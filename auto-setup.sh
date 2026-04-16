#!/bin/bash
# =============================================================================
# Claude Orchestration Auto-Setup
# =============================================================================
# 기존 Claude 프로젝트의 상태(메모리, CLAUDE.md, 파일 구조)를 읽어서
# project.config.md를 자동 생성하고 오케스트레이션 시스템을 셋업합니다.
#
# 사용법:
#   bash auto-setup.sh /path/to/game-project
#   bash auto-setup.sh .                      # 현재 디렉토리
# =============================================================================

set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"

# --- Python 프로젝트 감지 함수들 ---
detect_python_project() {
    # requirements.txt 체크
    if [[ -f "$PROJECT_DIR/requirements.txt" ]]; then
        if grep -qi "django" "$PROJECT_DIR/requirements.txt"; then
            echo "python-django"
        elif grep -qi "flask" "$PROJECT_DIR/requirements.txt"; then
            echo "python-flask"
        elif grep -qi "fastapi" "$PROJECT_DIR/requirements.txt"; then
            echo "python-fastapi"
        else
            echo "python-general"
        fi
        return 0
    fi

    # pyproject.toml 체크
    if [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
        if grep -qi "django" "$PROJECT_DIR/pyproject.toml"; then
            echo "python-django"
        elif grep -qi "flask" "$PROJECT_DIR/pyproject.toml"; then
            echo "python-flask"
        elif grep -qi "fastapi" "$PROJECT_DIR/pyproject.toml"; then
            echo "python-fastapi"
        else
            echo "python-general"
        fi
        return 0
    fi

    # manage.py 체크 (Django 특화)
    if [[ -f "$PROJECT_DIR/manage.py" ]]; then
        echo "python-django"
        return 0
    fi

    # 기타 Python 파일들
    if [[ -f "$PROJECT_DIR/setup.py" || -f "$PROJECT_DIR/Pipfile" || -f "$PROJECT_DIR/poetry.lock" || -f "$PROJECT_DIR/.python-version" ]]; then
        echo "python-general"
        return 0
    fi

    return 1
}

detect_python_version() {
    if [[ -f "$PROJECT_DIR/.python-version" ]]; then
        cat "$PROJECT_DIR/.python-version"
    elif [[ -f "$PROJECT_DIR/pyproject.toml" ]] && grep -q "python" "$PROJECT_DIR/pyproject.toml"; then
        grep "python" "$PROJECT_DIR/pyproject.toml" | head -1 | sed 's/.*python.*=.*"\([0-9.]*\)".*/\1/'
    else
        python3 --version 2>/dev/null | awk '{print $2}' || echo "3.9+"
    fi
}

detect_package_manager() {
    if [[ -f "$PROJECT_DIR/poetry.lock" ]]; then
        echo "poetry"
    elif [[ -f "$PROJECT_DIR/Pipfile" ]]; then
        echo "pipenv"
    elif [[ -f "$PROJECT_DIR/requirements.txt" ]]; then
        echo "pip"
    else
        echo "pip"
    fi
}

echo "============================================"
echo " Claude Orchestration Auto-Setup"
echo "============================================"
echo ""
echo "  Project: $PROJECT_DIR"
echo ""

# ---------------------------------------------------------------------------
# Phase 1: 프로젝트 자동 감지
# ---------------------------------------------------------------------------

echo "🔍 Phase 1: 프로젝트 자동 감지..."
echo ""

# --- 엔진 감지 ---
ENGINE=""
LANGUAGE=""
ERROR_LOG_PATH=""
ERROR_PATTERN=""
WARNING_PATTERN=""

# Unity
if ls "$PROJECT_DIR"/*.meta &>/dev/null || find "$PROJECT_DIR" -maxdepth 3 -name "*.meta" -print -quit 2>/dev/null | grep -q .; then
    ENGINE="Unity"
    LANGUAGE="C#"
    ERROR_LOG_PATH='%LOCALAPPDATA%\Unity\Editor\Editor.log'
    ERROR_PATTERN="error CS"
    WARNING_PATTERN="warning CS"
    # Unity 버전 감지 (ProjectVersion.txt 우선, fallback ProjectSettings.asset)
    PROJECT_VERSION_TXT=$(find "$PROJECT_DIR" -maxdepth 5 -name "ProjectVersion.txt" -print -quit 2>/dev/null)
    if [ -n "$PROJECT_VERSION_TXT" ]; then
        UNITY_VERSION=$(grep 'm_EditorVersion:' "$PROJECT_VERSION_TXT" 2>/dev/null | head -1 | sed 's/.*m_EditorVersion: //')
    else
        PROJECT_SETTINGS=$(find "$PROJECT_DIR" -maxdepth 4 -name "ProjectSettings.asset" -print -quit 2>/dev/null)
        if [ -n "$PROJECT_SETTINGS" ]; then
            UNITY_VERSION=$(grep 'm_EditorVersion:' "$PROJECT_SETTINGS" 2>/dev/null | sed 's/.*m_EditorVersion: //' | head -1)
        fi
    fi
    [ -z "$UNITY_VERSION" ] && UNITY_VERSION="unknown"
    ENGINE="Unity $UNITY_VERSION"
    echo "  ✅ 엔진: $ENGINE"
fi

# Godot
if find "$PROJECT_DIR" -maxdepth 2 -name "project.godot" -print -quit 2>/dev/null | grep -q .; then
    ENGINE="Godot"
    GODOT_FILE=$(find "$PROJECT_DIR" -maxdepth 2 -name "project.godot" -print -quit)
    # GDScript vs C#
    if find "$PROJECT_DIR" -maxdepth 5 -name "*.gd" -print -quit 2>/dev/null | grep -q .; then
        LANGUAGE="GDScript"
    elif find "$PROJECT_DIR" -maxdepth 5 -name "*.cs" -print -quit 2>/dev/null | grep -q .; then
        LANGUAGE="C#"
    fi
    ERROR_LOG_PATH="(Godot Output)"
    ERROR_PATTERN="ERROR"
    WARNING_PATTERN="WARNING"
    echo "  ✅ 엔진: $ENGINE ($LANGUAGE)"
fi

# Unreal
if find "$PROJECT_DIR" -maxdepth 2 -name "*.uproject" -print -quit 2>/dev/null | grep -q .; then
    ENGINE="Unreal Engine"
    LANGUAGE="C++ / Blueprint"
    UPROJECT=$(find "$PROJECT_DIR" -maxdepth 2 -name "*.uproject" -print -quit)
    UE_VERSION=$(grep '"EngineAssociation"' "$UPROJECT" 2>/dev/null | sed 's/.*: *"//;s/".*//' | head -1)
    [ -z "$UE_VERSION" ] && UE_VERSION="unknown"
    ENGINE="Unreal Engine $UE_VERSION"
    ERROR_LOG_PATH='%LOCALAPPDATA%\UnrealEngine\Saved\Logs'
    ERROR_PATTERN="Error:"
    WARNING_PATTERN="Warning:"
    echo "  ✅ 엔진: $ENGINE"
fi

# Python 프로젝트
if [ -z "$ENGINE" ]; then
    PYTHON_TYPE=$(detect_python_project)
    if [ $? -eq 0 ]; then
        PYTHON_VERSION=$(detect_python_version)
        PKG_MANAGER=$(detect_package_manager)
        case "$PYTHON_TYPE" in
            python-django)
                ENGINE="Django"
                LANGUAGE="Python $PYTHON_VERSION"
                ERROR_PATTERN="Error"
                WARNING_PATTERN="Warning"
                echo "  ✅ 프레임워크: Django (Python $PYTHON_VERSION, $PKG_MANAGER)"
                ;;
            python-flask)
                ENGINE="Flask"
                LANGUAGE="Python $PYTHON_VERSION"
                ERROR_PATTERN="Error"
                WARNING_PATTERN="Warning"
                echo "  ✅ 프레임워크: Flask (Python $PYTHON_VERSION, $PKG_MANAGER)"
                ;;
            python-fastapi)
                ENGINE="FastAPI"
                LANGUAGE="Python $PYTHON_VERSION"
                ERROR_PATTERN="Error"
                WARNING_PATTERN="Warning"
                echo "  ✅ 프레임워크: FastAPI (Python $PYTHON_VERSION, $PKG_MANAGER)"
                ;;
            python-general)
                ENGINE="Python"
                LANGUAGE="Python $PYTHON_VERSION"
                ERROR_PATTERN="Error"
                WARNING_PATTERN="Warning"
                echo "  ✅ 언어: Python $PYTHON_VERSION ($PKG_MANAGER)"
                ;;
        esac
        ERROR_LOG_PATH="stdout"
    fi
fi

if [ -z "$ENGINE" ]; then
    echo "  ⚠️  엔진 자동 감지 실패 — project.config.md에서 수동 설정 필요"
    ENGINE="(수동 입력 필요)"
    LANGUAGE="(수동 입력 필요)"
fi

# --- 디렉토리 구조 감지 ---
echo ""
echo "  📁 디렉토리 구조 스캔..."

SRC_DIR=""
ASSET_SPRITE_DIR=""
ASSET_AUDIO_DIR=""
ASSET_RESOURCE_DIR=""
TEST_DIR=""
SCENE_DIR=""
TOOL_DIR=""

# Unity 구조
if [[ "$ENGINE" == Unity* ]]; then
    # Assets/Scripts 패턴
    SRC_DIR=$(find "$PROJECT_DIR" -maxdepth 4 -type d -name "Scripts" -path "*/Assets/*" -print -quit 2>/dev/null)
    ASSET_SPRITE_DIR=$(find "$PROJECT_DIR" -maxdepth 4 -type d \( -name "Sprites" -o -name "Textures" \) -path "*/Assets/*" -print -quit 2>/dev/null)
    ASSET_AUDIO_DIR=$(find "$PROJECT_DIR" -maxdepth 4 -type d -name "Audio" -path "*/Assets/*" -print -quit 2>/dev/null)
    ASSET_RESOURCE_DIR=$(find "$PROJECT_DIR" -maxdepth 4 -type d -name "Resources" -path "*/Assets/*" -print -quit 2>/dev/null)
    TEST_DIR=$(find "$PROJECT_DIR" -maxdepth 5 -type d -name "EditMode" -path "*/Tests/*" -print -quit 2>/dev/null)
    SCENE_DIR=$(find "$PROJECT_DIR" -maxdepth 4 -type d -name "Scenes" -path "*/Assets/*" -print -quit 2>/dev/null)
fi

# Godot 구조
if [[ "$ENGINE" == Godot* ]]; then
    SRC_DIR=$(find "$PROJECT_DIR" -maxdepth 3 -type d \( -name "scripts" -o -name "src" \) -print -quit 2>/dev/null)
    ASSET_SPRITE_DIR=$(find "$PROJECT_DIR" -maxdepth 3 -type d \( -name "sprites" -o -name "textures" -o -name "art" \) -print -quit 2>/dev/null)
    ASSET_AUDIO_DIR=$(find "$PROJECT_DIR" -maxdepth 3 -type d \( -name "audio" -o -name "sfx" -o -name "music" \) -print -quit 2>/dev/null)
    SCENE_DIR=$(find "$PROJECT_DIR" -maxdepth 3 -type d -name "scenes" -print -quit 2>/dev/null)
    TEST_DIR=$(find "$PROJECT_DIR" -maxdepth 3 -type d \( -name "tests" -o -name "test" \) -print -quit 2>/dev/null)
fi

# Python 구조
if [[ "$ENGINE" == Django* ]] || [[ "$ENGINE" == Flask* ]] || [[ "$ENGINE" == FastAPI* ]] || [[ "$ENGINE" == Python* ]]; then
    # Django 특화 구조
    if [[ "$ENGINE" == Django* ]]; then
        SRC_DIR=$(find "$PROJECT_DIR" -maxdepth 2 -type d -name "*" | grep -v "__pycache__" | head -1)
        if [ -d "$PROJECT_DIR/static" ]; then
            ASSET_SPRITE_DIR="$PROJECT_DIR/static/images"
            ASSET_AUDIO_DIR="$PROJECT_DIR/static/audio"
            ASSET_RESOURCE_DIR="$PROJECT_DIR/static"
        fi
    else
        # Flask/FastAPI/일반 Python 구조
        SRC_DIR=$(find "$PROJECT_DIR" -maxdepth 2 -type d \( -name "src" -o -name "app" -o -name "*" \) | grep -v "__pycache__" | grep -v ".git" | grep -v "venv" | grep -v ".venv" | head -1)
        ASSET_SPRITE_DIR=$(find "$PROJECT_DIR" -maxdepth 3 -type d \( -name "static" -o -name "assets" \) -print -quit 2>/dev/null)
        ASSET_AUDIO_DIR="$ASSET_SPRITE_DIR"
        ASSET_RESOURCE_DIR="$ASSET_SPRITE_DIR"
    fi

    TEST_DIR=$(find "$PROJECT_DIR" -maxdepth 2 -type d \( -name "tests" -o -name "test" \) -print -quit 2>/dev/null)
    if [ -z "$TEST_DIR" ]; then
        TEST_DIR="tests/"
    fi
    SCENE_DIR="templates/"
fi

# 공통: tools 디렉토리
TOOL_DIR=$(find "$PROJECT_DIR" -maxdepth 2 -type d -name "tools" -print -quit 2>/dev/null)

# 상대 경로 변환
rel_path() {
    local full="$1"
    if [ -n "$full" ]; then
        echo "${full#$PROJECT_DIR/}"
    else
        echo "(미감지)"
    fi
}

SRC_REL=$(rel_path "$SRC_DIR")
SPRITE_REL=$(rel_path "$ASSET_SPRITE_DIR")
AUDIO_REL=$(rel_path "$ASSET_AUDIO_DIR")
RESOURCE_REL=$(rel_path "$ASSET_RESOURCE_DIR")
TEST_REL=$(rel_path "$TEST_DIR")
SCENE_REL=$(rel_path "$SCENE_DIR")
TOOL_REL=$(rel_path "$TOOL_DIR")

echo "    소스코드: $SRC_REL"
echo "    스프라이트: $SPRITE_REL"
echo "    오디오: $AUDIO_REL"
echo "    리소스: $RESOURCE_REL"
echo "    테스트: $TEST_REL"
echo "    씬: $SCENE_REL"
echo "    도구: $TOOL_REL"

# --- Claude 메모리 읽기 ---
echo ""
echo "  🧠 Claude 메모리 스캔..."

# 프로젝트 경로를 Claude 메모리 경로로 변환
# Windows: C:\Users\darkh\Desktop\myGame → C--Users-darkh-Desktop-myGame
# Git Bash: /c/Users/darkh/Desktop/myGame → C--Users-darkh-Desktop-myGame
# Drive letter: /c/ → C--  (uppercase via tr, no GNU \U dependency)
DRIVE_LETTER=$(echo "$PROJECT_DIR" | sed -n 's|^/\([a-zA-Z]\)/.*|\1|p' | tr '[:lower:]' '[:upper:]')
if [ -n "$DRIVE_LETTER" ]; then
    CLAUDE_PROJECT_KEY="${DRIVE_LETTER}--$(echo "$PROJECT_DIR" | sed 's|^/[a-zA-Z]/||' | sed 's|/|-|g')"
else
    CLAUDE_PROJECT_KEY=$(echo "$PROJECT_DIR" | sed 's|/|-|g' | sed 's|^-||')
fi
CLAUDE_PROJECT_KEY2="$CLAUDE_PROJECT_KEY"

CLAUDE_HOME="$HOME/.claude"
# Windows: USERPROFILE
if [ -d "/c/Users" ]; then
    CLAUDE_HOME=$(echo "$HOME" | sed 's|^/c/|/c/|')/.claude
fi

MEMORY_DIR=""
for key in "$CLAUDE_PROJECT_KEY" "$CLAUDE_PROJECT_KEY2"; do
    candidate="$CLAUDE_HOME/projects/$key/memory"
    if [ -d "$candidate" ]; then
        MEMORY_DIR="$candidate"
        break
    fi
done

# 직접 검색 fallback
if [ -z "$MEMORY_DIR" ]; then
    BASENAME=$(basename "$PROJECT_DIR")
    MEMORY_DIR=$(find "$CLAUDE_HOME/projects" -maxdepth 2 -type d -name "memory" -path "*$BASENAME*" -print -quit 2>/dev/null)
fi

PROJECT_NAME=""
PROJECT_DESCRIPTION=""
ART_STYLE=""
COMMIT_CONVENTION=""
ARCHITECTURE_RULES=""
EMAIL_SUBJECT=""
EMAIL_INTERVAL=""
FEEDBACK_ITEMS=""

if [ -n "$MEMORY_DIR" ] && [ -d "$MEMORY_DIR" ]; then
    MEMORY_COUNT=$(ls -1 "$MEMORY_DIR"/*.md 2>/dev/null | wc -l)
    echo "    메모리 파일: ${MEMORY_COUNT}건 발견 ($MEMORY_DIR)"

    # 프로젝트 정보 추출
    for f in "$MEMORY_DIR"/project_*.md; do
        [ -f "$f" ] || continue
        content=$(cat "$f")

        # 프로젝트명
        if echo "$content" | grep -q "Project:"; then
            name=$(echo "$content" | grep 'Project:' | sed 's/.*Project:\*\* *//' | sed 's/ *(.*//' | head -1)
            [ -n "$name" ] && PROJECT_NAME="$name"
        fi

        # 아트 스타일
        if echo "$content" | grep -qi "스타일\|art style\|visual"; then
            # "이미지 컨셉: **스타듀밸리 스타일**" 패턴
            style=$(echo "$content" | grep -i '이미지 컨셉\|아트 스타일\|Art style' | sed 's/.*[：:] *//' | sed 's/\*//g' | sed 's/^ *//' | sed 's/ *$//' | head -1)
            # fallback: description 필드에서
            if [ -z "$style" ]; then
                style=$(echo "$content" | grep 'description:' | sed 's/description: *//' | head -1)
            fi
            [ -n "$style" ] && ART_STYLE="$style"
        fi
    done

    # feedback 메모리에서 규칙 추출
    for f in "$MEMORY_DIR"/feedback_*.md; do
        [ -f "$f" ] || continue
        desc=$(grep 'description:' "$f" 2>/dev/null | sed 's/description: *//' | head -1)
        if [ -n "$desc" ]; then
            FEEDBACK_ITEMS="${FEEDBACK_ITEMS}
- ${desc}"
        fi
    done

    # reference 메모리에서 이메일 설정 추출
    for f in "$MEMORY_DIR"/reference_*.md; do
        [ -f "$f" ] || continue
        content=$(cat "$f")
        subj=$(echo "$content" | grep 'subject:' | sed 's/.*subject://' | grep -o '\[[^]]*\]' | head -1)
        [ -n "$subj" ] && EMAIL_SUBJECT="$subj"
    done

    echo "    프로젝트명: ${PROJECT_NAME:-미감지}"
    echo "    아트 스타일: ${ART_STYLE:-미감지}"
    echo "    이메일 subject: ${EMAIL_SUBJECT:-미감지}"
else
    echo "    ⚠️  Claude 메모리 디렉토리 미발견"
fi

# --- CLAUDE.md 읽기 ---
CLAUDE_MD=""
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
    echo "    CLAUDE.md: 발견"
elif [ -f "$PROJECT_DIR/.claude/CLAUDE.md" ]; then
    CLAUDE_MD="$PROJECT_DIR/.claude/CLAUDE.md"
    echo "    CLAUDE.md: 발견 (.claude/)"
fi

# --- 기존 문서 스캔 (docs/, GDD, README, CLAUDE.md 등) ---
echo ""
echo "  📄 기존 문서 스캔"
echo ""
echo "    프로젝트의 기존 문서(docs/, GDD, README, CLAUDE.md 등)를"
echo "    에이전트가 첫 실행 시 읽도록 설정합니다."
echo ""
read -p "    기존 문서 분석 포함? (Y/n): " SCAN_DOCS || true

DOCS_LIST=""
DOCS_COUNT=0

if [ "$SCAN_DOCS" = "n" ] || [ "$SCAN_DOCS" = "N" ]; then
    echo "    → 문서 스캔 스킵"
else

# docs/ 디렉토리
if [ -d "$PROJECT_DIR/docs" ]; then
    while IFS= read -r f; do
        rel="${f#$PROJECT_DIR/}"
        title=$(head -5 "$f" 2>/dev/null | grep '^# ' | head -1 | sed 's/^# //')
        [ -z "$title" ] && title="(제목 없음)"
        DOCS_LIST="${DOCS_LIST}
- \`${rel}\` — ${title}"
        DOCS_COUNT=$((DOCS_COUNT + 1))
    done < <(find "$PROJECT_DIR/docs" -maxdepth 4 -type f \( -name "*.md" -o -name "*.html" -o -name "*.txt" \) 2>/dev/null | sort)
fi

# 루트 문서 (GDD.md, FEATURES.md, ROADMAP.md, README.md 등)
for doc in GDD.md FEATURES.md ROADMAP.md DESIGN.md PLAN.md TODO.md README.md CHANGELOG.md; do
    if [ -f "$PROJECT_DIR/$doc" ]; then
        title=$(head -5 "$PROJECT_DIR/$doc" 2>/dev/null | grep '^# ' | head -1 | sed 's/^# //')
        [ -z "$title" ] && title="(제목 없음)"
        DOCS_LIST="${DOCS_LIST}
- \`${doc}\` — ${title}"
        DOCS_COUNT=$((DOCS_COUNT + 1))
    fi
done

# CLAUDE.md
if [ -n "$CLAUDE_MD" ]; then
    DOCS_LIST="${DOCS_LIST}
- \`${CLAUDE_MD#$PROJECT_DIR/}\` — Claude 프로젝트 설정"
    DOCS_COUNT=$((DOCS_COUNT + 1))
fi

echo "    문서 ${DOCS_COUNT}건 발견"

fi  # SCAN_DOCS

# --- Git 정보 ---
echo ""
echo "  📦 Git 정보..."

GIT_REMOTE="없음"
GIT_BRANCH="master"
COMMIT_PUSH_POLICY="task"

if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "    ⚠️  Git 저장소가 아닙니다."
    echo ""
    read -p "    Git 초기화할까요? (Y/n): " GIT_INIT || true
    if [ "$GIT_INIT" != "n" ] && [ "$GIT_INIT" != "N" ]; then
        cd "$PROJECT_DIR" && git init
        GIT_BRANCH="master"
        echo "    ✅ git init 완료"
    fi
fi

if [ -d "$PROJECT_DIR/.git" ]; then
    GIT_REMOTE=$(cd "$PROJECT_DIR" && git remote get-url origin 2>/dev/null || echo "")
    GIT_BRANCH=$(cd "$PROJECT_DIR" && git branch --show-current 2>/dev/null || echo "master")

    if [ -z "$GIT_REMOTE" ]; then
        echo "    Remote: 없음"
        echo ""
        read -p "    원격 저장소 URL 입력 (없으면 Enter 스킵): " REMOTE_URL || true
        if [ -n "$REMOTE_URL" ]; then
            cd "$PROJECT_DIR" && git remote add origin "$REMOTE_URL"
            GIT_REMOTE="$REMOTE_URL"
            echo "    ✅ remote origin 추가: $REMOTE_URL"
        else
            GIT_REMOTE="없음"
        fi
    else
        echo "    Remote: $GIT_REMOTE"
    fi
    echo "    Branch: $GIT_BRANCH"

    # 커밋 메시지 패턴 감지
    COMMIT_SAMPLES=$(cd "$PROJECT_DIR" && git log --oneline -20 2>/dev/null || echo "")
    if echo "$COMMIT_SAMPLES" | grep -qE '^[a-f0-9]+ (feat|fix|refactor|test|chore|docs|asset):'; then
        COMMIT_CONVENTION="conventional commits (feat:/fix:/refactor:/test:/asset:/docs:)"
        echo "    커밋 컨벤션: Conventional Commits 감지"
    fi
fi

# --- Commit/Push 정책 ---
echo ""
echo "  📤 Commit/Push 정책 설정"
echo ""
echo "    1) task  — 태스크 완료 시마다 commit+push (기본)"
echo "    2) review — In Review 제출 시에만 push"
echo "    3) batch  — 30분마다 변경사항 일괄 push"
echo "    4) manual — 자동 push 안 함 (commit만 자동)"
echo ""
read -p "    선택 (1-4, 기본=1): " POLICY_CHOICE || true
case "$POLICY_CHOICE" in
    2) COMMIT_PUSH_POLICY="review" ;;
    3) COMMIT_PUSH_POLICY="batch" ;;
    4) COMMIT_PUSH_POLICY="manual" ;;
    *) COMMIT_PUSH_POLICY="task" ;;
esac
echo "    → 정책: $COMMIT_PUSH_POLICY"

# --- 개발 방향 ---
echo ""
echo "  🎯 개발 방향"
echo ""
echo "    1) stabilize — 안정화 (버그 수정, 방어 코드, 테스트)"
echo "    2) feature   — 기능 개발 (새 시스템, 핵심 흐름 확장)"
echo "    3) polish    — 폴리시 (UI/UX, 애니메이션, 사운드, QoL)"
echo "    4) content   — 콘텐츠 확장 (레벨, 아이템, NPC, 스토리)"
echo "    5) custom    — 직접 입력"
echo ""
read -p "    선택 (1-5, 기본=2): " DIRECTION_CHOICE || true
case "$DIRECTION_CHOICE" in
    1) DEV_DIRECTION="stabilize"
       DEV_PRIORITY_TEXT="안정성 > 기존 기능 개선 > 신규 기능. 버그 수정과 방어 코드 최우선. 신규 기능 추가 금지." ;;
    3) DEV_DIRECTION="polish"
       DEV_PRIORITY_TEXT="UX/UI 개선 > 비주얼/오디오 > 성능 최적화. 기능 변경 최소화, 체감 품질 향상 집중." ;;
    4) DEV_DIRECTION="content"
       DEV_PRIORITY_TEXT="콘텐츠 볼륨 확장 > 밸런스 조정 > 신규 시스템. 기존 시스템 위에 데이터 추가 중심." ;;
    5) DEV_DIRECTION="custom"
       echo ""
       read -p "    개발 방향 직접 입력: " CUSTOM_DIRECTION || true
       DEV_PRIORITY_TEXT="$CUSTOM_DIRECTION" ;;
    *) DEV_DIRECTION="feature"
       DEV_PRIORITY_TEXT="핵심 기능 > 시스템 깊이 > 콘텐츠. 기존 기능 개선과 신규 기능 병행." ;;
esac
echo "    → 방향: $DEV_DIRECTION"

# --- 에이전트 구성 ---
echo ""
echo "  🤖 에이전트 구성"
echo ""
echo "    1) full  — 4개 전부 (Supervisor + Developer + Client + Coordinator)"
echo "    2) lean  — 2개 (Developer + Supervisor만, 리뷰/관리 생략)"
echo "    3) solo  — 1개 (Developer만, 모든 역할 통합)"
echo ""
read -p "    선택 (1-3, 기본=1): " AGENT_CHOICE || true
case "$AGENT_CHOICE" in
    2) AGENT_MODE="lean" ;;
    3) AGENT_MODE="solo" ;;
    *) AGENT_MODE="full" ;;
esac
echo "    → 구성: $AGENT_MODE"

# --- 리뷰 강도 (full/lean일 때만) ---
REVIEW_LEVEL="standard"
if [ "$AGENT_MODE" != "solo" ]; then
    echo ""
    echo "  🔍 리뷰 강도"
    echo ""
    echo "    1) strict   — 모든 태스크 고객사 리뷰 필수"
    echo "    2) standard — 새 시스템만 리뷰, QA/수치조정은 자가진행 (기본)"
    echo "    3) minimal  — 리뷰 없음, 전부 자가진행"
    echo ""
    read -p "    선택 (1-3, 기본=2): " REVIEW_CHOICE || true
    case "$REVIEW_CHOICE" in
        1) REVIEW_LEVEL="strict" ;;
        3) REVIEW_LEVEL="minimal" ;;
        *) REVIEW_LEVEL="standard" ;;
    esac
    echo "    → 리뷰: $REVIEW_LEVEL"
fi

# --- 프로젝트명 fallback ---
LOOP_INTERVAL="2m"

if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME=$(basename "$PROJECT_DIR")
fi

echo ""
echo "============================================"
echo " Phase 2: project.config.md 생성"
echo "============================================"
echo ""

# ---------------------------------------------------------------------------
# Phase 2: project.config.md 자동 생성
# ---------------------------------------------------------------------------

CONFIG_PATH="$PROJECT_DIR/orchestration/project.config.md"

# 기존 config 백업
if [ -f "$CONFIG_PATH" ]; then
    BACKUP="${CONFIG_PATH}.bak"
    cp "$CONFIG_PATH" "$BACKUP"
    echo "  ⚠️  기존 project.config.md → .bak 백업 완료"
fi

# orchestration 디렉토리가 없으면 먼저 init.sh 실행
if [ ! -d "$PROJECT_DIR/orchestration" ]; then
    echo "📁 orchestration/ 디렉토리 생성 중 (init.sh)..."
    bash "$TEMPLATE_DIR/init.sh" "$PROJECT_DIR" "$PROJECT_NAME"
    echo ""
fi

cat > "$CONFIG_PATH" << CONFIGEOF
# Project Configuration

> 자동 생성됨 (auto-setup.sh, $(date '+%Y-%m-%d %H:%M'))
> Claude 프로젝트 메모리 + 파일 구조에서 감지한 설정입니다.
> 필요 시 수동으로 수정하세요.

## 기본 정보
- **프로젝트명:** $PROJECT_NAME
- **엔진/프레임워크:** $ENGINE
- **언어:** $LANGUAGE
- **플랫폼:** $(if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [ -n "$WINDIR" ]; then echo "Windows"; elif [[ "$OSTYPE" == "darwin"* ]]; then echo "macOS"; else echo "Linux"; fi)

## Git
- **Remote:** $GIT_REMOTE
- **Branch:** $GIT_BRANCH

## Runtime
- Loop interval: $LOOP_INTERVAL

## Orchestration
- Agent mode: $AGENT_MODE
- Review level: $REVIEW_LEVEL
- Dev direction: $DEV_DIRECTION

## 디렉토리 매핑

| 용도 | 경로 |
|------|------|
| 소스코드 | $SRC_REL |
| 에셋 (이미지) | $SPRITE_REL |
| 에셋 (오디오) | $AUDIO_REL |
| 에셋 (리소스) | $RESOURCE_REL |
| 테스트 | $TEST_REL |
| 씬/레벨 | $SCENE_REL |
| 도구 | $TOOL_REL |

## 에이전트 권한

### Supervisor (감독관) 수정 가능
- $SRC_REL (버그 수정/품질 개선)
- $SPRITE_REL
- $AUDIO_REL
- $RESOURCE_REL
- orchestration/logs/SUPERVISOR.md
- orchestration/BACKLOG_RESERVE.md
- orchestration/BOARD.md

### Developer (개발자) 수정 가능
- $SRC_REL
- $TEST_REL
- orchestration/BOARD.md (자기 태스크만)
- orchestration/logs/DEVELOPER.md

### Client (고객사) 수정 가능
- orchestration/reviews/ (생성만)
- orchestration/BOARD.md (In Review 결과 컬럼만)
- orchestration/logs/CLIENT.md

### Coordinator (소통 관리자) 수정 가능
- orchestration/BOARD.md
- orchestration/BACKLOG_RESERVE.md
- orchestration/specs/
- orchestration/logs/COORDINATOR.md
- orchestration/discussions/
- orchestration/prompts/COORDINATOR.txt

## 빌드/컴파일 에러 체크
- **에러 로그 경로:** $ERROR_LOG_PATH
- **에러 패턴:** "$ERROR_PATTERN"
- **경고 패턴:** "$WARNING_PATTERN"

## 에셋 규격

### 이미지
- 캐릭터 스프라이트: (프로젝트에 맞게 설정)
- 오브젝트 스프라이트: (프로젝트에 맞게 설정)
- UI 아이콘: (프로젝트에 맞게 설정)
- 아트 스타일: ${ART_STYLE:-(프로젝트에 맞게 설정)}

### 오디오
- BGM: (프로젝트에 맞게 설정)
- SFX: (프로젝트에 맞게 설정)

## 커밋/푸시 정책
- **컨벤션:** ${COMMIT_CONVENTION:-접두사: feat: / fix: / refactor: / test: / asset: / docs:}
- **커밋 단위:** 한 태스크 = 한 커밋 원칙
- **Push 정책:** $COMMIT_PUSH_POLICY
  - task: 태스크 완료 시마다 commit+push
  - review: In Review 제출 시에만 push (중간 작업은 commit만)
  - batch: 30분마다 변경사항 일괄 push
  - manual: 자동 push 안 함 (에이전트는 commit만, push는 사용자가 수동)

## 코드 아키텍처 규칙
- (프로젝트에 맞게 설정)

## 루프 간격
- Supervisor: $LOOP_INTERVAL
- Developer: $LOOP_INTERVAL
- Client: $LOOP_INTERVAL
- Coordinator: $LOOP_INTERVAL

## 알림
- **이메일 subject:** ${EMAIL_SUBJECT:-(프로젝트에 맞게 설정)}
- **메일 체크 주기:** 5분

## Claude 메모리에서 가져온 피드백 규칙
$(if [ -n "$FEEDBACK_ITEMS" ]; then echo "$FEEDBACK_ITEMS"; else echo "- (감지된 피드백 없음)"; fi)

## 리뷰 페르소나

### 페르소나 1
- **이름:** (설정 필요)
- **아이콘:** 🎮
- **역할:** 일반 사용자
- **배경:** (프로젝트 타겟 유저 기반으로 설정)
- **관점:** 직관성, 온보딩
- **말투:** 솔직하고 짧음
- **주로 잡는 문제:** 불친절한 UI, 설명 부족

### 페르소나 2
- **이름:** (설정 필요)
- **아이콘:** ⚔️
- **역할:** 전문 사용자
- **배경:** (도메인 경험 풍부)
- **관점:** 시스템 깊이, 밸런스
- **말투:** 분석적
- **주로 잡는 문제:** 시스템 깊이 부족, 밸런스

### 페르소나 3
- **이름:** (설정 필요)
- **아이콘:** 🎨
- **역할:** UX/UI 디자이너
- **배경:** UI 전문가
- **관점:** 시각적 일관성, 접근성
- **말투:** 전문적
- **주로 잡는 문제:** UI 일관성, 피드백 부재

### 페르소나 4
- **이름:** (설정 필요)
- **아이콘:** 🔍
- **역할:** QA 엔지니어
- **배경:** QA 경험
- **관점:** 안정성, 예외 처리
- **말투:** 체계적
- **주로 잡는 문제:** 크래시, 경계값 버그

## 검증 체계

### 검증 1: 엔진 검증
- **도구:** (MCP 플러그인 있으면 기재)
- **확인 항목:**
  - 씬/레벨 구조
  - 컴포넌트/노드 참조
  - 에셋 존재 여부
  - 빌드 세팅

### 검증 2: 코드 추적
- **확인 항목:**
  - 로직이 TASK 명세에 부합하는가
  - 기존 코드와 호환되는가
  - 아키텍처 패턴 준수
  - 테스트 커버리지

### 검증 3: UI 추적
- **확인 항목:**
  - 입력 → 이벤트 → UI 반응 체인
  - 패널/화면 열기/닫기
  - 데이터 바인딩 정확성

### 검증 4: 사용자 시나리오
- **시나리오 목록:**
  - (프로젝트에 맞게 설정)

## 기존 문서 (에이전트 필독)

> 오케스트레이션 시작 전 기존 작업물. 모든 에이전트는 첫 루프에서 아래 문서를 읽고 프로젝트 맥락을 파악해야 한다.
$(if [ -n "$DOCS_LIST" ]; then echo "$DOCS_LIST"; else echo "- (감지된 문서 없음)"; fi)

## 개발 방향/우선순위
- **방향:** $DEV_DIRECTION
- $DEV_PRIORITY_TEXT

## 에이전트 구성
- **모드:** $AGENT_MODE
  - full: 4개 전부 (Supervisor + Developer + Client + Coordinator)
  - lean: 2개 (Developer + Supervisor만)
  - solo: 1개 (Developer만, 모든 역할 통합)

## 리뷰 강도
- **레벨:** $REVIEW_LEVEL
  - strict: 모든 태스크 리뷰 필수
  - standard: 새 시스템만 리뷰, QA/수치조정은 자가진행
  - minimal: 리뷰 없음, 전부 자가진행
CONFIGEOF

echo "  ✅ project.config.md 생성 완료"
echo "     $CONFIG_PATH"

# ---------------------------------------------------------------------------
# Phase 3: 실행 안내
# ---------------------------------------------------------------------------

echo ""
echo "============================================"
echo " ✅ Auto-Setup 완료!"
echo "============================================"
echo ""
echo "  감지된 설정:"
echo "    프로젝트: $PROJECT_NAME"
echo "    엔진: $ENGINE"
echo "    언어: $LANGUAGE"
echo ""
echo "  다음 단계:"
echo "  1. project.config.md 확인 → $CONFIG_PATH"
echo "  2. 초기 태스크 등록 → $PROJECT_DIR/orchestration/BACKLOG_RESERVE.md"
echo "  3. 에이전트 실행 → orchestrate.bat 또는 launch.sh"
echo ""

# ---------------------------------------------------------------------------
# Phase 4: Agent runner scripts 생성
# ---------------------------------------------------------------------------
echo "📜 Agent runner scripts 생성..."

# 에이전트 모드에 따라 생성할 에이전트 결정
case "$AGENT_MODE" in
    solo) AGENTS_TO_CREATE=("DEVELOPER") ;;
    lean) AGENTS_TO_CREATE=("SUPERVISOR" "DEVELOPER") ;;
    *)    AGENTS_TO_CREATE=("SUPERVISOR" "DEVELOPER" "CLIENT" "COORDINATOR") ;;
esac

# solo 모드: Developer 프롬프트에 통합 역할 추가
if [ "$AGENT_MODE" = "solo" ] && ! grep -q "통합 역할 (solo 모드)" "$PROJECT_DIR/orchestration/prompts/DEVELOPER.txt" 2>/dev/null; then
    SOLO_APPEND="

## 통합 역할 (solo 모드)
이 세션은 solo 모드다. Developer + Supervisor + Client + Coordinator 역할을 혼자 수행한다.
- 구현 완료 후 자가 리뷰 수행 (project.config.md 검증 체계 참조)
- 에셋 필요 시 직접 생성 (project.config.md 에셋 규격 참조)
- BOARD 동기화, RESERVE 보충도 직접 처리
- 리뷰는 간소화: 코드 추적 + 플레이 시나리오 검증만 수행"
    echo "$SOLO_APPEND" >> "$PROJECT_DIR/orchestration/prompts/DEVELOPER.txt"
fi

for agent in "${AGENTS_TO_CREATE[@]}"; do
    runner="$PROJECT_DIR/orchestration/.run_${agent}.sh"
    cat > "$runner" << RUNEOF
#!/bin/bash
echo -ne "\\033]0;${agent}\\007"
cd "$PROJECT_DIR"
CONFIG_FILE="orchestration/project.config.md"
PROMPT_FILE="orchestration/prompts/${agent}.txt"

get_config_value() {
  local key="\$1"
  [ -f "\$CONFIG_FILE" ] || return 0
  grep -m1 "^-[[:space:]]*\${key}:" "\$CONFIG_FILE" | sed "s/^-[[:space:]]*\${key}:[[:space:]]*//"
}

interval_to_seconds() {
  local raw
  raw=\$(echo "\$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  case "\$raw" in
    *h) echo \$(( \${raw%h} * 3600 )) ;;
    *m) echo \$(( \${raw%m} * 60 )) ;;
    *s) echo \$(( \${raw%s} )) ;;
    *)  echo "\$raw" ;;
  esac
}

INTERVAL_RAW=\$(get_config_value "Loop interval")
[ -z "\$INTERVAL_RAW" ] && INTERVAL_RAW="2m"
INTERVAL_SECONDS=\$(interval_to_seconds "\$INTERVAL_RAW")
case "\$INTERVAL_SECONDS" in
  ''|*[!0-9]*) INTERVAL_SECONDS=120 ;;
esac
if [ "\$INTERVAL_SECONDS" -le 0 ] 2>/dev/null; then
  INTERVAL_SECONDS=120
fi

while true; do
  PROMPT=\$(cat "\$PROMPT_FILE")
  echo "=== [\$(date '+%H:%M:%S')] ${agent} loop start (interval: \$INTERVAL_RAW) ==="
  claude -p "\$PROMPT"
  echo ""
  sleep "\$INTERVAL_SECONDS"
done
RUNEOF
    chmod +x "$runner" 2>/dev/null
done
echo "  ✅ ${#AGENTS_TO_CREATE[@]}개 runner 생성: ${AGENTS_TO_CREATE[*]}"
echo ""
