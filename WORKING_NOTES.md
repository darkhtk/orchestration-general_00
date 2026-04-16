# Working Notes

## 2026-04-16 — PROJECT_BRIEF 시리즈 초기 작성

### 배경

같은 날 오전/오후 AB(A→B) 및 BA(B→A) 캐너리 라이브 테스트에서 B 의 에이전트(A 저장소를 개발하는 역할) 가 자체 판단으로 `src/core/WebDetector.js` (406줄 JavaScript), `orchestration/web_project_detector.py`, `test-projects/vue-sample/*` 등을 A 저장소에 쌓는 현상이 확인됨. 원인: A 에 PROJECT_BRIEF.md / MVP_SCOPE.md / CURRENT_GOAL.md 가 존재하지 않아 B 의 bootstrap 이 `briefing: degraded (empty, score=0.00)` 로 판단, 에이전트가 tech stack 정보 없이 "웹 프로젝트 자동 감지" 태스크(S-085)를 JS/Python 으로 해석.

### 대응

이 브리프 3종 + 본 WORKING_NOTES 작성. 특히 PROJECT_BRIEF.md 의 "Anti-stack" 섹션에 JS/TS/Python 금지를 명시. 다음 BA 캐너리에서 실제로 이 브리프가 읽혀 B 에이전트 판단이 bash/batch/PowerShell 로 수렴하는지 검증 예정.

### 열린 결정

- **PROJECT_BRIEF.md 를 kg-A-initial 태그에 포함시킬지 여부**: 현재 kg-A-initial 은 `cfd34b1 snapshot: A framework state before A/B pipeline initialization` 에 고정. 이 커밋은 브리프 도입 이전. 슬롯 브랜치는 kg-A-initial 에서 생성되므로 브리프가 자동 반영되지 않음. 해결 옵션 (둘 다 수동 운영자 결정):
  1. 브리프 커밋 후 `git tag -f kg-A-initial HEAD` 로 태그 강제 이동
  2. 브리프만을 내용으로 하는 별도 커밋을 cherry-pick 형태로 슬롯 브랜치 생성 직후 자동 주입하는 로직을 자동화 파이프라인(run-slot)에 추가
- **assets/ 디렉토리 정책**: 오늘 BA 슬롯에서 `assets/A-001-project-setup-flow.md`, `A-002-tui-dashboard-wireframe.md`, `A-003-project-readme-assets.md` 등 mermaid/와이어프레임 design 문서가 생성됨. 설계 자료는 가치 있으나 위치가 A 저장소의 기존 구조와 맞지 않음. docs/ 하위로 이동할지, assets/ 그대로 둘지 정책 결정 필요

### 다음 루프에 전달할 컨텍스트

- kg-A-initial 이 구식(2026-04-13) 이라 새 브리프/수정이 슬롯에 반영되지 않는다는 점 기억
- Auto-Setup 이 타겟 프로젝트의 project.config.md 를 덮어쓰는 로직이 있으므로 (orchestrate.bat L118-127), 새 브리프 파일은 project.config.md 가 아닌 레포 루트에 두어 덮어쓰기를 피함
- Client 의 리뷰는 Bash 허용 후 정상 작동 확인됨 (오늘 `718b656`, `4475d21`). Coordinator 역시 (`13de671`, `fe5ec50` B 측 수정 후). 다음 루프에 대한 권한 관련 걱정은 없음
