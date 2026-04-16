#!/bin/bash
# =============================================================================
# Extract Feature List from Project
# =============================================================================
# 프로젝트 코드를 분석해서 FEATURES.md (기능 리스트)를 자동 생성합니다.
# seed-backlog.sh와 함께 사용하면 전체 자동화가 됩니다.
#
# 사용법:
#   bash extract-features.sh /path/to/project
# =============================================================================

set -e

PROJECT_DIR="${1:-.}"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "[ERROR] Project directory not found: $PROJECT_DIR"
    exit 1
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

OUTPUT_FILE="$PROJECT_DIR/FEATURES.md"

echo ""
echo "============================================"
echo " Extract Feature List"
echo "============================================"
echo ""
echo "  Project: $PROJECT_DIR"
echo ""

# --- 프로젝트 정보 수집 ---
echo "🔍 Collecting project info..."

# 기존 문서 수집
EXISTING_DOCS=""
for doc in README.md GDD.md DESIGN.md PLAN.md docs/*.md; do
    found=$(find "$PROJECT_DIR" -maxdepth 3 -name "$(basename "$doc")" -print 2>/dev/null | head -3)
    if [ -n "$found" ]; then
        for f in $found; do
            content=$(head -100 "$f" 2>/dev/null)
            EXISTING_DOCS="${EXISTING_DOCS}

--- FILE: ${f#$PROJECT_DIR/} ---
${content}
--- END ---"
        done
    fi
done

# 소스 파일 목록
SRC_FILES=$(find "$PROJECT_DIR" -maxdepth 6 \
    \( -name "*.cs" -o -name "*.gd" -o -name "*.cpp" -o -name "*.h" -o -name "*.py" -o -name "*.ts" -o -name "*.js" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/Library/*" ! -path "*/.godot/*" \
    2>/dev/null | sort)

SRC_COUNT=$(echo "$SRC_FILES" | grep -c '.' || true)
echo "  Source files: ${SRC_COUNT}"

# 주요 클래스/시스템 추출 (파일명 기반)
SYSTEMS=$(echo "$SRC_FILES" | xargs -I{} basename {} 2>/dev/null | sort -u)

# 핵심 파일 내용 샘플 (Manager, Controller, System 등)
KEY_FILES=""
for pattern in Manager Controller System Service Handler; do
    matches=$(echo "$SRC_FILES" | grep -i "$pattern" | head -5)
    for f in $matches; do
        content=$(head -50 "$f" 2>/dev/null)
        KEY_FILES="${KEY_FILES}

--- FILE: ${f#$PROJECT_DIR/} ---
${content}
--- END ---"
    done
done

# Git 커밋 히스토리에서 기능 힌트
GIT_FEATURES=""
if [ -d "$PROJECT_DIR/.git" ]; then
    GIT_FEATURES=$(cd "$PROJECT_DIR" && git log --oneline -50 2>/dev/null | grep -iE 'feat|add|implement|create' || true)
fi

echo "  Key systems found: $(echo "$SYSTEMS" | grep -ciE 'Manager|Controller|System|Service' || true)"
echo ""

# --- Claude로 Feature List 생성 ---
echo "🤖 Analyzing project with Claude..."
echo ""

PROMPT="You are a game project analyst. Analyze this project and create a comprehensive FEATURES.md.

## Project Files
Source files (${SRC_COUNT} total):
$(echo "$SRC_FILES" | sed "s|$PROJECT_DIR/||g" | head -100)

## Key System Files
${KEY_FILES}

## Existing Documentation
${EXISTING_DOCS}

## Recent Feature Commits
${GIT_FEATURES}

---

Based on the above, generate a FEATURES.md with this exact format:

\`\`\`markdown
# [Project Name] - Feature List

## Core Systems
### [System Name]
- **Status:** Done / In Progress / Not Started
- **Description:** (1-2 lines)
- **Sub-features:**
  - [ ] or [x] feature detail
  - [ ] or [x] feature detail

(repeat for each core system)

## Gameplay Features
### [Feature Name]
- **Status:** Done / In Progress / Not Started
- **Description:** (1-2 lines)
- **Sub-features:**
  - [ ] or [x] feature detail

## UI/UX
### [UI Component]
- **Status:** Done / In Progress / Not Started
- **Sub-features:**
  - [ ] or [x] detail

## Art & Audio
### Sprites
- [ ] or [x] detail
### Audio
- [ ] or [x] detail

## Polish & QoL
- [ ] or [x] detail

## Known Issues / TODO
- [ ] issue or todo item
\`\`\`

Rules:
- Mark [x] for features that clearly exist in code, [ ] for missing/incomplete
- Be thorough - extract every system, feature, UI element from the code
- Group logically
- Include features that SHOULD exist but DON'T (based on game genre)
- Write in Korean for descriptions
- This will be used to auto-generate development tasks, so be specific"

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

# markdown 코드블록 제거 (있으면)
CLEAN_OUTPUT=$(echo "$CLAUDE_OUTPUT" | sed '/^```markdown$/d' | sed '/^```$/d')

echo "$CLEAN_OUTPUT" > "$OUTPUT_FILE"

FEATURE_COUNT=$(grep -c '^\- \[' "$OUTPUT_FILE" 2>/dev/null || true)
DONE_COUNT=$(grep -c '^\- \[x\]' "$OUTPUT_FILE" 2>/dev/null || true)
TODO_COUNT=$(grep -c '^\- \[ \]' "$OUTPUT_FILE" 2>/dev/null || true)

echo ""
echo "============================================"
echo " Feature List Generated!"
echo "============================================"
echo ""
echo "  Output:    $OUTPUT_FILE"
echo "  Total:     ${FEATURE_COUNT} features"
echo "  Done:      ${DONE_COUNT}"
echo "  TODO:      ${TODO_COUNT}"
echo ""
echo "  Next: run seed-backlog.sh to create tasks from this list"
echo ""
