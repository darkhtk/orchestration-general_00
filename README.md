# Claude Orchestration

**[한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [हिन्दी](README.hi.md) | [ไทย](README.th.md) | [Tiếng Việt](README.vi.md)**

Multiple Claude CLI agents collaborating on game development through file-based async communication.

One bat file sets up everything. Agents autonomously pick up tasks, implement features, review code, and manage the project board — all coordinated through markdown files.

## How It Works

```
orchestrate.bat  (double-click)
    |
    |-- Dependency check (Git, Claude CLI)
    |-- Select game project folder (modern dialog)
    |-- Auto-detect engine (Unity / Godot / Unreal)
    |-- Interactive setup:
    |       Git remote, commit policy, dev direction,
    |       agent mode, review level, doc scanning
    |-- Generate project config + agent prompts
    |-- Launch agents in separate terminals
    v
  4 agents running in parallel, communicating via orchestration/
```

## Framework Lifecycle

The framework works best as a repeatable lifecycle instead of a one-time setup:

1. `Preflight`
   Prepare the target project so agents can read it safely and make good decisions.
2. `Bootstrap`
   Run `orchestrate.bat` to generate orchestration files, config, prompts, and runners.
3. `Seed`
   Populate initial work through feature extraction or manual backlog creation.
4. `Operate`
   Let agents work continuously through the board and review loop.
5. `Control`
   Use `FREEZE`, `DRAIN_FOR_TEST`, reconfiguration, and monitoring to steer the system safely.
6. `Test`
   Drain to a safe point, freeze, test manually, then resume.

## Agents

| Agent | Role | What it does |
|-------|------|-------------|
| **Supervisor** | Orchestrator | Asset creation, code quality audits, bug fixes, task management |
| **Developer** | Builder | Implements game logic, writes tests, commits code |
| **Client** | Reviewer | Multi-persona QA reviews, quality feedback |
| **Coordinator** | Manager | Board sync, backlog replenishment, spec writing, agent monitoring |

## Requirements

| Program | Required | Install |
|---------|----------|---------|
| Git for Windows | Yes | https://git-scm.com/download/win |
| Node.js 18+ | Yes | https://nodejs.org |
| Claude CLI | Yes | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | Recommended | Pre-installed on Windows 10/11 |

## Quick Start

```bash
# 1. Clone
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. Double-click orchestrate.bat
#    - Picks your game project folder
#    - Auto-detects engine, directories, existing docs
#    - Asks setup questions (direction, agent mode, etc.)
#    - Launches agents

# Or from command line:
orchestrate.bat "C:\path\to\your\game"
```

## Recommended Entry Point

If you want the simplest operator workflow, start with:

- [orchestration-tools.bat](/C:/sourcetree/Ochestration_general/orchestration-tools.bat)

It acts as a hub for the common paths:

- setup or resume orchestration
- monitor orchestration status
- manage `FREEZE` / `DRAIN_FOR_TEST`
- prepare a test window
- watch runtime errors
- add a feature from text

Use the individual `.bat` files directly only when you already know the exact action you want.

## Setup Options

The interactive setup asks:

| Option | Choices | Default |
|--------|---------|---------|
| **Existing docs** | Scan project docs for agents to read on first loop | Yes |
| **Git** | Init repo, set remote URL | Auto-detect |
| **Commit/Push policy** | task / review / batch / manual | task |
| **Dev direction** | stabilize / feature / polish / content / custom | feature |
| **Agent mode** | full (4) / lean (2) / solo (1) | full |
| **Review level** | strict / standard / minimal | standard |
| **Loop interval** | Stored in `project.config.md` as `Loop interval` | 2m |

## Before You Start

This framework works best when the target project already has a small amount of structure and documentation.

Recommended minimum preparation:

- `README.md`
- `docs/current-state.md`
- `docs/dev-priorities.md`
- `docs/testing.md`

Use [PRE-FLIGHT-CHECKLIST.md](/C:/sourcetree/Ochestration_general/PRE-FLIGHT-CHECKLIST.md) before enabling orchestration on an existing project.

Reusable starter docs are included here:

- [current-state.template.md](/C:/sourcetree/Ochestration_general/docs/templates/current-state.template.md)
- [dev-priorities.template.md](/C:/sourcetree/Ochestration_general/docs/templates/dev-priorities.template.md)
- [testing.template.md](/C:/sourcetree/Ochestration_general/docs/templates/testing.template.md)
- [architecture.template.md](/C:/sourcetree/Ochestration_general/docs/templates/architecture.template.md)

When you run `orchestrate.bat`, the framework now performs an automatic preflight scaffold first:

- creates `docs/` if missing
- adds `docs/PRE-FLIGHT-CHECKLIST.md`
- adds `docs/current-state.md`, `docs/dev-priorities.md`, `docs/testing.md`, and `docs/architecture.md` if missing
- adds a minimal `README.md` only if the project does not already have one

Existing project files are never overwritten by this preflight step.

## What Gets Created

When you run orchestrate.bat on a game project, it creates:

```
your-game-project/
  orchestration/
    project.config.md        # All settings (agents read this every loop)
    BOARD.md                 # Kanban board (Backlog > In Progress > In Review > Done)
    BACKLOG_RESERVE.md       # Task pool for developers to pick from
    agents/                  # Agent role definitions
    prompts/                 # Agent launch prompts
    templates/               # Document templates (task, review, spec, etc.)
    tasks/                   # Task specs (TASK-001.md, ...)
    reviews/                 # Review results (REVIEW-001-v1.md, ...)
    decisions/               # Supervisor decisions
    discussions/             # Agent discussions (async debates)
      concluded/             # Resolved discussions
    specs/                   # Feature specs (SPEC-R-001.md, ...)
    logs/                    # Per-agent loop logs
    .run_SUPERVISOR.sh       # Agent runner scripts
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## Workflow

```
Backlog --> In Progress --> In Review --> Done
                ^               |
                '-- Rejected <--'
```

1. **Supervisor/Coordinator** create tasks in BACKLOG_RESERVE
2. **Developer** picks top task, implements it
3. Developer moves task to In Review
4. **Client** performs multi-persona review (4 reviewer personas)
5. APPROVE -> Done / NEEDS_WORK -> Rejected -> Developer fixes

## Agent Modes

### Full (4 agents)
All agents active. Full review cycle, board management, asset creation.

### Lean (2 agents)
Developer + Supervisor only. No dedicated reviewer or coordinator. Supervisor handles reviews and board sync.

### Solo (1 agent)
Single Developer agent with all roles merged. Self-review, self-managed board. Good for small projects or solo development.

## Resuming

If you run orchestrate.bat on a project that already has `orchestration/`, it detects the existing setup:

```
  Existing orchestration detected!
  Mode: full    Direction: stabilize

  1) Resume      - launch agents only (skip setup)
  2) Reconfigure - re-run setup
  3) Cancel
```

## Runtime Config

`project.config.md` now includes ASCII-safe orchestration keys so scripts can parse settings reliably on Windows:

```md
## Runtime
- Loop interval: 2m

## Orchestration
- Agent mode: full
- Review level: standard
- Dev direction: feature
```

Runner scripts read `Loop interval` from config and fall back to `2m` if the key is missing.

## Other Tools

| File | What it does |
|------|-------------|
| `add-feature.bat` | Describe a feature in plain text -> auto-generates tasks + specs |
| `monitor.bat` | Watch Unity/Godot editor logs for runtime errors, auto-create bug tasks |
| `monitor-orchestration.bat` | Live dashboard for board state, agent health, latest review, and git activity |
| `manage-orchestration.bat` | Add or remove FREEZE and DRAIN_FOR_TEST control flags, or open a quick monitor snapshot |
| `test-orchestration.bat` | Prepare a test window by draining current work, freezing at a safe point, or entering test mode immediately |
| `orchestration-tools.bat` | Single entry hub for setup, monitoring, control, testing, runtime monitoring, and feature intake |

## Key Mechanisms

### FREEZE
Add a FREEZE notice to top of BOARD.md -> all agents stop immediately. Remove it to resume.

### DRAIN_FOR_TEST
Add a DRAIN_FOR_TEST notice to let agents finish the current task at a safe checkpoint, update BOARD/logs, and stop picking new work. This is the recommended way to prepare a temporary manual test window.

## Operations Workflow

Recommended operational flow for changing direction, patching orchestration, or preparing a manual test window:

1. Use `manage-orchestration.bat` to set `FREEZE` or `DRAIN_FOR_TEST`.
2. Watch progress with `monitor-orchestration.bat` until the system reaches a safe point.
3. Apply your patch or run `orchestrate.bat` -> `Reconfigure`.
4. Review `project.config.md`, `BOARD.md`, and `BACKLOG_RESERVE.md`.
5. Use `manage-orchestration.bat` to remove the control flag and resume.

For short manual test windows, prefer:

1. `test-orchestration.bat` -> `Enter drain for test`
2. `test-orchestration.bat` -> `Watch until safe test point`
3. Run your test while `FREEZE` is active
4. `manage-orchestration.bat` -> `Unfreeze`

### Discussions
Agents can open async debates in `discussions/`. Used for design decisions, priority changes, protocol improvements. All agents respond in their section, then supervisor concludes.

### Self-progression
Developer can auto-advance through tasks without waiting for supervisor. QA/balance tasks skip review entirely. New system tasks always require Client review.

## Supported Engines

| Engine | Auto-detect | Error log | Sample config |
|--------|------------|-----------|---------------|
| Unity | `.meta` files, `Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## File Overview

```
orchestrate.bat          # Main entry point (setup + launch)
orchestration-tools.bat  # Recommended operator hub for day-to-day use
add-feature.bat          # Add feature by text description
monitor.bat              # Runtime error monitoring
pick-folder.ps1          # Modern folder picker dialog (IFileDialog COM)
auto-setup.sh            # Engine detection, config generation, interactive setup
init.sh                  # Directory structure creation
launch.sh                # Cross-platform agent launcher
extract-features.sh      # Analyze codebase -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> tasks + specs
add-feature.sh           # Natural language -> tasks + specs
preflight-setup.sh       # Generic preflight doc scaffold for target projects
monitor.sh               # Editor.log watcher + error reporter
project.config.md        # Blank config template
docs/templates/          # Reusable preflight documentation templates
framework/
  agents/                # Agent role definitions (4 files)
  prompts/               # Agent loop prompts (4 files)
  templates/             # Document templates (7 files)
sample-config/           # Example configs for Unity/Godot
```

## License

MIT
