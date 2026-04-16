#!/bin/bash
# =============================================================================
# Conflict Recovery System — 에이전트 충돌 자동 복구 시스템
# =============================================================================
# 여러 에이전트가 동시에 실행될 때 발생할 수 있는 충돌을 감지하고 자동으로 복구합니다.
#
# 주요 기능:
# 1. 파일 잠금 충돌 감지 및 복구
# 2. 프로세스 데드락 해결
# 3. 중복 작업 방지
# 4. 에이전트 상태 동기화
#
# 사용법:
#   bash conflict-recovery.sh /path/to/project              # 1회 체크
#   bash conflict-recovery.sh /path/to/project --monitor    # 지속적 감시
#   bash conflict-recovery.sh /path/to/project --repair     # 강제 복구
# =============================================================================

set -e

PROJECT_DIR="${1:-.}"
MODE="${2:---check}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "[오류] 프로젝트를 찾을 수 없습니다: $PROJECT_DIR"
    exit 1
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

ORCH_DIR="$PROJECT_DIR/orchestration"
LOGS_DIR="$ORCH_DIR/logs"
LOCK_DIR="$ORCH_DIR/.locks"
RECOVERY_LOG="$LOGS_DIR/RECOVERY.md"

# 디렉토리 생성
mkdir -p "$LOCK_DIR" "$LOGS_DIR"

echo ""
echo "============================================"
echo " 에이전트 충돌 복구 시스템"
echo "============================================"
echo ""
echo "  프로젝트: $PROJECT_DIR"
echo "  모드: $MODE"
echo "  시간: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# --- 유틸리티 함수 ---

# 로그 기록
log_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$RECOVERY_LOG"
    echo "  $level: $message"
}

# 활성 에이전트 프로세스 감지
detect_active_agents() {
    local agents=()

    # bash 프로세스 중 오케스트레이션 관련 스크립트 실행 중인 것들 찾기
    local orchestration_scripts=("launch.sh" "monitor.sh" "add-feature.sh" "auto-setup.sh")

    for script in "${orchestration_scripts[@]}"; do
        local pids=$(pgrep -f "$script" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            agents+=("$script:$pids")
        fi
    done

    printf '%s\n' "${agents[@]}"
}

# 파일 잠금 충돌 감지
detect_file_conflicts() {
    local conflicts=()

    # 중요 파일들의 잠금 상태 확인
    local critical_files=("$ORCH_DIR/BOARD.md" "$ORCH_DIR/BACKLOG_RESERVE.md")

    for file in "${critical_files[@]}"; do
        local lock_file="$LOCK_DIR/$(basename "$file").lock"

        if [ -f "$lock_file" ]; then
            local lock_age=$(($(date +%s) - $(stat -c%Y "$lock_file" 2>/dev/null || date +%s)))

            # 5분 이상 된 잠금은 스테일 잠금으로 간주
            if [ "$lock_age" -gt 300 ]; then
                local lock_pid=$(cat "$lock_file" 2>/dev/null || echo "unknown")
                conflicts+=("stale_lock:$file:$lock_pid:${lock_age}초")
            fi
        fi

        # 파일이 여러 프로세스에 의해 수정 중인지 확인 (Linux의 경우)
        if command -v lsof >/dev/null 2>&1; then
            local writers=$(lsof "$file" 2>/dev/null | grep -c ' w ' || true)
            if [ "$writers" -gt 1 ]; then
                conflicts+=("multiple_writers:$file:$writers")
            fi
        fi
    done

    printf '%s\n' "${conflicts[@]}"
}

# 중복 작업 감지
detect_duplicate_tasks() {
    local duplicates=()

    # 진행 중인 작업들을 로그에서 분석
    local agent_logs=("$LOGS_DIR/DEVELOPER.md" "$LOGS_DIR/SUPERVISOR.md" "$LOGS_DIR/CLIENT.md" "$LOGS_DIR/COORDINATOR.md")
    local active_tasks=()

    for log_file in "${agent_logs[@]}"; do
        if [ -f "$log_file" ]; then
            # 최근 10분 내의 작업 기록 확인
            local recent_tasks=$(grep -E "작업 시작|Task started" "$log_file" 2>/dev/null | tail -5 || true)
            if [ -n "$recent_tasks" ]; then
                active_tasks+=("$(basename "$log_file" .md):$recent_tasks")
            fi
        fi
    done

    # 작업 중복 검사 (간단한 휴리스틱)
    local task_keywords=()
    for task_entry in "${active_tasks[@]}"; do
        local tasks=$(echo "$task_entry" | cut -d':' -f2-)
        # 공통 키워드 추출 (예: feature, bug, test 등)
        local keywords=$(echo "$tasks" | grep -oiE '\b(feature|bug|test|refactor|update|fix)\b' | sort -u || true)
        for keyword in $keywords; do
            task_keywords+=("$keyword")
        done
    done

    # 중복 키워드가 3개 이상이면 중복 작업으로 의심
    local duplicate_count=$(printf '%s\n' "${task_keywords[@]}" | sort | uniq -d | wc -l)
    if [ "$duplicate_count" -gt 0 ]; then
        duplicates+=("duplicate_keywords:$duplicate_count")
    fi

    printf '%s\n' "${duplicates[@]}"
}

# 프로세스 데드락 감지
detect_deadlocks() {
    local deadlocks=()
    local active_agents=($(detect_active_agents))

    if [ "${#active_agents[@]}" -gt 2 ]; then
        # 3개 이상의 에이전트가 동시 실행 중일 때 리소스 대기 상황 체크
        for agent in "${active_agents[@]}"; do
            local script_name=$(echo "$agent" | cut -d':' -f1)
            local pid=$(echo "$agent" | cut -d':' -f2)

            # 프로세스가 I/O 대기 중인지 확인
            if [ -f "/proc/$pid/stat" ]; then
                local state=$(awk '{print $3}' "/proc/$pid/stat" 2>/dev/null || echo "?")
                if [ "$state" = "D" ]; then  # Uninterruptible sleep (보통 I/O 대기)
                    deadlocks+=("io_wait:$script_name:$pid")
                fi
            fi
        done
    fi

    printf '%s\n' "${deadlocks[@]}"
}

# 자동 복구 실행
auto_recover() {
    local conflict_type="$1"
    local details="$2"

    log_event "복구" "자동 복구 시작: $conflict_type"

    case "$conflict_type" in
        "stale_lock")
            local file_path=$(echo "$details" | cut -d':' -f2)
            local lock_file="$LOCK_DIR/$(basename "$file_path").lock"
            log_event "정보" "스테일 잠금 제거: $lock_file"
            rm -f "$lock_file"
            ;;

        "multiple_writers")
            local file_path=$(echo "$details" | cut -d':' -f2)
            log_event "경고" "다중 쓰기 감지: $file_path (수동 개입 필요)"
            ;;

        "duplicate_keywords")
            log_event "경고" "중복 작업 의심됨 (에이전트 간 조율 필요)"
            ;;

        "io_wait")
            local script_name=$(echo "$details" | cut -d':' -f2)
            local pid=$(echo "$details" | cut -d':' -f3)
            log_event "경고" "I/O 대기 감지: $script_name (PID: $pid)"

            # 30초 이상 대기 중이면 강제 종료 옵션 제공
            if [ "$MODE" = "--repair" ]; then
                log_event "복구" "강제 종료: PID $pid"
                kill -TERM "$pid" 2>/dev/null || true
                sleep 2
                kill -KILL "$pid" 2>/dev/null || true
            fi
            ;;
    esac
}

# --- 메인 로직 ---

# 복구 로그 초기화
if [ ! -f "$RECOVERY_LOG" ] || [ "$MODE" = "--repair" ]; then
    cat > "$RECOVERY_LOG" << LOGEOF
# 에이전트 충돌 복구 로그

> 초기화: $(date '+%Y-%m-%d %H:%M:%S')

## 복구 이벤트
LOGEOF
fi

# 1회 체크 모드
if [ "$MODE" = "--check" ] || [ "$MODE" = "--repair" ]; then
    echo "🔍 충돌 검사 중..."

    # 활성 에이전트 확인
    active_agents=($(detect_active_agents))
    echo "  활성 에이전트: ${#active_agents[@]}개"
    for agent in "${active_agents[@]}"; do
        echo "    - $agent"
    done

    # 파일 충돌 검사
    echo ""
    echo "📁 파일 잠금 충돌 검사..."
    file_conflicts=($(detect_file_conflicts))
    for conflict in "${file_conflicts[@]}"; do
        echo "  ⚠️  충돌 감지: $conflict"
        auto_recover "$(echo "$conflict" | cut -d':' -f1)" "$conflict"
    done
    if [ "${#file_conflicts[@]}" -eq 0 ]; then
        echo "  ✅ 파일 잠금 충돌 없음"
    fi

    # 중복 작업 검사
    echo ""
    echo "🔄 중복 작업 검사..."
    duplicate_tasks=($(detect_duplicate_tasks))
    for duplicate in "${duplicate_tasks[@]}"; do
        echo "  ⚠️  중복 감지: $duplicate"
        auto_recover "$(echo "$duplicate" | cut -d':' -f1)" "$duplicate"
    done
    if [ "${#duplicate_tasks[@]}" -eq 0 ]; then
        echo "  ✅ 중복 작업 없음"
    fi

    # 데드락 검사
    echo ""
    echo "🔒 데드락 검사..."
    deadlocks=($(detect_deadlocks))
    for deadlock in "${deadlocks[@]}"; do
        echo "  ⚠️  데드락 감지: $deadlock"
        auto_recover "$(echo "$deadlock" | cut -d':' -f1)" "$deadlock"
    done
    if [ "${#deadlocks[@]}" -eq 0 ]; then
        echo "  ✅ 데드락 없음"
    fi

    echo ""
    echo "============================================"
    echo " 검사 완료"
    echo "============================================"
    echo ""

    # 요약 리포트
    total_issues=$((${#file_conflicts[@]} + ${#duplicate_tasks[@]} + ${#deadlocks[@]}))
    if [ "$total_issues" -gt 0 ]; then
        log_event "요약" "$total_issues개 이슈 감지됨"
        echo "  📊 총 이슈: $total_issues개"
        echo "  📝 상세 로그: $RECOVERY_LOG"
    else
        log_event "요약" "이상 없음"
        echo "  ✅ 모든 시스템 정상"
    fi

    exit 0
fi

# 지속적 감시 모드
if [ "$MODE" = "--monitor" ]; then
    echo "👁️  에이전트 충돌 지속 감시 중... (Ctrl+C로 중지)"
    echo ""

    CHECK_INTERVAL=10  # 10초마다 체크
    LAST_REPORT_TIME=0

    while true; do
        current_time=$(date +%s)

        # 충돌 체크
        file_conflicts=($(detect_file_conflicts))
        duplicate_tasks=($(detect_duplicate_tasks))
        deadlocks=($(detect_deadlocks))

        total_issues=$((${#file_conflicts[@]} + ${#duplicate_tasks[@]} + ${#deadlocks[@]}))

        if [ "$total_issues" -gt 0 ]; then
            echo "  ⚠️  $(date '+%H:%M:%S') — $total_issues개 충돌 감지"

            # 자동 복구 실행
            for conflict in "${file_conflicts[@]}"; do
                auto_recover "$(echo "$conflict" | cut -d':' -f1)" "$conflict"
            done
            for duplicate in "${duplicate_tasks[@]}"; do
                auto_recover "$(echo "$duplicate" | cut -d':' -f1)" "$duplicate"
            done
            for deadlock in "${deadlocks[@]}"; do
                auto_recover "$(echo "$deadlock" | cut -d':' -f1)" "$deadlock"
            done
        fi

        # 5분마다 상태 리포트
        if [ $((current_time - LAST_REPORT_TIME)) -gt 300 ]; then
            active_agents=($(detect_active_agents))
            echo "  📊 $(date '+%H:%M:%S') — 활성 에이전트: ${#active_agents[@]}개, 이슈: $total_issues개"
            LAST_REPORT_TIME=$current_time
        fi

        sleep $CHECK_INTERVAL
    done
fi

echo "[오류] 알 수 없는 모드: $MODE"
echo "사용법: $0 /path/to/project [--check|--monitor|--repair]"
exit 1