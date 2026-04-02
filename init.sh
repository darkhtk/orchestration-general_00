#!/bin/bash
# Claude Orchestration Template - 프로젝트 초기화 스크립트
# 사용법: bash init.sh [프로젝트 디렉토리] [프로젝트명]
#
# 예시:
#   bash init.sh .                          # 현재 디렉토리에 셋업
#   bash init.sh /path/to/my-game "My RPG"  # 지정 디렉토리에 셋업

set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_NAME="${2:-My Game Project}"

# 절대 경로로 변환
if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

echo "============================================"
echo " Claude Orchestration Template Initializer"
echo "============================================"
echo ""
echo "  Template:  $TEMPLATE_DIR"
echo "  Project:   $PROJECT_DIR"
echo "  Name:      $PROJECT_NAME"
echo ""

# 이미 orchestration/ 존재 시 확인
if [ -d "$PROJECT_DIR/orchestration" ]; then
    echo "⚠️  orchestration/ 디렉토리가 이미 존재합니다."
    read -p "  덮어쓰시겠습니까? (y/N): " confirm || true
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "취소됨."
        exit 0
    fi
fi

echo "📁 디렉토리 구조 생성..."
mkdir -p "$PROJECT_DIR/orchestration"/{agents,tasks,reviews,decisions,discussions/concluded,logs,prompts,specs}

echo "📄 에이전트 역할 정의 복사..."
cp "$TEMPLATE_DIR/framework/agents/"*.md "$PROJECT_DIR/orchestration/agents/"

echo "📝 프롬프트 복사..."
cp "$TEMPLATE_DIR/framework/prompts/"*.txt "$PROJECT_DIR/orchestration/prompts/"

echo "📋 템플릿 복사..."
mkdir -p "$PROJECT_DIR/orchestration/templates"
cp "$TEMPLATE_DIR/framework/templates/"*.md "$PROJECT_DIR/orchestration/templates/"

echo "⚙️  project.config.md 생성..."
if [ ! -f "$PROJECT_DIR/orchestration/project.config.md" ]; then
    cp "$TEMPLATE_DIR/project.config.md" "$PROJECT_DIR/orchestration/project.config.md"
    # 프로젝트명 치환 (macOS/Linux 이식성)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/(예: My RPG Game)/$PROJECT_NAME/" "$PROJECT_DIR/orchestration/project.config.md"
    else
        sed -i "s/(예: My RPG Game)/$PROJECT_NAME/" "$PROJECT_DIR/orchestration/project.config.md"
    fi
else
    echo "  → project.config.md 이미 존재, 스킵."
fi

echo "📊 BOARD.md 생성..."
if [ ! -f "$PROJECT_DIR/orchestration/BOARD.md" ]; then
    sed "s/(project.config.md \"프로젝트명\" 참조)/$PROJECT_NAME/" \
        "$TEMPLATE_DIR/framework/templates/BOARD-TEMPLATE.md" \
        > "$PROJECT_DIR/orchestration/BOARD.md"
    # 날짜 삽입
    TODAY=$(date +%Y-%m-%d)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/YYYY-MM-DD/$TODAY/" "$PROJECT_DIR/orchestration/BOARD.md"
    else
        sed -i "s/YYYY-MM-DD/$TODAY/" "$PROJECT_DIR/orchestration/BOARD.md"
    fi
else
    echo "  → BOARD.md 이미 존재, 스킵."
fi

echo "📦 BACKLOG_RESERVE.md 생성..."
if [ ! -f "$PROJECT_DIR/orchestration/BACKLOG_RESERVE.md" ]; then
    cp "$TEMPLATE_DIR/framework/templates/BACKLOG-TEMPLATE.md" \
       "$PROJECT_DIR/orchestration/BACKLOG_RESERVE.md"
else
    echo "  → BACKLOG_RESERVE.md 이미 존재, 스킵."
fi

echo "📝 빈 로그 파일 생성..."
for agent in SUPERVISOR DEVELOPER CLIENT COORDINATOR; do
    if [ ! -f "$PROJECT_DIR/orchestration/logs/$agent.md" ]; then
        echo "# $agent Loop Log" > "$PROJECT_DIR/orchestration/logs/$agent.md"
        echo "(아직 실행되지 않음)" >> "$PROJECT_DIR/orchestration/logs/$agent.md"
    fi
done

echo ""
echo "============================================"
echo " ✅ 초기화 완료!"
echo "============================================"
echo ""
echo "다음 단계:"
echo ""
echo "  1. project.config.md 수정:"
echo "     $PROJECT_DIR/orchestration/project.config.md"
echo ""
echo "  2. 초기 태스크 등록:"
echo "     $PROJECT_DIR/orchestration/BACKLOG_RESERVE.md"
echo ""
echo "  3. 에이전트 실행 (4개 터미널):"
echo '     claude "$(cat orchestration/prompts/SUPERVISOR.txt)"'
echo '     claude "$(cat orchestration/prompts/DEVELOPER.txt)"'
echo '     claude "$(cat orchestration/prompts/CLIENT.txt)"'
echo '     claude "$(cat orchestration/prompts/COORDINATOR.txt)"'
echo ""
