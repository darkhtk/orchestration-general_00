#!/bin/bash
# BOARD.md 동시 수정 충돌 방지를 위한 파일 잠금 메커니즘
# SPEC-R-001 구현

set -euo pipefail

# 설정값
# 스크립트의 위치를 기준으로 LOCK_FILE 경로 설정
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOCK_FILE="$PROJECT_ROOT/orchestration/.board.lock"
readonly LOCK_TIMEOUT=30  # 잠금 타임아웃 (초)
readonly RETRY_INTERVAL=2  # 재시도 간격 (초)
readonly MAX_RETRIES=10    # 최대 재시도 횟수

# 로그 함수
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] [BOARD_LOCK] $*" >&2
}

log_critical() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [CRITICAL] [BOARD_LOCK] $*" >&2
}

log_wait() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] [BOARD_LOCK_WAIT] $*" >&2
}

# 잠금 파일이 stale인지 확인 (30초 초과)
is_stale_lock() {
    local lock_file="$1"

    if [[ ! -f "$lock_file" ]]; then
        return 1  # 파일이 없으면 stale이 아님
    fi

    # 잠금 파일에서 타임스탬프 추출
    local timestamp
    timestamp=$(grep "^TIMESTAMP=" "$lock_file" 2>/dev/null | cut -d= -f2 || echo "")

    if [[ -z "$timestamp" ]]; then
        return 0  # 타임스탬프가 없으면 stale로 간주
    fi

    # 현재 시간과 비교 (Linux date 명령어 사용)
    local current_epoch
    local lock_epoch

    current_epoch=$(date +%s)
    lock_epoch=$(date -d "$timestamp" +%s 2>/dev/null || echo "0")

    local elapsed=$((current_epoch - lock_epoch))

    if [[ $elapsed -gt $LOCK_TIMEOUT ]]; then
        return 0  # stale lock
    else
        return 1  # 유효한 lock
    fi
}

# 잠금 획득
acquire_lock() {
    local agent_name="$1"
    local retries=0
    local backoff_interval=$RETRY_INTERVAL
    local consecutive_failures=0

    if [[ -z "$agent_name" ]]; then
        log_critical "에이전트명이 필요합니다"
        return 1
    fi

    while [[ $retries -lt $MAX_RETRIES ]]; do
        # 성능 최적화: 먼저 빠른 stale 체크
        if [[ -f "$LOCK_FILE/info" ]]; then
            if is_stale_lock "$LOCK_FILE/info"; then
                log_info "stale 잠금 감지, 정리 중..."
                rm -rf "$LOCK_FILE" 2>/dev/null || true
                consecutive_failures=0  # stale lock 정리 후 실패 카운터 초기화
            else
                # 유효한 잠금이 존재하는 경우, 잠금 소유자 정보 확인
                local lock_agent
                lock_agent=$(grep "^AGENT=" "$LOCK_FILE/info" 2>/dev/null | cut -d= -f2 || echo "unknown")

                # 동일한 에이전트가 이미 잠금을 가지고 있는 경우
                if [[ "$lock_agent" == "$agent_name" ]]; then
                    local lock_pid
                    lock_pid=$(grep "^PID=" "$LOCK_FILE/info" 2>/dev/null | cut -d= -f2 || echo "0")
                    log_info "동일 에이전트 잠금 감지: $agent_name (PID: $lock_pid vs 현재: $$)"

                    # 동일 PID인 경우 이미 획득한 것으로 간주
                    if [[ "$lock_pid" == "$$" ]]; then
                        log_info "잠금 이미 획득됨: $agent_name (PID: $$)"
                        return 0
                    fi
                fi
            fi
        fi

        # mkdir을 이용한 atomic lock 시도
        if mkdir "${LOCK_FILE}.tmp" 2>/dev/null; then
            # 잠금 파일 내용 생성
            cat > "${LOCK_FILE}.tmp/info" << EOF
AGENT=$agent_name
PID=$$
TIMESTAMP=$(date -Iseconds)
EOF

            # atomic rename
            if mv "${LOCK_FILE}.tmp" "$LOCK_FILE" 2>/dev/null; then
                log_info "잠금 획득 성공: $agent_name (PID: $$)"
                return 0
            else
                # rename 실패 시 cleanup
                rmdir "${LOCK_FILE}.tmp" 2>/dev/null || true
                consecutive_failures=$((consecutive_failures + 1))
            fi
        else
            consecutive_failures=$((consecutive_failures + 1))
        fi

        # 성능 최적화: 연속 실패 시 지수적 백오프 적용
        retries=$((retries + 1))

        if [[ $consecutive_failures -ge 3 ]]; then
            backoff_interval=$((backoff_interval * 2))
            if [[ $backoff_interval -gt 10 ]]; then
                backoff_interval=10  # 최대 10초
            fi
            log_wait "연속 실패로 백오프 적용: ${backoff_interval}초 대기 - $agent_name"
        else
            log_wait "잠금 대기 중... ($retries/$MAX_RETRIES) - $agent_name"
        fi

        if [[ $retries -lt $MAX_RETRIES ]]; then
            sleep $backoff_interval
        fi
    done

    log_critical "BOARD_LOCK_TIMEOUT: 최대 재시도 횟수 초과 - $agent_name"
    return 1
}

# 잠금 해제
release_lock() {
    local agent_name="$1"

    if [[ -z "$agent_name" ]]; then
        log_critical "에이전트명이 필요합니다"
        return 1
    fi

    if [[ ! -d "$LOCK_FILE" ]]; then
        log_info "잠금 파일이 없습니다 - $agent_name"
        return 0
    fi

    # 자신의 잠금인지 확인
    local lock_agent
    local lock_pid

    if [[ -f "$LOCK_FILE/info" ]]; then
        lock_agent=$(grep "^AGENT=" "$LOCK_FILE/info" 2>/dev/null | cut -d= -f2 || echo "")
        lock_pid=$(grep "^PID=" "$LOCK_FILE/info" 2>/dev/null | cut -d= -f2 || echo "")

        if [[ "$lock_agent" != "$agent_name" ]]; then
            log_critical "다른 에이전트의 잠금입니다: $lock_agent (요청자: $agent_name)"
            return 1
        fi

        if [[ "$lock_pid" != "$$" ]]; then
            log_critical "다른 프로세스의 잠금입니다: $lock_pid (현재: $$)"
            return 1
        fi
    fi

    # 잠금 해제
    if rm -rf "$LOCK_FILE" 2>/dev/null; then
        log_info "잠금 해제 성공: $agent_name (PID: $$)"
        return 0
    else
        log_critical "잠금 해제 실패: $agent_name (PID: $$)"
        return 1
    fi
}

# 잠금 상태 확인
check_lock() {
    if [[ -d "$LOCK_FILE" ]] && [[ -f "$LOCK_FILE/info" ]]; then
        echo "잠금 상태: LOCKED"
        cat "$LOCK_FILE/info"

        if is_stale_lock "$LOCK_FILE/info"; then
            echo "상태: STALE (30초 초과)"
        else
            echo "상태: ACTIVE"
        fi
    else
        echo "잠금 상태: UNLOCKED"
    fi
}

# cleanup 함수 - trap에서 사용
cleanup_lock() {
    local agent_name="$1"
    if [[ -d "$LOCK_FILE" ]]; then
        log_info "프로세스 종료 시 잠금 정리: $agent_name"
        release_lock "$agent_name" 2>/dev/null || true
    fi
}

# 사용법 출력
usage() {
    cat << EOF
사용법: source board-lock.sh

함수:
  acquire_lock AGENT_NAME    - 잠금 획득
  release_lock AGENT_NAME    - 잠금 해제
  check_lock                 - 잠금 상태 확인

예제:
  source orchestration/scripts/board-lock.sh
  acquire_lock COORDINATOR
  # BOARD.md 수정 작업
  release_lock COORDINATOR

또는 자동 cleanup을 위해:
  trap 'cleanup_lock COORDINATOR' EXIT
  acquire_lock COORDINATOR
  # 작업...
  # EXIT 시 자동으로 잠금 해제됨
EOF
}

# 스크립트가 직접 실행될 때 사용법 출력
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    usage
fi