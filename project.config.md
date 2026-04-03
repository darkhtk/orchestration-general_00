# Project Configuration

> 이 파일만 프로젝트에 맞게 수정하세요. 모든 에이전트 프롬프트가 이 파일을 참조합니다.

## 기본 정보
- **프로젝트명:** (예: My RPG Game)
- **엔진/프레임워크:** (예: Unity 6000.3.9f1 / Unreal 5.4 / Godot 4.3)
- **언어:** (예: C# / GDScript / C++ / Blueprint)
- **플랫폼:** (예: Windows / Mobile / Web)

## Git
- **Remote:** (예: https://github.com/user/repo.git)
- **Branch:** (예: master)

## Runtime
- Loop interval: 2m

## Orchestration
- Agent mode: full
- Review level: standard
- Dev direction: feature

## 디렉토리 매핑

| 용도 | 경로 |
|------|------|
| 소스코드 | (예: src/Scripts/) |
| 에셋 (이미지) | (예: assets/Sprites/) |
| 에셋 (오디오) | (예: assets/Audio/) |
| 에셋 (리소스) | (예: assets/Resources/) |
| 테스트 | (예: tests/EditMode/) |
| 씬/레벨 | (예: assets/Scenes/) |
| 도구/스크립트 | (예: tools/) |

## 에이전트 권한

### Supervisor (감독관) 수정 가능
- (에셋 경로)
- (소스코드 경로 — 버그 수정/품질 개선 한정)
- orchestration/logs/SUPERVISOR.md
- orchestration/BACKLOG_RESERVE.md
- orchestration/BOARD.md

### Developer (개발자) 수정 가능
- (소스코드 경로)
- (테스트 경로)
- orchestration/BOARD.md (자기 태스크만: In Progress → In Review)
- orchestration/logs/DEVELOPER.md

### Client (고객사) 수정 가능
- orchestration/reviews/ (생성만)
- orchestration/BOARD.md (In Review 결과 컬럼만)
- orchestration/logs/CLIENT.md

### Coordinator (소통 관리자) 수정 가능
- orchestration/BOARD.md (동기화, 프로토콜 공지)
- orchestration/BACKLOG_RESERVE.md (보충)
- orchestration/specs/ (기획서)
- orchestration/logs/COORDINATOR.md
- orchestration/discussions/ (토론 생성)
- orchestration/prompts/COORDINATOR.txt (자기 자신만)

## 빌드/컴파일 에러 체크
- **에러 로그 경로:** (예: %LOCALAPPDATA%\Unity\Editor\Editor.log)
- **에러 패턴:** (예: "error CS")
- **경고 패턴:** (예: "warning CS")

## 에셋 규격

### 이미지
- 캐릭터 스프라이트: (예: 16x32 PPU=16)
- 오브젝트 스프라이트: (예: 32x32 PPU=16)
- UI 아이콘: (예: 64x64)
- 아트 스타일: (예: 스타듀밸리 픽셀아트)

### 오디오
- BGM: (예: 22050Hz 16bit mono 30초+)
- SFX: (예: 22050Hz 16bit mono)

## 커밋/푸시 정책
- **컨벤션:** 접두사: feat: / fix: / refactor: / test: / asset: / docs:
- **커밋 단위:** 한 태스크 = 한 커밋 원칙 (필요시 분할)
- **Push 정책:** task
  - task: 태스크 완료 시마다 commit+push
  - review: In Review 제출 시에만 push (중간 작업은 commit만)
  - batch: 30분마다 변경사항 일괄 push
  - manual: 자동 push 안 함 (에이전트는 commit만, push는 사용자가 수동)

## 코드 아키텍처 규칙
- (예: ScriptableObject 기반 데이터, MonoBehaviour 기반 로직)
- (예: 싱글턴 패턴 사용처 제한)
- (예: 이벤트 기반 시스템 간 통신)

## 루프 간격
- Supervisor: 2m
- Developer: 2m
- Client: 2m
- Coordinator: 2m

## 알림
- **이메일 subject:** (예: [My RPG Game])
- **메일 체크 주기:** 5분

## 리뷰 페르소나

> 최소 3명, 최대 9명. 프로젝트 성격에 맞게 조정.

### 페르소나 1
- **이름:** (예: 민지)
- **아이콘:** (예: 🎮)
- **역할:** (예: 캐주얼 게이머)
- **배경:** (예: 모바일 게임 위주, 하루 30분 플레이)
- **관점:** (예: 직관성, 온보딩, "3초 안에 알겠는가?")
- **말투:** (예: 솔직하고 짧음)
- **주로 잡는 문제:** (예: 불친절한 UI, 설명 부족)

### 페르소나 2
- **이름:** (예: 현우)
- **아이콘:** (예: ⚔️)
- **역할:** (예: 하드코어 전략 게이머)
- **배경:** (예: 경영 시뮬/전략 게임 1000시간+)
- **관점:** (예: 시스템 깊이, 밸런스, 리플레이 가치)
- **말투:** (예: 분석적)
- **주로 잡는 문제:** (예: 얕은 시스템, 밸런스 붕괴)

### 페르소나 3
- **이름:** (예: 서연)
- **아이콘:** (예: 🎨)
- **역할:** (예: UX/UI 디자이너)
- **배경:** (예: 게임 UI 전문가)
- **관점:** (예: 시각적 일관성, 정보 계층, 접근성)
- **말투:** (예: 전문적이지만 명확)
- **주로 잡는 문제:** (예: 일관성 깨짐, 피드백 부재)

### 페르소나 4
- **이름:** (예: 정민)
- **아이콘:** (예: 🔍)
- **역할:** (예: QA 엔지니어)
- **배경:** (예: 게임 QA 3년)
- **관점:** (예: 안정성, 예외 처리, 성능)
- **말투:** (예: 체계적, 재현 절차 기반)
- **주로 잡는 문제:** (예: 크래시, 경계값 버그)

## 검증 체계

### 검증 1: 엔진 검증
- **도구:** (예: MCP-Unity / 없음)
- **확인 항목:**
  - 씬/레벨 계층구조
  - 컴포넌트/노드 참조
  - 프리팹/씬 상태
  - 에셋 존재 여부
  - 빌드 세팅

### 검증 2: 코드 추적
- **확인 항목:**
  - 로직이 TASK 명세에 부합하는가
  - 기존 코드와 호환되는가
  - 아키텍처 패턴을 준수하는가
  - 테스트가 수용 기준을 커버하는가
  - 코드 품질 (하드코딩, 매직넘버, null 체크)

### 검증 3: UI 추적
- **확인 항목:**
  - 입력 → 이벤트 → UI 반응 체인
  - 패널/화면 열기/닫기 플로우
  - UI 매니저 연동
  - 데이터 바인딩 정확성
  - 기존 UI와의 충돌

### 검증 4: 플레이 시나리오
- **시나리오 목록:**
  - (예: NPC 상호작용 → 결과 확인)
  - (예: UI 열기 → 조작 → 닫기 → 이동 복귀)
  - (예: 씬 전환 → 복귀 → 정상 확인)
  - (예: 같은 행동 반복 → 상태 누적 확인)

## 개발 방향/우선순위
- (예: 폴리시 + QoL + 안정성 > 게임플레이 > 콘텐츠)
- (예: 기존 기능 개선 > 신규 기능)
