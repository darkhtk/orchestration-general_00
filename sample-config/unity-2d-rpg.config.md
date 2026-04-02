# Project Configuration — Unity 2D RPG 예시

> Magic Workshop RPG 프로젝트에서 실제 사용된 설정을 기반으로 한 샘플입니다.

## 기본 정보
- **프로젝트명:** Magic Workshop RPG
- **엔진/프레임워크:** Unity 6000.3.9f1
- **언어:** C#
- **플랫폼:** Windows

## 디렉토리 매핑

| 용도 | 경로 |
|------|------|
| 소스코드 | testGame/Assets/Scripts/ |
| 에셋 (이미지) | testGame/Assets/Sprites/ |
| 에셋 (오디오) | testGame/Assets/Audio/ |
| 에셋 (리소스) | testGame/Assets/Resources/ |
| 테스트 | testGame/Assets/Tests/EditMode/ |
| 씬/레벨 | testGame/Assets/Scenes/ |
| 도구 | tools/*.py |

## 에이전트 권한

### Supervisor (감독관) 수정 가능
- testGame/Assets/Scripts/ (코드 직접 수정 OK)
- testGame/Assets/Sprites/, Audio/, Resources/
- tools/*.py
- orchestration/logs/SUPERVISOR.md
- orchestration/BACKLOG_RESERVE.md
- orchestration/BOARD.md

### Developer (개발자) 수정 가능
- testGame/Assets/Scripts/
- testGame/Assets/Tests/EditMode/
- orchestration/BOARD.md (자기 태스크만)
- orchestration/logs/DEVELOPER.md

### Client (고객사) 수정 가능
- orchestration/reviews/ (생성만)
- orchestration/BOARD.md (In Review 결과 컬럼만)
- orchestration/logs/CLIENT.md

### Coordinator (소통 관리자) 수정 가능
- orchestration/BOARD.md
- orchestration/BACKLOG_RESERVE.md
- orchestration/specs/
- orchestration/logs/COORDINATOR.md
- orchestration/discussions/
- orchestration/prompts/COORDINATOR.txt

## 빌드/컴파일 에러 체크
- **에러 로그 경로:** %LOCALAPPDATA%\Unity\Editor\Editor.log
- **에러 패턴:** "error CS"
- **경고 패턴:** "warning CS"

## 에셋 규격

### 이미지
- 캐릭터 스프라이트: 16x32 PPU=16
- 오브젝트 스프라이트: 32x32 PPU=16
- UI 아이콘: 64x64
- 아트 스타일: 스타듀밸리 픽셀아트

### 오디오
- BGM: 22050Hz 16bit mono 30초+
- SFX: 22050Hz 16bit mono

## 커밋 컨벤션
- 접두사: feat: / fix: / refactor: / test: / asset: / docs:
- 한 태스크 = 한 커밋 원칙

## 코드 아키텍처 규칙
- ScriptableObject 기반 데이터, MonoBehaviour 기반 로직
- 싱글턴 패턴 (GameManager, AudioManager 등)
- 이벤트 기반 시스템 간 통신
- FindAnyObjectByType fallback
- UI → SceneGenerator EnsureUI() 포함

## 루프 간격
- Supervisor: 2m
- Developer: 2m
- Client: 2m
- Coordinator: 2m

## 알림
- **이메일 subject:** [Magic Workshop]
- **메일 체크 주기:** 5분

## 리뷰 페르소나

### 페르소나 1
- **이름:** 민지
- **아이콘:** 🎮
- **역할:** 캐주얼 게이머
- **배경:** 모바일 게임 위주, 하루 30분 플레이, 복잡한 시스템 싫어함
- **관점:** 직관성, 첫인상, 온보딩, "이게 뭔지 3초 안에 알겠는가?"
- **말투:** 솔직하고 짧음. "이거 뭐야?", "어디 눌러야 해?"
- **주로 잡는 문제:** 불친절한 UI, 설명 부족, 진입장벽

### 페르소나 2
- **이름:** 현우
- **아이콘:** ⚔️
- **역할:** 하드코어 전략 게이머
- **배경:** 경영 시뮬/전략 게임 1000시간+, 시스템 최적화를 즐김
- **관점:** 시스템 깊이, 밸런스, 상호작용, 리플레이 가치
- **말투:** 분석적. "이 수치 밸런스가...", "최적해가 고정되면 재미없다"
- **주로 잡는 문제:** 얕은 시스템, 밸런스 붕괴, 의미없는 선택지

### 페르소나 3
- **이름:** 서연
- **아이콘:** 🎨
- **역할:** UX/UI 디자이너
- **배경:** 게임 UI 전문가, 인터랙션 디자인 5년 경력
- **관점:** 시각적 일관성, 정보 계층, 접근성, 반응 피드백
- **말투:** 전문적이지만 명확. "시각적 계층이 부족해요", "피드백 루프가 끊겨요"
- **주로 잡는 문제:** 일관성 깨짐, 정보 과부하, 피드백 부재

### 페르소나 4
- **이름:** 정민
- **아이콘:** 🔍
- **역할:** QA 엔지니어
- **배경:** 게임 QA 3년, 엣지 케이스 발굴 전문
- **관점:** 안정성, 예외 처리, 재현 가능성, 성능
- **말투:** 체계적. "재현 절차: 1)... 2)... 3)...", "예상: X, 실제: Y"
- **주로 잡는 문제:** 크래시, 예외 미처리, 경계값 버그, 메모리 누수

## 검증 체계

### 검증 1: 엔진 검증
- **도구:** MCP-Unity (com.ivanmurzak.unity.mcp v0.61.0)
- **확인 항목:**
  - 씬 계층구조 (Hierarchy): 새 오브젝트가 올바른 위치에 존재하는지
  - 컴포넌트 참조: 스크립트가 올바른 GameObject에 붙어있는지
  - 프리팹 상태: 프리팹 내 참조가 깨지지 않았는지
  - 에셋 존재: 스프라이트/SO/AudioClip 등이 실제 생성되었는지
  - 빌드 세팅: 씬이 Build Settings에 등록되었는지

### 검증 2: 코드 추적
- **확인 항목:**
  - 변경된 코드의 로직이 TASK 명세·수용 기준에 부합하는지
  - 기존 코드와의 호환성 (호출 체인이 끊기지 않는지)
  - 새 메서드/클래스가 기존 아키텍처 패턴 준수하는지
  - 테스트가 추가/수정되었고 수용 기준을 커버하는지
  - 하드코딩, 매직넘버, 누락된 null 체크 등 코드 품질

### 검증 3: UI 추적
- **확인 항목:**
  - 사용자 입력(클릭/키보드) → 이벤트 → UI 반응 체인이 완성되는지
  - 패널 열기/닫기 (ESC, X 버튼) 플로우
  - UIManager 연동: 패널 표시/숨김/일시정지가 올바른지
  - 데이터 바인딩: UI에 표시되는 수치가 실제 데이터와 일치하는지
  - 기존 UI와의 충돌 (패널 중첩, 이벤트 가로채기 등)

### 검증 4: 플레이 시나리오
- **시나리오 목록:**
  - NPC 클릭 → 지시 → 행동 완료 → 결과 확인 (인벤토리/로그)
  - UI 열기 → 조작 → 닫기 → 이동 가능 확인
  - 씬 전환 → 복귀 → 모든 것 정상 확인 (NPC, UI, 데이터)
  - 같은 행동 3회 반복 → 상태 누적 정상 확인
  - AI 응답 시나리오: 유효한 값 / 무효한 값 / 타임아웃

## 개발 방향/우선순위
- 폴리시 + QoL + 안정성 > 게임플레이 > 콘텐츠
- 기존 기능 개선 > 신규 기능
