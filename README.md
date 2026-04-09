# Claude Orchestration

여러 AI 에이전트가 파일 기반 비동기 협업으로 프로젝트를 운영하도록 붙이는 오케스트레이션 프레임워크입니다.

이 레포는 특정 프로젝트의 작업 산출물을 보관하는 곳이 아니라, 제네릭한 템플릿, 스크립트, 운영 규칙을 제공하는 프레임워크 레포입니다.

## 권장 시작점

가장 쉬운 사용 방법은 다음 파일부터 시작하는 것입니다.

- `orchestration-tools.bat`

이 허브에서 아래 작업으로 들어갈 수 있습니다.

- 오케스트레이션 초기 설정 또는 재개
- 진행 상태 모니터링
- `FREEZE` / `DRAIN_FOR_TEST` 제어
- 테스트 윈도우 준비
- 런타임 에러 모니터링
- 자연어 기반 기능 추가

## 프레임워크 라이프사이클

이 프레임워크는 일회성 설정 도구가 아니라 반복 운영용입니다.

1. `Preflight`
   대상 프로젝트에 최소 문서와 구조를 준비합니다.
2. `Bootstrap`
   `orchestrate.bat`로 오케스트레이션 파일과 runner를 생성합니다.
3. `Seed`
   초기 backlog를 생성하거나 feature 추출로 일감을 채웁니다.
4. `Operate`
   에이전트가 지속 루프로 작업, 리뷰, 보드 운영을 수행합니다.
5. `Control`
   `FREEZE`, `DRAIN_FOR_TEST`, `Reconfigure`, 모니터링으로 흐름을 제어합니다.
6. `Test`
   안전 지점까지 drain한 뒤 멈추고 테스트하고 다시 재개합니다.

## 주요 도구

| 파일 | 용도 |
|------|------|
| `orchestration-tools.bat` | 일상 운영용 단일 진입 허브 |
| `orchestrate.bat` | 대상 프로젝트에 오케스트레이션을 설정하고 에이전트를 실행 |
| `monitor-orchestration.bat` | 보드 상태, 에이전트 헬스, 최신 리뷰, Git 상태 모니터링 |
| `manage-orchestration.bat` | `FREEZE`, `DRAIN_FOR_TEST`, 해제 같은 운영 제어 |
| `test-orchestration.bat` | 테스트 윈도우 진입, safe point 대기, 테스트 모드 진입 |
| `monitor.bat` | Unity/Godot 런타임 로그 모니터링 |
| `add-feature.bat` | 자연어 기능 요청을 backlog + spec 초안으로 변환 |

## 빠른 시작

```bash
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00
orchestration-tools.bat
```

직접 실행할 수도 있습니다.

```bash
orchestrate.bat "C:\path\to\your\project"
```

## 실행 흐름

`orchestrate.bat`는 다음 순서로 동작합니다.

1. 의존성 확인
2. 대상 프로젝트 선택
3. 자동 preflight scaffold 실행
4. 프로젝트 자동 감지
5. 설정 질문
6. `orchestration/` 구조 생성
7. runner 생성
8. 선택적으로 feature 추출 / backlog seed
9. 에이전트 실행

## 자동 Preflight

`orchestrate.bat` 실행 시 먼저 `preflight-setup.sh`가 돌면서 대상 프로젝트에 기본 문서를 자동 생성합니다.

생성 대상:

- `docs/PRE-FLIGHT-CHECKLIST.md`
- `docs/current-state.md`
- `docs/dev-priorities.md`
- `docs/testing.md`
- `docs/architecture.md`
- 최소 `README.md` (프로젝트에 README가 없을 때만)

기존 파일은 덮어쓰지 않습니다.

## 대상 프로젝트에 생성되는 구조

프레임워크를 프로젝트에 적용하면 대상 프로젝트 안에 아래 구조가 만들어집니다.

```text
your-project/
  orchestration/
    project.config.md
    BOARD.md
    BACKLOG_RESERVE.md
    agents/
    prompts/
    templates/
    tasks/
    reviews/
    decisions/
    discussions/
      concluded/
    specs/
    logs/
    .run_SUPERVISOR.sh
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

중요:

- 실제 기능 spec은 대상 프로젝트의 `orchestration/specs/`에 생성됩니다.
- 프레임워크 레포 루트에는 실제 프로젝트용 `specs/`를 두지 않습니다.
- 프레임워크 레포에는 공용 템플릿과 운영 규칙만 남깁니다.

## 에이전트 역할

| 에이전트 | 역할 |
|---------|------|
| `Supervisor` | 품질, 태스크 정의, 자산/코드 개선, 결정 관리 |
| `Developer` | 구현, 테스트, 커밋 |
| `Client` | 리뷰, 멀티 페르소나 QA |
| `Coordinator` | 보드 동기화, reserve 보충, spec 작성, 운영 감시 |

## 운영 제어 규칙

### FREEZE

`BOARD.md` 상단에 `FREEZE`가 있으면 에이전트는 즉시 새 작업을 멈춥니다.

권장 사용:

- 방향 전환
- 스크립트 패치
- 긴급 점검
- 테스트 직전 완전 정지

### DRAIN_FOR_TEST

`DRAIN_FOR_TEST`는 즉시 중단이 아니라 현재 작업을 안전 지점까지 정리한 뒤 새 작업을 집지 않도록 하는 상태입니다.

권장 사용:

- 수동 테스트 전
- 현재 작업 상태를 보존한 채 잠깐 검증하고 싶을 때

## 권장 운영 흐름

### 방향 전환 / 설정 변경

1. `manage-orchestration.bat`로 `FREEZE`
2. 패치 적용
3. `orchestrate.bat`에서 `Reconfigure`
4. `BOARD.md`, `BACKLOG_RESERVE.md`, `project.config.md` 점검
5. `manage-orchestration.bat`로 해제

### 테스트 윈도우

1. `test-orchestration.bat`에서 `Enter drain for test`
2. `Watch until safe test point`
3. 자동 또는 수동 `FREEZE`
4. 테스트 수행
5. `manage-orchestration.bat`에서 해제

## 사전 준비 문서

적용 전에 아래 문서가 있으면 품질이 크게 좋아집니다.

- `PRE-FLIGHT-CHECKLIST.md`
- `docs/templates/current-state.template.md`
- `docs/templates/dev-priorities.template.md`
- `docs/templates/testing.template.md`
- `docs/templates/architecture.template.md`

이 템플릿들은 프레임워크 레포 안에 있고, 대상 프로젝트 쪽으로 scaffold됩니다.

## 저장소에 남겨야 하는 것과 남기지 말아야 하는 것

프레임워크 레포에 남겨야 하는 것:

- 공용 스크립트
- 공용 템플릿
- 샘플 설정
- 운영 규칙 문서

프레임워크 레포에 남기지 말아야 하는 것:

- 특정 프로젝트 backlog
- 특정 프로젝트 feature 목록
- 특정 프로젝트 spec 묶음
- 특정 작업 산출물 문서

## 요구 사항

- Git for Windows
- Node.js 18+
- Claude CLI
- Windows Terminal 권장

## 현재 레포 구조

```text
framework/                공용 에이전트 역할, 프롬프트, 템플릿
sample-config/            엔진별 샘플 설정
docs/templates/           preflight용 문서 템플릿
orchestrate.bat           설정 + 실행
orchestration-tools.bat   운영 허브
manage-orchestration.*    운영 제어
monitor-orchestration.*   운영 상태 모니터링
test-orchestration.*      테스트 윈도우 제어
preflight-setup.sh        대상 프로젝트 문서 scaffold
```

## 라이선스

MIT
