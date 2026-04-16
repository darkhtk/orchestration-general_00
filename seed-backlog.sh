#!/bin/bash
# =============================================================================
# Seed Backlog from Feature List
# =============================================================================
# 프로젝트의 기능 리스트 MD 파일을 읽어서
# BACKLOG_RESERVE.md + specs/ 를 자동 생성합니다.
#
# 사용법:
#   bash seed-backlog.sh /path/to/project [feature-list.md]
#
# feature-list.md를 지정하지 않으면 프로젝트에서 자동 탐색:
#   GDD.md, FEATURES.md, TODO.md, ROADMAP.md, README.md 등
# =============================================================================

set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
FEATURE_FILE="${2:-}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "[ERROR] Project directory not found: $PROJECT_DIR"
    exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# --- Feature list 파일 탐색 ---
if [ -z "$FEATURE_FILE" ]; then
    echo "🔍 Feature list 파일 탐색..."
    # 우선순위 순서로 탐색
    CANDIDATES=(
        "GDD.md" "gdd.md"
        "FEATURES.md" "features.md"
        "ROADMAP.md" "roadmap.md"
        "TODO.md" "todo.md"
        "REQUIREMENTS.md" "requirements.md"
        "DESIGN.md" "design.md"
        "PLAN.md" "plan.md"
    )

    for candidate in "${CANDIDATES[@]}"; do
        found=$(find "$PROJECT_DIR" -maxdepth 3 -name "$candidate" -print -quit 2>/dev/null)
        if [ -n "$found" ]; then
            FEATURE_FILE="$found"
            echo "  ✅ 발견: $FEATURE_FILE"
            break
        fi
    done

    # 못 찾으면 docs/ 하위 MD 파일 탐색
    if [ -z "$FEATURE_FILE" ]; then
        found=$(find "$PROJECT_DIR" -maxdepth 3 -path "*/docs/*.md" -print -quit 2>/dev/null)
        if [ -n "$found" ]; then
            FEATURE_FILE="$found"
            echo "  ✅ 발견 (docs/): $FEATURE_FILE"
        fi
    fi

    if [ -z "$FEATURE_FILE" ]; then
        echo "  ⚠️  Feature list 파일을 찾지 못했습니다."
        echo ""
        echo "  사용법: bash seed-backlog.sh /path/to/project features.md"
        echo "  또는 프로젝트에 GDD.md, FEATURES.md, ROADMAP.md 등을 만들어주세요."
        exit 1
    fi
fi

# 절대 경로 변환
if [[ "$FEATURE_FILE" != /* ]]; then
    FEATURE_FILE="$PROJECT_DIR/$FEATURE_FILE"
fi

if [ ! -f "$FEATURE_FILE" ]; then
    echo "[ERROR] File not found: $FEATURE_FILE"
    exit 1
fi

echo ""
echo "============================================"
echo " Seed Backlog from Feature List"
echo "============================================"
echo ""
echo "  Project:  $PROJECT_DIR"
echo "  Features: $FEATURE_FILE"
echo ""

# --- orchestration 디렉토리 확인 ---
if [ ! -d "$PROJECT_DIR/orchestration" ]; then
    echo "[ERROR] orchestration/ directory not found."
    echo "  Run auto-setup.sh first."
    exit 1
fi

# --- config 읽기 ---
CONFIG="$PROJECT_DIR/orchestration/project.config.md"
DEV_PRIORITY=""
if [ -f "$CONFIG" ]; then
    DEV_PRIORITY=$(grep -A2 '개발 방향' "$CONFIG" 2>/dev/null | tail -2)
fi

# --- Feature list 내용 읽기 ---
FEATURE_CONTENT=$(cat "$FEATURE_FILE")
FEATURE_LINES=$(echo "$FEATURE_CONTENT" | wc -l)
echo "  Feature list: ${FEATURE_LINES} lines"
echo ""

# --- Claude를 사용해 BACKLOG + SPEC 생성 ---
echo "🤖 Claude로 BACKLOG + SPEC 생성 중..."
echo ""

BACKLOG_FILE="$PROJECT_DIR/orchestration/BACKLOG_RESERVE.md"
SPEC_DIR="$PROJECT_DIR/orchestration/specs"

# Claude에게 보낼 프롬프트
PROMPT=$(cat << 'PROMPTEOF'
You are a game project planner. Read the feature list below and generate two things:

## Task 1: BACKLOG_RESERVE.md

Convert each feature/requirement into actionable development tasks.
Output format (Korean):

```
# Backlog Reserve — 상시 개선 태스크 풀

> **용도:** BOARD의 Backlog가 0건일 때 개발자가 자가 배정하는 예비 목록.
> 위에서부터 순서대로 선택. 완료 후 이 파일에서 삭제 + BOARD Done에 추가.
> 감독관/Coordinator가 수시로 항목을 보충한다.

## 규칙
- 개발자는 BOARD Backlog가 0건이면 이 파일에서 최상단 항목을 가져가 BOARD에 등록 + 구현.
- 한 번에 1건만 가져간다.
- 가져간 항목은 이 파일에서 삭제하고 BOARD 로드맵에 추가한다.
- tasks/TASK-XXX.md 파일이 없으면 여기 설명으로 충분 — 별도 생성 불필요.
- **🎨 태그 태스크는 감독관 전용** — 개발자는 스킵하고 다음 항목을 가져간다.
- **specs/SPEC-XXX.md 존재 시 기획서 따라 구현.**

---

## 예비 태스크 (위에서부터 선택)

### R-001: [task title]
[1-2 line description]. specs/SPEC-R-001.md 참조.

### 🎨 A-001: [asset task title]
[1-2 line description of art/audio asset needed]

...
```

Rules for task ordering:
1. Core systems first (data structures, managers, singletons)
2. Then gameplay features that depend on core
3. Then UI/UX
4. Then polish (VFX, SFX, animations)
5. Asset tasks (🎨) interspersed where needed
6. Use R-XXX for code tasks, A-XXX for asset tasks, 🎨 prefix for supervisor-only

## Task 2: SPEC files

For each R-XXX task, create a spec file content block. Format:

```
===SPEC:R-XXX===
# SPEC-R-XXX: [feature name]

**관련 태스크:** R-XXX
**작성일:** TODAY

---

## 개요
(1-line description)

## 상세 설명
(purpose, context, expected behavior)

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| ... | ... | ... |

## 데이터 구조
```
(class/struct/SO definition sketch)
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| ... | ... | (event/direct/callback) |

## UI 와이어프레임
```
(ASCII wireframe if UI involved, or "N/A")
```

## 호출 진입점
- **어디서:** (which UI/situation)
- **어떻게:** (which button/key)

## 수용 기준
- [ ] ...
- [ ] ...
===END===
```

Now read this feature list and generate the output:

---FEATURE_LIST---
PROMPTEOF
)

# Feature content를 프롬프트에 붙이기
FULL_PROMPT="${PROMPT}
${FEATURE_CONTENT}
---END_FEATURE_LIST---

Generate the BACKLOG_RESERVE.md content first, then all SPEC files. Be thorough - cover every feature mentioned. Output in the exact format specified above."

# Claude 실행
# 임시 파일을 사용하여 셸 인젝션 방지
TEMP_PROMPT=$(mktemp)
printf '%s' "$FULL_PROMPT" > "$TEMP_PROMPT"
CLAUDE_OUTPUT=$(claude --print @"$TEMP_PROMPT" 2>/dev/null)
rm -f "$TEMP_PROMPT"

if [ -z "$CLAUDE_OUTPUT" ]; then
    echo "  [ERROR] Claude output is empty. Check if claude CLI is available."
    exit 1
fi

# --- BACKLOG 추출 및 저장 ---
echo "📝 BACKLOG_RESERVE.md 생성..."

# BACKLOG 부분 추출 (# Backlog Reserve 부터 첫 ===SPEC 전까지)
BACKLOG_CONTENT=$(echo "$CLAUDE_OUTPUT" | sed -n '/^# Backlog Reserve/,/^===SPEC:/{ /^===SPEC:/d; p; }')

if [ -z "$BACKLOG_CONTENT" ]; then
    # fallback: 전체 출력에서 SPEC 부분 제거
    BACKLOG_CONTENT=$(echo "$CLAUDE_OUTPUT" | sed '/^===SPEC:/,/^===END===/d')
fi

if [ -n "$BACKLOG_CONTENT" ]; then
    echo "$BACKLOG_CONTENT" > "$BACKLOG_FILE"
    TASK_COUNT=$(echo "$BACKLOG_CONTENT" | grep -c '^### ' || true)
    echo "  ✅ ${TASK_COUNT}건 태스크 생성"
else
    echo "  ⚠️  BACKLOG 파싱 실패 — 원본 출력을 저장합니다."
    echo "$CLAUDE_OUTPUT" > "$BACKLOG_FILE"
fi

# --- SPEC 파일 추출 및 저장 ---
echo "📋 SPEC 파일 생성..."

SPEC_COUNT=0
# ===SPEC:R-XXX=== 부터 ===END=== 까지 추출
while IFS= read -r spec_id; do
    # spec_id = R-001 등
    spec_content=$(echo "$CLAUDE_OUTPUT" | sed -n "/^===SPEC:${spec_id}===/,/^===END===/{ /^===SPEC:/d; /^===END===/d; p; }")

    if [ -n "$spec_content" ]; then
        spec_file="$SPEC_DIR/SPEC-${spec_id}.md"
        echo "$spec_content" > "$spec_file"
        SPEC_COUNT=$((SPEC_COUNT + 1))
    fi
done < <(echo "$CLAUDE_OUTPUT" | grep -o '===SPEC:[^=]*===' | sed 's/===SPEC://;s/===//')

echo "  ✅ ${SPEC_COUNT}건 SPEC 파일 생성"

echo ""
echo "============================================"
echo " ✅ Backlog Seeding 완료!"
echo "============================================"
echo ""
echo "  BACKLOG: $BACKLOG_FILE"
echo "  SPECS:   $SPEC_DIR/ (${SPEC_COUNT}건)"
echo ""
echo "  에이전트를 실행하면 Developer가 자동으로 태스크를 픽업합니다."
echo ""
