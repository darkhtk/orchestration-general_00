# Pre-Flight Checklist

Use this checklist before applying Claude Orchestration to an existing project.

The goal is not to document everything. The goal is to give the agents enough context to work safely, consistently, and with the right priorities.

## 1. Repository Safety

- [ ] Git is initialized
- [ ] A remote is connected
- [ ] `.gitignore` excludes generated files, caches, logs, and build artifacts
- [ ] The project can be restored to a known-good state if a bad patch lands

## 2. Project Readability

- [ ] There is a root `README.md`
- [ ] The project has a clear entry point or starting scene
- [ ] Core directories are recognizable: code, assets, scenes, tests, tools
- [ ] The current project status is summarized in one document

## 3. Execution and Testing

- [ ] There is a documented way to run the project
- [ ] There is a documented way to build the project
- [ ] There is a documented way to run tests, if tests exist
- [ ] There is a short manual smoke-test checklist

## 4. Priorities and Constraints

- [ ] The current development direction is written down: `stabilize`, `feature`, `polish`, or `content`
- [ ] The top 3-5 active priorities are listed
- [ ] Risky or protected areas are listed
- [ ] "Do not change" rules are listed where needed

## 5. Architecture Context

- [ ] The main systems are listed
- [ ] Data flow or ownership is described at a high level
- [ ] Save/load or migration rules are documented if relevant
- [ ] UI flow is documented if UI work is expected

## 6. Recommended Minimum Docs

Before enabling orchestration, try to prepare at least these files:

- `README.md`
- `docs/current-state.md`
- `docs/dev-priorities.md`
- `docs/testing.md`

Recommended additions for larger projects:

- `docs/architecture.md`
- `docs/known-issues.md`
- `docs/ui-flow.md`
- `docs/asset-guidelines.md`
- `docs/save-format.md`

## 7. Good Enough Standard

These documents do not need to be complete.

They do need to be:

- current enough to trust
- short enough to scan quickly
- specific enough to guide decisions

If you only have time to write three files, write:

1. `README.md`
2. `docs/current-state.md`
3. `docs/dev-priorities.md`
