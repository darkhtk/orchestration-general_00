#!/bin/bash
# =============================================================================
# Runtime Monitor — 런타임 에러/크래시 실시간 감시
# =============================================================================
# 게임 실행 중 Editor.log (또는 Player.log)를 실시간으로 감시하고
# 에러 발견 시 orchestration에 자동 보고합니다.
#
# 사용법:
#   bash monitor.sh /path/to/project              # 기본 (Editor.log)
#   bash monitor.sh /path/to/project --player      # Player.log (빌드 버전)
#   bash monitor.sh /path/to/project --analyze     # 현재 로그 1회 분석
# =============================================================================

set -e

PROJECT_DIR="${1:-.}"
MODE="${2:---editor}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "[ERROR] Project not found: $PROJECT_DIR"
    exit 1
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

ORCH_DIR="$PROJECT_DIR/orchestration"
CONFIG="$ORCH_DIR/project.config.md"
BOARD="$ORCH_DIR/BOARD.md"
BACKLOG="$ORCH_DIR/BACKLOG_RESERVE.md"
REPORT="$ORCH_DIR/logs/MONITOR.md"

# --- 로그 파일 경로 결정 ---
LOG_FILE=""

# LOCALAPPDATA fallback (macOS/Linux)
if [ -z "$LOCALAPPDATA" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        LOCALAPPDATA="$HOME/Library/Application Support"
    else
        LOCALAPPDATA="$HOME/.local/share"
    fi
fi
if [ -z "$APPDATA" ]; then
    APPDATA="$HOME/.config"
fi

if [ -f "$CONFIG" ]; then
    # config에서 에러 로그 경로 읽기
    LOG_PATH_RAW=$(grep '에러 로그 경로' "$CONFIG" 2>/dev/null | sed 's/.*\*\* *//' | sed 's/ *$//')
    # 환경변수 치환
    LOG_FILE=$(echo "$LOG_PATH_RAW" | sed "s|%LOCALAPPDATA%|$LOCALAPPDATA|g" | sed "s|%APPDATA%|$APPDATA|g" | sed 's|\\|/|g')
fi

# fallback: Unity 기본 경로
if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
    if [ "$MODE" = "--player" ]; then
        LOG_FILE="$LOCALAPPDATA/Unity/Editor/Player.log"
    else
        LOG_FILE="$LOCALAPPDATA/Unity/Editor/Editor.log"
    fi
fi

# macOS Unity fallback
if [ ! -f "$LOG_FILE" ] && [[ "$OSTYPE" == "darwin"* ]]; then
    LOG_FILE="$HOME/Library/Logs/Unity/Editor.log"
fi

# Godot fallback
if [ ! -f "$LOG_FILE" ]; then
    GODOT_LOG="$APPDATA/Godot/logs/godot.log"
    [ -f "$GODOT_LOG" ] && LOG_FILE="$GODOT_LOG"
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "[ERROR] Log file not found: $LOG_FILE"
    echo "  Make sure the game engine is running."
    exit 1
fi

echo ""
echo "============================================"
echo " Runtime Monitor"
echo "============================================"
echo ""
echo "  Project: $PROJECT_DIR"
echo "  Log:     $LOG_FILE"
echo "  Mode:    $MODE"
echo ""

# --- 에러 패턴 정의 ---
# Unity
PATTERNS_CRITICAL="NullReferenceException|StackOverflowException|OutOfMemoryException|ExecutionEngineException|AccessViolation|CRASH|Segmentation fault"
PATTERNS_ERROR="Exception:|Error:|error CS|UnassignedReferenceException|MissingReferenceException|MissingComponentException|IndexOutOfRangeException|ArgumentException|InvalidOperationException|FormatException|KeyNotFoundException"
PATTERNS_WARNING="warning CS|Warning:|Performance warning|GC Allocation|Shader error"
PATTERNS_UI="Canvas|UI|Button|Panel|EventSystem|RectTransform|LayoutGroup|ScrollRect|Raycast"

# --- 1회 분석 모드 ---
if [ "$MODE" = "--analyze" ]; then
    echo "🔍 Analyzing current log..."
    echo ""

    LOG_SIZE=$(wc -c < "$LOG_FILE")
    echo "  Log size: $((LOG_SIZE / 1024)) KB"

    # 크리티컬
    CRITICAL_COUNT=$(grep -cE "$PATTERNS_CRITICAL" "$LOG_FILE" 2>/dev/null || true)
    echo ""
    echo "  === CRITICAL ($CRITICAL_COUNT) ==="
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        grep -nE "$PATTERNS_CRITICAL" "$LOG_FILE" | tail -20
    fi

    # 에러
    ERROR_COUNT=$(grep -cE "$PATTERNS_ERROR" "$LOG_FILE" 2>/dev/null || true)
    echo ""
    echo "  === ERRORS ($ERROR_COUNT) ==="
    if [ "$ERROR_COUNT" -gt 0 ]; then
        grep -nE "$PATTERNS_ERROR" "$LOG_FILE" | sort -u | tail -30
    fi

    # 경고
    WARNING_COUNT=$(grep -cE "$PATTERNS_WARNING" "$LOG_FILE" 2>/dev/null || true)
    echo ""
    echo "  === WARNINGS ($WARNING_COUNT) ==="

    # UI 관련 에러
    UI_ERROR_COUNT=$(grep -E "$PATTERNS_ERROR" "$LOG_FILE" 2>/dev/null | grep -ciE "$PATTERNS_UI" || true)
    echo ""
    echo "  === UI ERRORS ($UI_ERROR_COUNT) ==="
    if [ "$UI_ERROR_COUNT" -gt 0 ]; then
        grep -E "$PATTERNS_ERROR" "$LOG_FILE" | grep -iE "$PATTERNS_UI" | tail -15
    fi

    # 리포트 생성
    cat > "$REPORT" << REPORTEOF
# Runtime Monitor Report
## $(date '+%Y-%m-%d %H:%M')

### Summary
| Type | Count |
|------|-------|
| Critical | $CRITICAL_COUNT |
| Errors | $ERROR_COUNT |
| Warnings | $WARNING_COUNT |
| UI Errors | $UI_ERROR_COUNT |

REPORTEOF

    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo "### Critical Issues" >> "$REPORT"
        echo '```' >> "$REPORT"
        grep -E "$PATTERNS_CRITICAL" "$LOG_FILE" | tail -10 >> "$REPORT"
        echo '```' >> "$REPORT"
        echo "" >> "$REPORT"
    fi

    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "### Errors (unique)" >> "$REPORT"
        echo '```' >> "$REPORT"
        grep -E "$PATTERNS_ERROR" "$LOG_FILE" | sort -u | tail -20 >> "$REPORT"
        echo '```' >> "$REPORT"
        echo "" >> "$REPORT"
    fi

    if [ "$UI_ERROR_COUNT" -gt 0 ]; then
        echo "### UI Errors" >> "$REPORT"
        echo '```' >> "$REPORT"
        grep -E "$PATTERNS_ERROR" "$LOG_FILE" | grep -iE "$PATTERNS_UI" | tail -10 >> "$REPORT"
        echo '```' >> "$REPORT"
    fi

    echo ""
    echo "  Report: $REPORT"

    # 크리티컬이 있으면 BACKLOG에 버그 태스크 자동 추가
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo ""
        echo "  ⚠️  CRITICAL errors found!"
        echo "  Generating bug fix tasks..."

        CRITICAL_ERRORS=$(grep -E "$PATTERNS_CRITICAL" "$LOG_FILE" | sort -u | head -5)

        PROMPT="You are a bug fixer. These critical runtime errors were found:

\`\`\`
$CRITICAL_ERRORS
\`\`\`

Generate BACKLOG entries to fix each error. Format:

### BUG-FIX-NNN: [short description]
[root cause analysis + fix direction]. Priority P0.

Output ONLY the ### entries, nothing else. Write in Korean."

        BUG_TASKS=$(claude --print "$PROMPT" 2>/dev/null)

        if [ -n "$BUG_TASKS" ]; then
            echo "" >> "$BACKLOG"
            echo "### --- [$(date '+%Y-%m-%d')] Runtime Monitor: Critical Bugs ---" >> "$BACKLOG"
            echo "" >> "$BACKLOG"
            echo "$BUG_TASKS" >> "$BACKLOG"
            BUG_COUNT=$(echo "$BUG_TASKS" | grep -c '^### ' || true)
            echo "  ✅ ${BUG_COUNT}건 버그 수정 태스크 추가"
        fi
    fi

    echo ""
    echo "============================================"
    echo " Analysis Complete"
    echo "============================================"
    echo ""
    exit 0
fi

# --- 실시간 감시 모드 ---
echo "👁️  Watching for runtime errors... (Ctrl+C to stop)"
echo ""

LAST_SIZE=$(wc -c < "$LOG_FILE")
ERROR_BUFFER=""
CHECK_INTERVAL=5

while true; do
    CURRENT_SIZE=$(wc -c < "$LOG_FILE")

    if [ "$CURRENT_SIZE" -gt "$LAST_SIZE" ]; then
        # 새로 추가된 부분만 읽기
        NEW_CONTENT=$(tail -c +$((LAST_SIZE + 1)) "$LOG_FILE")
        LAST_SIZE=$CURRENT_SIZE

        # 크리티컬 체크
        CRITICAL=$(echo "$NEW_CONTENT" | grep -E "$PATTERNS_CRITICAL" || true)
        if [ -n "$CRITICAL" ]; then
            echo ""
            echo "  🚨 CRITICAL: $CRITICAL"
            echo "  $(date '+%H:%M:%S') — Writing to MONITOR.md"

            # 리포트에 기록
            echo "## 🚨 CRITICAL [$(date '+%H:%M:%S')]" >> "$REPORT"
            echo '```' >> "$REPORT"
            echo "$CRITICAL" >> "$REPORT"
            echo '```' >> "$REPORT"
            echo "" >> "$REPORT"
        fi

        # 에러 체크
        ERRORS=$(echo "$NEW_CONTENT" | grep -E "$PATTERNS_ERROR" || true)
        if [ -n "$ERRORS" ]; then
            ERROR_COUNT=$(echo "$ERRORS" | wc -l)
            echo "  ⚠️  $(date '+%H:%M:%S') — $ERROR_COUNT error(s) detected"

            # 10건 이상 누적되면 리포트
            ERROR_BUFFER="${ERROR_BUFFER}${ERRORS}"
            BUFFER_COUNT=$(echo "$ERROR_BUFFER" | grep -c '.' 2>/dev/null || true)
            if [ "$BUFFER_COUNT" -ge 10 ]; then
                echo "  📝 $(date '+%H:%M:%S') — ${BUFFER_COUNT} errors buffered, writing report"
                echo "## Errors [$(date '+%H:%M:%S')] — ${BUFFER_COUNT} total" >> "$REPORT"
                echo '```' >> "$REPORT"
                echo "$ERROR_BUFFER" | sort -u | tail -20 >> "$REPORT"
                echo '```' >> "$REPORT"
                echo "" >> "$REPORT"
                ERROR_BUFFER=""
            fi
        fi

        # UI 에러 체크
        UI_ERRORS=$(echo "$NEW_CONTENT" | grep -E "$PATTERNS_ERROR" | grep -iE "$PATTERNS_UI" || true)
        if [ -n "$UI_ERRORS" ]; then
            echo "  🖼️  $(date '+%H:%M:%S') — UI error: $(echo "$UI_ERRORS" | head -1)"
        fi
    elif [ "$CURRENT_SIZE" -lt "$LAST_SIZE" ]; then
        # 로그 파일이 리셋됨 (에디터 재시작)
        echo "  🔄 $(date '+%H:%M:%S') — Log file reset (editor restarted?)"
        LAST_SIZE=0
        ERROR_BUFFER=""
    fi

    sleep $CHECK_INTERVAL
done
