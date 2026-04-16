# MVP Scope

## Must Have / 핵심 기능

- **4-에이전트 오케스트레이션 루프:** Supervisor + Developer + Client + Coordinator 가 각기 독립된 bash 프로세스(`.run_<ROLE>.sh`)로 돌며 BOARD.md 중심의 태스크 라이프사이클 (backlog → in_progress → in_review → rejected | done) 을 수행
- **단일 진입점:** `orchestrate.bat <타겟 프로젝트>` 한 번으로 타겟 프로젝트에 대한 초기화/재개 판단, 에이전트 런너 스크립트 생성, 4 에이전트 동시 기동까지 자동 수행
- **BOARD.md/FREEZE 프로토콜:** 파일 맨 위에 `FREEZE` 라인 한 줄 → 모든 에이전트가 드레인 후 안전 종료. 에이전트별 `.run_<ROLE>.sh` 프로세스만 죽이면 해당 에이전트 단독 정지
- **Auto-setup:** 타겟 프로젝트의 엔진/언어(Unity, Godot, Unreal, Python, 기타) 자동 감지 + `orchestration/project.config.md` 생성
- **Claude CLI 기반 에이전트 호출:** 각 에이전트 루프는 Claude CLI 를 headless (`claude --print` 파이프) 로 호출해 구조화된 출력을 받고 BOARD/커밋에 반영. 프롬프트 인젝션 방지를 위해 임시 파일 경유(`@tempfile`) 패턴 사용

## Out of Scope / 제외 항목

- **Not now:** 클라우드 배포, GUI 앱(Electron 포함), 원격 팀 협업 기능, 다수 동시 타겟 프로젝트 처리
- **Nice to have but excluded:** 웹 기반 대시보드, REST API, DB 영속화. 현재는 Markdown + git 이 전부
- **Excluded by design:** JavaScript/TypeScript/Python 기반 런타임 도입. 새 언어 런타임은 MVP 범위 밖

## Success Criteria / 성공 기준

- 운영자가 `orchestrate.bat <target>` 1회 실행한 뒤 4+ 시간 감독 없이 자동 루프가 돌며 BOARD 와 slot 브랜치에 실질 커밋(리뷰 완료된 태스크 1건 이상)이 누적되는 것
- FREEZE 주입 후 5분 이내 모든 에이전트가 drained 상태로 정지
- `auto-setup.sh` 실행 후 5개 이상의 주요 엔진/언어 타입에서 올바른 project.config.md 가 생성됨

## Validation / 검증 체크포인트

- 실제 타겟 프로젝트(다른 저장소)에 대해 orchestrate.bat 1회 가동 → 최소 3개 태스크가 Done 또는 APPROVE 상태에 도달
- FREEZE 주입 시 .run_*.sh 프로세스 0개로 수렴
