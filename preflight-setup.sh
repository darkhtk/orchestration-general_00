#!/bin/bash
# =============================================================================
# Claude Orchestration Preflight Scaffold
# =============================================================================
# Creates generic preparation docs inside the target project before orchestration
# setup runs. Existing files are never overwritten.
# =============================================================================

set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "[ERROR] Project not found: $PROJECT_DIR"
    exit 1
fi

DOCS_DIR="$PROJECT_DIR/docs"
TEMPLATE_DOCS_DIR="$TEMPLATE_DIR/docs/templates"

created=0
skipped=0

copy_if_missing() {
    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"
    if [ -f "$dst" ]; then
        echo "  [SKIP] ${dst#$PROJECT_DIR/}"
        skipped=$((skipped + 1))
    else
        cp "$src" "$dst"
        echo "  [CREATE] ${dst#$PROJECT_DIR/}"
        created=$((created + 1))
    fi
}

echo "============================================"
echo " Claude Orchestration Preflight"
echo "============================================"
echo ""
echo "  Project: $PROJECT_DIR"
echo ""

mkdir -p "$DOCS_DIR"

copy_if_missing "$TEMPLATE_DIR/PRE-FLIGHT-CHECKLIST.md" "$DOCS_DIR/PRE-FLIGHT-CHECKLIST.md"
copy_if_missing "$TEMPLATE_DOCS_DIR/current-state.template.md" "$DOCS_DIR/current-state.md"
copy_if_missing "$TEMPLATE_DOCS_DIR/dev-priorities.template.md" "$DOCS_DIR/dev-priorities.md"
copy_if_missing "$TEMPLATE_DOCS_DIR/testing.template.md" "$DOCS_DIR/testing.md"
copy_if_missing "$TEMPLATE_DOCS_DIR/architecture.template.md" "$DOCS_DIR/architecture.md"

if [ ! -f "$PROJECT_DIR/README.md" ]; then
    cat > "$PROJECT_DIR/README.md" <<'READEOF'
# Project Overview

## What This Project Is

- Project name:
- Genre / product type:
- Current goal:

## How To Run

- Main entry point:
- Required environment:

## Current Status

- What already works:
- What is in progress:
- Biggest risks:

## Important Docs

- `docs/current-state.md`
- `docs/dev-priorities.md`
- `docs/testing.md`
- `docs/architecture.md`
READEOF
    echo "  [CREATE] README.md"
    created=$((created + 1))
else
    echo "  [SKIP] README.md"
    skipped=$((skipped + 1))
fi

echo ""
echo "  Created: $created"
echo "  Skipped: $skipped"
echo ""
echo "Preflight scaffold complete."
