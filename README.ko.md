# Claude Orchestration

여러 Claude CLI 에이전트가 파일 기반 비동기 통신으로 게임을 함께 개발하는 오케스트레이션 프레임워크.

bat 파일 하나로 전부 셋업됩니다. 에이전트들이 자율적으로 태스크를 가져가고, 기능을 구현하고, 코드를 리뷰하고, 보드를 관리합니다 — 전부 마크다운 파일을 통해 조율됩니다.

## 동작 흐름

```
orchestrate.bat  (더블클릭)
    |
    |-- 의존성 체크 (Git, Claude CLI)
    |-- 게임 프로젝트 폴더 선택 (모던 다이얼로그)
    |-- 엔진 자동 감지 (Unity / Godot / Unreal)
    |-- 대화형 셋업:
    |       Git 원격 저장소, 커밋 정책, 개발 방향,
    |       에이전트 모드, 리뷰 강도, 문서 스캔
    |-- 프로젝트 설정 + 에이전트 프롬프트 생성
    |-- 에이전트 실행 (각각 별도 터미널)
    v
  4개 에이전트가 병렬 실행, orchestration/ 통해 통신
```

## 에이전트

| 에이전트 | 역할 | 하는 일 |
|---------|------|--------|
| **Supervisor** (감독관) | 오케스트레이터 | 에셋 생성, 코드 품질 감사, 버그 수정, 태스크 관리 |
| **Developer** (개발자) | 실행자 | 게임 로직 구현, 테스트 작성, 커밋 |
| **Client** (고객사) | 검증자 | 멀티 페르소나 QA 리뷰, 품질 피드백 |
| **Coordinator** (소통 관리자) | 관리자 | 보드 동기화, 백로그 보충, 기획서 작성, 에이전트 감시 |

## 요구사항

| 프로그램 | 필수 | 설치 |
|---------|------|------|
| Git for Windows | O | https://git-scm.com/download/win |
| Node.js 18+ | O | https://nodejs.org |
| Claude CLI | O | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | 권장 | Windows 10/11 기본 탑재 |

## 빠른 시작

```bash
# 1. 클론
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. orchestrate.bat 더블클릭
#    - 게임 프로젝트 폴더 선택
#    - 엔진, 디렉토리, 기존 문서 자동 감지
#    - 셋업 질문 (방향, 에이전트 모드 등)
#    - 에이전트 실행

# 또는 커맨드라인에서:
orchestrate.bat "C:\path\to\your\game"
```

## 셋업 옵션

대화형 셋업에서 묻는 항목:

| 옵션 | 선택지 | 기본값 |
|------|--------|-------|
| **기존 문서** | 프로젝트 문서를 스캔해서 에이전트가 첫 루프에서 읽기 | Yes |
| **Git** | 저장소 초기화, 원격 URL 설정 | 자동 감지 |
| **커밋/푸시 정책** | task / review / batch / manual | task |
| **개발 방향** | stabilize / feature / polish / content / custom | feature |
| **에이전트 모드** | full (4개) / lean (2개) / solo (1개) | full |
| **리뷰 강도** | strict / standard / minimal | standard |

## 생성되는 구조

orchestrate.bat을 게임 프로젝트에서 실행하면 생성되는 것:

```
your-game-project/
  orchestration/
    project.config.md        # 전체 설정 (에이전트가 매 루프마다 읽음)
    BOARD.md                 # 칸반 보드 (Backlog > In Progress > In Review > Done)
    BACKLOG_RESERVE.md       # 개발자가 가져가는 예비 태스크 풀
    agents/                  # 에이전트 역할 정의
    prompts/                 # 에이전트 실행 프롬프트
    templates/               # 문서 템플릿 (태스크, 리뷰, 기획서 등)
    tasks/                   # 태스크 명세 (TASK-001.md, ...)
    reviews/                 # 리뷰 결과 (REVIEW-001-v1.md, ...)
    decisions/               # 감독관 판단 기록
    discussions/             # 에이전트 간 토론 (비동기 논의)
      concluded/             # 종료된 토론
    specs/                   # 기능 기획서 (SPEC-R-001.md, ...)
    logs/                    # 에이전트별 루프 로그
    .run_SUPERVISOR.sh       # 에이전트 실행 스크립트
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## 워크플로우

```
Backlog --> In Progress --> In Review --> Done
                ^               |
                '-- Rejected <--'
```

1. **Supervisor/Coordinator**가 BACKLOG_RESERVE에 태스크 등록
2. **Developer**가 최상단 태스크를 가져가 구현
3. 구현 완료 후 In Review로 이동
4. **Client**가 멀티 페르소나 리뷰 수행 (4명의 리뷰어 페르소나)
5. APPROVE -> Done / NEEDS_WORK -> Rejected -> Developer가 수정

## 에이전트 모드

### Full (4개)
전 에이전트 활성. 완전한 리뷰 사이클, 보드 관리, 에셋 생성.

### Lean (2개)
Developer + Supervisor만. 전담 리뷰어/관리자 없음. Supervisor가 리뷰와 보드 동기화 겸임.

### Solo (1개)
Developer 하나에 모든 역할 통합. 자가 리뷰, 자가 보드 관리. 소규모 프로젝트나 혼자 개발할 때 적합.

## 이어서 실행

이미 `orchestration/`이 있는 프로젝트에서 orchestrate.bat을 실행하면 기존 셋업을 감지합니다:

```
  Existing orchestration detected!
  Mode: full    Direction: stabilize

  1) Resume      - 에이전트만 실행 (셋업 스킵)
  2) Reconfigure - 셋업 재실행
  3) Cancel
```

## 기타 도구

| 파일 | 하는 일 |
|------|--------|
| `add-feature.bat` | 자연어로 기능 설명 -> 태스크 + 기획서 자동 생성 |
| `monitor.bat` | Unity/Godot 에디터 로그 감시, 런타임 에러 발견 시 버그 태스크 자동 생성 |

## 핵심 메커니즘

### FREEZE
BOARD.md 상단에 FREEZE 공지 추가 -> 전 에이전트 즉시 중단. 제거하면 재개.

### 토론
에이전트가 `discussions/`에 비동기 토론을 열 수 있음. 설계 결정, 우선순위 변경, 프로토콜 개선에 사용. 모든 에이전트가 자기 섹션에 응답하고, 감독관이 결론을 내림.

### 자가진행
Developer가 감독관을 기다리지 않고 태스크를 자동 진행 가능. QA/밸런스 태스크는 리뷰 없이 완료. 새 시스템 추가 태스크만 Client 리뷰 필수.

## 지원 엔진

| 엔진 | 자동 감지 | 에러 로그 | 샘플 설정 |
|------|----------|----------|----------|
| Unity | `.meta` 파일, `Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## 파일 구성

```
orchestrate.bat          # 메인 진입점 (셋업 + 실행)
add-feature.bat          # 텍스트로 기능 추가
monitor.bat              # 런타임 에러 모니터링
pick-folder.ps1          # 모던 폴더 선택 다이얼로그 (IFileDialog COM)
auto-setup.sh            # 엔진 감지, 설정 생성, 대화형 셋업
init.sh                  # 디렉토리 구조 생성
launch.sh                # 크로스 플랫폼 에이전트 런처
extract-features.sh      # 코드 분석 -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> 태스크 + 기획서
add-feature.sh           # 자연어 -> 태스크 + 기획서
monitor.sh               # 에디터 로그 감시 + 에러 리포트
project.config.md        # 빈 설정 템플릿
framework/
  agents/                # 에이전트 역할 정의 (4개)
  prompts/               # 에이전트 루프 프롬프트 (4개)
  templates/             # 문서 템플릿 (7개)
sample-config/           # Unity/Godot 설정 예시
```

## 라이선스

MIT
