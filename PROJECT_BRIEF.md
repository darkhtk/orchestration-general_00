# Project Brief

## One-line Summary

이 프로젝트는 **Bash/Batch + PowerShell + Claude CLI** 기반의 Windows/크로스플랫폼 멀티-에이전트 오케스트레이션 프레임워크다. Developer, Supervisor, Client, Coordinator 4개 에이전트를 각기 독립 프로세스로 띄워 BOARD.md 중심의 태스크 보드를 통해 협력시켜, 한 번의 `orchestrate.bat` 실행으로 장기 자동 개발 루프를 돌린다.

## Primary User / 대상 사용자

- **주 사용자:** Windows 11 환경에서 Git Bash + PowerShell + Claude CLI(`claude` 바이너리)를 이미 쓰고 있는 개발자/운영자
- **운영 시나리오:** 하나의 타겟 프로젝트에 대해 며칠~몇 주 단위로 감독 없이 (or 감독 최소화) 기능 개발을 맡기고 싶은 1인 개발자 또는 소규모 팀
- **기대 아웃풋:** 주기적으로 BOARD.md + slot 브랜치에 커밋이 누적되며, REVIEW 파일로 리뷰 히스토리가 남는 자율 개발 사이클

## Tech Stack / 기술 스택 — **이 프레임워크 자체의 구현 기술**

- **쉘 스크립트(bash):** `orchestrate.bat` 에서 호출되는 `.run_<ROLE>.sh` 에이전트 런너, `auto-setup.sh`, `init.sh`, `launch.sh`, `monitor.sh`, `seed-backlog.sh`, `add-feature.sh`, `extract-features.sh`, `conflict-recovery.sh`
- **Windows Batch(.bat):** `orchestrate.bat` (진입점), `manage-orchestration.bat`, `monitor-orchestration.bat`, `monitor.bat`, `add-feature.bat`
- **PowerShell(.ps1):** `manage-orchestration.ps1`, `monitor-orchestration.ps1`, `monitor-orchestration-optimized.ps1`, `pick-folder.ps1`, `common-orchestration-functions.ps1`
- **Claude CLI:** 각 에이전트는 `claude --print @<prompt_file>` 형태로 호출. Max 구독 인증(`~/.claude/projects` jsonl 스토어) 사용
- **Markdown 파일 중심 상태:** BOARD.md, BACKLOG_RESERVE.md, orchestration/project.config.md, orchestration/logs/<ROLE>.md, orchestration/reviews/REVIEW-*.md, specs/SPEC-*.md

## Anti-stack — **이 프로젝트에 추가하면 안 되는 기술**

- ❌ JavaScript / TypeScript 런타임 (Node.js). `src/core/WebDetector.js` 같은 파일은 A 의 실행 환경(bash+cmd)에서 돌지 않음
- ❌ Python 런타임. `*.py` 모듈은 A 의 런타임과 통합되지 않음
- ❌ Vue/React/Angular 샘플 프로젝트 디렉토리. 이 저장소는 웹 앱이 아님
- ❌ Node 기반 빌드 도구(Vite, webpack 등), package.json 추가

**웹 프로젝트 감지/지원 태스크(S-085, S-086 등)가 백로그에 들어와도 구현은 bash 또는 PowerShell로 하고, JS/Python 코드 파일을 새로 추가하지 말 것.**

## Core Experience

- 운영자가 `orchestrate.bat <타겟 프로젝트 경로>` 한 번 실행 → 4개 에이전트가 각자의 쉘에서 기동 → 1인 개발 사이클 자동 진행
- BOARD.md 에 FREEZE 문자열 주입 → 전체 에이전트 안전하게 드레인 후 정지

## Success Criteria

- 새 로직이 추가되면 기존 `.sh`/`.bat`/`.ps1` 패밀리 안에서 일관되게 구현되어야 함
- 모든 변경은 기존 BOARD.md / BACKLOG_RESERVE.md 상태 흐름을 존중해야 함
- 새 언어 런타임 의존성을 도입하지 않는 변경만 받아들임

## Notes

- 이 저장소는 반대편 프레임워크 `C:\sourcetree\Orchestration_general_02` (Node/TS `@anthropic-ai/claude-agent-sdk` 기반, B) 와 짝을 이뤄 자동화 파이프라인에서 상호 개발 사이클을 돈다
- 파이프라인 자동화 코드는 별도 저장소(`C:\sourcetree\orchestration_framework_dev_automation`)에 존재
