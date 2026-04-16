#!/bin/bash
# =============================================================================
# Add Feature — 자연어 요청을 태스크+기획서로 변환
# =============================================================================
# 사용법:
#   bash add-feature.sh /path/to/project "멀티플레이어 PvP 시스템 추가"
#   bash add-feature.sh .               "인벤토리에 정렬 기능"
# =============================================================================

set -e

PROJECT_DIR="${1:-.}"
REQUEST="${2:-}"

if [ -z "$REQUEST" ]; then
    echo ""
    echo "  Usage: bash add-feature.sh /path/to/project \"feature description\""
    echo ""
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo "[ERROR] Project not found: $PROJECT_DIR"
    exit 1
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

ORCH_DIR="$PROJECT_DIR/orchestration"
if [ ! -d "$ORCH_DIR" ]; then
    echo "[ERROR] orchestration/ not found. Run auto-setup.sh first."
    exit 1
fi

BACKLOG="$ORCH_DIR/BACKLOG_RESERVE.md"
SPEC_DIR="$ORCH_DIR/specs"
CONFIG="$ORCH_DIR/project.config.md"

echo ""
echo "============================================"
echo " Add Feature"
echo "============================================"
echo ""
echo "  Request: $REQUEST"
echo ""

# --- 기존 상태 파악 ---

# 현재 BACKLOG에서 마지막 R/A 번호 찾기
LAST_R=$(grep -oE 'R-[0-9]+' "$BACKLOG" 2>/dev/null | sed 's/R-//' | sort -n | tail -1)
LAST_A=$(grep -oE 'A-[0-9]+' "$BACKLOG" 2>/dev/null | sed 's/A-//' | sort -n | tail -1)
# specs에서도 확인
LAST_R_SPEC=$(ls "$SPEC_DIR"/SPEC-R-*.md 2>/dev/null | grep -oE 'R-[0-9]+' | sed 's/R-//' | sort -n | tail -1)

# 가장 큰 번호 + 1
NEXT_R=$(( ${LAST_R:-0} > ${LAST_R_SPEC:-0} ? ${LAST_R:-0} : ${LAST_R_SPEC:-0} ))
NEXT_R=$((NEXT_R + 1))
NEXT_A=$((${LAST_A:-0} + 1))

# config 정보
ENGINE=""
LANGUAGE=""
if [ -f "$CONFIG" ]; then
    ENGINE=$(grep '엔진' "$CONFIG" 2>/dev/null | head -1 | sed 's/.*\*\* *//' | sed 's/ *$//')
    LANGUAGE=$(grep '언어' "$CONFIG" 2>/dev/null | head -1 | sed 's/.*\*\* *//' | sed 's/ *$//')
fi

# 기존 시스템 파악 (BACKLOG + specs에서)
EXISTING_SYSTEMS=$(grep '^### ' "$BACKLOG" 2>/dev/null | head -30)
EXISTING_SPECS=$(ls "$SPEC_DIR"/*.md 2>/dev/null | xargs -I{} head -3 {} 2>/dev/null | grep '^# ' | head -20)

# 소스 구조 (주요 파일명)
SRC_FILES=$(find "$PROJECT_DIR" -maxdepth 6 \
    \( -name "*.cs" -o -name "*.gd" -o -name "*.cpp" -o -name "*.ts" \) \
    ! -path "*/.git/*" ! -path "*/Library/*" ! -path "*/node_modules/*" \
    2>/dev/null | xargs -I{} basename {} 2>/dev/null | sort -u | head -50)

echo "🤖 Generating tasks..."
echo ""

# --- Claude 프롬프트 ---
PROMPT="You are a game development task planner.

## Context
- Engine: ${ENGINE:-unknown}
- Language: ${LANGUAGE:-unknown}
- Next task number: R-$(printf '%03d' $NEXT_R)
- Next asset number: A-$(printf '%03d' $NEXT_A)

## Existing systems in project:
$SRC_FILES

## Existing backlog tasks:
$EXISTING_SYSTEMS

## User Request:
$REQUEST

---

## Instructions

Break down the user's request into concrete development tasks. Generate TWO outputs:

### Output 1: BACKLOG entries

Format each task as:
\`\`\`
### R-NNN: [task title]
[1-2 line description]. specs/SPEC-R-NNN.md 참조.
\`\`\`

For asset tasks (sprites, audio, UI art):
\`\`\`
### 🎨 A-NNN: [asset task title]
[1-2 line description]
\`\`\`

Wrap ALL backlog entries between ===BACKLOG=== and ===END_BACKLOG===

### Output 2: SPEC files

For each R-NNN task, generate a spec:
\`\`\`
===SPEC:R-NNN===
# SPEC-R-NNN: [feature name]

**관련 태스크:** R-NNN

---

## 개요
(1-line)

## 상세 설명
(what, why, expected behavior)

## 데이터 구조
(class/struct sketch if needed, or N/A)

## 연동 경로
| From | To | 방식 |
|------|----|------|

## UI 와이어프레임
(ASCII art if UI, or N/A)

## 호출 진입점
- **어디서:**
- **어떻게:**

## 수용 기준
- [ ] ...
===END===
\`\`\`

Rules:
- Order: data/core first, then logic, then UI, then assets
- Be specific and actionable — each task should be 1-3 hours of work
- Include asset tasks (🎨) where visual/audio assets are needed
- Reference existing systems when connecting to them
- Write descriptions in Korean
- Number sequentially from R-$(printf '%03d' $NEXT_R) and A-$(printf '%03d' $NEXT_A)"

# Claude CLI 호출을 위한 안전한 방법 시도
CLAUDE_OUTPUT=""
if command -v claude >/dev/null 2>&1; then
    CLAUDE_OUTPUT=$(claude --print "$PROMPT" 2>/dev/null)
elif command -v claude-cli >/dev/null 2>&1; then
    CLAUDE_OUTPUT=$(claude-cli --print "$PROMPT" 2>/dev/null)
else
    echo "  [ERROR] Claude CLI가 설치되지 않았습니다."
    echo "  Claude CLI를 설치하거나 수동으로 프롬프트를 처리해주세요."
    echo ""
    echo "=== 프롬프트 내용 ==="
    echo "$PROMPT"
    echo "==================="
    exit 1
fi

if [ -z "$CLAUDE_OUTPUT" ]; then
    echo "  [ERROR] Claude 출력이 비어있습니다."
    echo "  Claude CLI 설정을 확인하거나 수동으로 프롬프트를 처리해주세요."
    echo ""
    echo "=== 프롬프트 내용 ==="
    echo "$PROMPT"
    echo "==================="
    exit 1
fi

# --- BACKLOG 추출 → 기존 파일에 APPEND ---
echo "📝 Appending to BACKLOG_RESERVE.md..."

BACKLOG_NEW=$(echo "$CLAUDE_OUTPUT" | sed -n '/===BACKLOG===/,/===END_BACKLOG===/{/===BACKLOG===/d;/===END_BACKLOG===/d;p;}')

if [ -z "$BACKLOG_NEW" ]; then
    # fallback: ### 으로 시작하는 라인 블록 추출
    BACKLOG_NEW=$(echo "$CLAUDE_OUTPUT" | sed -n '/^### /,/^===SPEC/{/^===SPEC/d;p;}')
fi

if [ -n "$BACKLOG_NEW" ]; then
    # 기존 BACKLOG에 append
    echo "" >> "$BACKLOG"
    echo "### --- [$(date '+%Y-%m-%d')] $REQUEST ---" >> "$BACKLOG"
    echo "" >> "$BACKLOG"
    echo "$BACKLOG_NEW" >> "$BACKLOG"

    NEW_TASK_COUNT=$(echo "$BACKLOG_NEW" | grep -c '^### ' || true)
    echo "  ✅ ${NEW_TASK_COUNT}건 태스크 추가"
else
    echo "  ⚠️  BACKLOG 파싱 실패"
fi

# --- SPEC 파일 추출 ---
echo "📋 Creating SPEC files..."

SPEC_COUNT=0
while IFS= read -r spec_id; do
    spec_content=$(echo "$CLAUDE_OUTPUT" | sed -n "/===SPEC:${spec_id}===/,/===END===/{/===SPEC:/d;/===END===/d;p;}")
    if [ -n "$spec_content" ]; then
        spec_file="$SPEC_DIR/SPEC-${spec_id}.md"
        echo "$spec_content" > "$spec_file"
        SPEC_COUNT=$((SPEC_COUNT + 1))
    fi
done < <(echo "$CLAUDE_OUTPUT" | grep -o '===SPEC:[^=]*===' | sed 's/===SPEC://;s/===//')

echo "  ✅ ${SPEC_COUNT}건 SPEC 생성"

echo ""
echo "============================================"
echo " Done!"
echo "============================================"
echo ""
echo "  Added ${NEW_TASK_COUNT:-0} tasks + ${SPEC_COUNT} specs"
echo "  Developer will auto-pickup from BACKLOG."
echo ""
