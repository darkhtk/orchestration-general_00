#!/bin/bash
# =============================================================================
# Claude Orchestration Agent Launcher
# =============================================================================
# 4개 에이전트를 각각 새 터미널에서 실행합니다.
#
# 사용법:
#   bash launch.sh [프로젝트 디렉토리] [에이전트...]
#
# 예시:
#   bash launch.sh .                          # 4개 전부 실행
#   bash launch.sh . supervisor developer     # 특정 에이전트만
#   bash launch.sh . --stop                   # 실행 중인 에이전트 확인
# =============================================================================

set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
shift 2>/dev/null || true

PROMPT_DIR="$PROJECT_DIR/orchestration/prompts"

# 프레임워크 프롬프트 자동 동기화
if [ -d "$TEMPLATE_DIR/framework/prompts" ] && [ -d "$PROMPT_DIR" ]; then
    cp -f "$TEMPLATE_DIR/framework/prompts/"*.txt "$PROMPT_DIR/" 2>/dev/null && \
        echo "  📝 프롬프트 동기화 완료 (framework → project)"
fi

# 프롬프트 디렉토리 확인
if [ ! -d "$PROMPT_DIR" ]; then
    echo "❌ orchestration/prompts/ 디렉토리가 없습니다."
    echo "   먼저 auto-setup.sh 또는 init.sh를 실행하세요."
    exit 1
fi

# 실행할 에이전트 결정
AGENTS=()
if [ $# -eq 0 ]; then
    AGENTS=("SUPERVISOR" "DEVELOPER" "CLIENT" "COORDINATOR")
else
    for arg in "$@"; do
        case "${arg^^}" in
            SUPERVISOR|SUP|S) AGENTS+=("SUPERVISOR") ;;
            DEVELOPER|DEV|D)  AGENTS+=("DEVELOPER") ;;
            CLIENT|CLI|C)     AGENTS+=("CLIENT") ;;
            COORDINATOR|COORD|CO) AGENTS+=("COORDINATOR") ;;
            --STOP)
                echo "🔍 실행 중인 Claude 프로세스:"
                ps aux 2>/dev/null | grep -i "claude" | grep -v grep || tasklist 2>/dev/null | grep -i "claude" || echo "  없음"
                exit 0
                ;;
            *)
                echo "⚠️  알 수 없는 에이전트: $arg"
                echo "   사용 가능: supervisor(s), developer(d), client(c), coordinator(co)"
                exit 1
                ;;
        esac
    done
fi

echo "============================================"
echo " Claude Orchestration Agent Launcher"
echo "============================================"
echo ""
echo "  프로젝트: $PROJECT_DIR"
echo "  에이전트: ${AGENTS[*]}"
echo ""

# OS 감지
IS_WINDOWS=false
IS_MAC=false
IS_LINUX=false

if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
    IS_WINDOWS=true
elif [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MAC=true
else
    IS_LINUX=true
fi

# 에이전트 실행
launch_agent() {
    local agent_name="$1"
    local prompt_file="$PROMPT_DIR/$agent_name.txt"

    if [ ! -f "$prompt_file" ]; then
        echo "  ⚠️  $prompt_file 없음 — 스킵"
        return
    fi

    # runner 스크립트 사용 (프롬프트를 셸에 직접 전달하지 않음 — 인젝션 방지)
    local runner="$PROJECT_DIR/orchestration/.run_${agent_name}.sh"

    if [ ! -f "$runner" ]; then
        echo "    ⚠️  $runner 없음 — 스킵 (auto-setup.sh를 먼저 실행하세요)"
        return
    fi

    echo "  🚀 $agent_name 실행 중..."

    if $IS_WINDOWS; then
        if command -v wt.exe &>/dev/null; then
            wt.exe -w 0 new-tab --title "$agent_name" -d "$PROJECT_DIR" bash "orchestration/.run_${agent_name}.sh" &
        else
            start "$agent_name" bash -c "cd '$PROJECT_DIR' && bash 'orchestration/.run_${agent_name}.sh'" &
        fi
    elif $IS_MAC; then
        osascript -e "
            tell application \"Terminal\"
                activate
                do script \"cd '$PROJECT_DIR' && bash 'orchestration/.run_${agent_name}.sh'\"
            end tell
        " &
    else
        if command -v gnome-terminal &>/dev/null; then
            gnome-terminal --tab --title="$agent_name" -- bash -c "cd '$PROJECT_DIR' && bash 'orchestration/.run_${agent_name}.sh'; exec bash" &
        elif command -v tmux &>/dev/null; then
            tmux new-window -n "$agent_name" "cd '$PROJECT_DIR' && bash 'orchestration/.run_${agent_name}.sh'"
        else
            echo "    ⚠️  터미널 자동 실행 불가 — 수동으로 실행하세요:"
            echo "    cd '$PROJECT_DIR' && bash orchestration/.run_${agent_name}.sh"
        fi
    fi

    # 에이전트 간 시작 간격 (동시 git 충돌 방지)
    sleep 3
}

for agent in "${AGENTS[@]}"; do
    launch_agent "$agent"
done

# 충돌 복구 시스템 시작 (에이전트가 2개 이상일 때)
if [ "${#AGENTS[@]}" -gt 1 ]; then
    echo "  🛡️  에이전트 충돌 복구 시스템 시작..."
    if [ -f "$TEMPLATE_DIR/conflict-recovery.sh" ]; then
        nohup bash "$TEMPLATE_DIR/conflict-recovery.sh" "$PROJECT_DIR" --monitor > "$PROJECT_DIR/orchestration/logs/RECOVERY.log" 2>&1 &
        echo "    ✅ 백그라운드에서 실행 중 (PID: $!)"
        echo "$!" > "$PROJECT_DIR/orchestration/.locks/recovery.pid"
    else
        echo "    ⚠️  conflict-recovery.sh를 찾을 수 없습니다"
    fi
fi

echo ""
echo "============================================"
echo " ✅ ${#AGENTS[@]}개 에이전트 실행됨"
echo "============================================"
echo ""
echo "  모니터링:"
echo "    cat orchestration/logs/SUPERVISOR.md"
echo "    cat orchestration/logs/DEVELOPER.md"
echo "    cat orchestration/logs/CLIENT.md"
echo "    cat orchestration/logs/COORDINATOR.md"
if [ "${#AGENTS[@]}" -gt 1 ]; then
    echo "    cat orchestration/logs/RECOVERY.md      # 충돌 복구 로그"
fi
echo ""
echo "  중단: 각 터미널에서 Ctrl+C"
echo "  전체 FREEZE: BOARD.md 상단에 '🛑 FREEZE' 추가"
if [ "${#AGENTS[@]}" -gt 1 ]; then
    echo "  충돌 체크: bash conflict-recovery.sh . --check"
fi
echo ""
