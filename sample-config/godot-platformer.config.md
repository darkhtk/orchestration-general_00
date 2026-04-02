# Project Configuration — Godot 4 플랫포머 예시

> 다른 엔진/장르에 적용하는 샘플입니다.

## 기본 정보
- **프로젝트명:** Pixel Jumper
- **엔진/프레임워크:** Godot 4.3
- **언어:** GDScript
- **플랫폼:** Windows / Web

## 디렉토리 매핑

| 용도 | 경로 |
|------|------|
| 소스코드 | src/scripts/ |
| 에셋 (이미지) | assets/sprites/ |
| 에셋 (오디오) | assets/audio/ |
| 에셋 (리소스) | assets/resources/ |
| 테스트 | tests/ |
| 씬/레벨 | scenes/ |
| 도구 | tools/ |

## 에이전트 권한

### Supervisor (감독관) 수정 가능
- src/scripts/ (버그 수정/품질 개선)
- assets/
- tools/
- orchestration/logs/SUPERVISOR.md
- orchestration/BACKLOG_RESERVE.md
- orchestration/BOARD.md

### Developer (개발자) 수정 가능
- src/scripts/
- scenes/
- tests/
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
- **에러 로그 경로:** (Godot 에디터 Output 패널 — 수동 확인 또는 godot --headless --check-only)
- **에러 패턴:** "ERROR" 또는 "Parse Error"
- **경고 패턴:** "WARNING"

## 에셋 규격

### 이미지
- 캐릭터 스프라이트: 32x32
- 타일셋: 16x16
- UI 아이콘: 48x48
- 아트 스타일: 레트로 픽셀아트 (NES 팔레트)

### 오디오
- BGM: 44100Hz 16bit stereo, 루프 가능
- SFX: 44100Hz 16bit mono

## 커밋 컨벤션
- 접두사: feat: / fix: / refactor: / test: / asset: / level:
- 한 태스크 = 한 커밋 원칙

## 코드 아키텍처 규칙
- Autoload 싱글턴 (GameManager, AudioManager)
- Signal 기반 시스템 간 통신
- Resource 기반 데이터 (.tres)
- 씬 상속 패턴 활용

## 루프 간격
- Supervisor: 2m
- Developer: 2m
- Client: 2m
- Coordinator: 3m

## 알림
- **이메일 subject:** [Pixel Jumper]
- **메일 체크 주기:** 10분

## 리뷰 페르소나

### 페르소나 1
- **이름:** 하늘
- **아이콘:** 🎮
- **역할:** 캐주얼 플랫포머 유저
- **배경:** 마리오/셀레스트 경험, 어려운 게임 싫어함
- **관점:** 조작감, 점프 감각, 난이도 곡선
- **말투:** 감성적. "이 점프 짜릿하다!", "여기서 왜 죽는지 모르겠어"
- **주로 잡는 문제:** 부정확한 히트박스, 불공정한 배치, 조작 지연

### 페르소나 2
- **이름:** 도윤
- **아이콘:** 🏆
- **역할:** 스피드러너
- **배경:** 플랫포머 스피드런 500시간+, 프레임 단위 최적화
- **관점:** 속도감, 움직임 옵션, 스킵 가능성, 일관성
- **말투:** 기술적. "코요테 타임 몇 프레임?", "이 벽점프 판정이..."
- **주로 잡는 문제:** 입력 지연, 불일관 물리, 속도 캡

### 페르소나 3
- **이름:** 수아
- **아이콘:** 🎨
- **역할:** 인디 게임 비주얼 평론가
- **배경:** 인디 게임 500종+ 플레이, 비주얼 감각 뛰어남
- **관점:** 비주얼 코히런스, 색감, 애니메이션 퀄리티
- **말투:** 비평적. "이 배경과 캐릭터 팔레트가 안 어울려요"
- **주로 잡는 문제:** 스타일 불일치, 애니메이션 끊김, 가독성

### 페르소나 4
- **이름:** 재현
- **아이콘:** 🔍
- **역할:** QA 테스터
- **배경:** 인디 게임 QA 경험, 벽 뚫기/무한 점프 탐구
- **관점:** 물리 엣지케이스, 충돌 버그, 세이브 안정성
- **말투:** 재현 중심. "벽 모서리에서 대시하면 뚫림"
- **주로 잡는 문제:** 콜리전 버그, 상태 꼬임, 세이브 손상

## 검증 체계

### 검증 1: 엔진 검증
- **도구:** 없음 (씬 파일 .tscn 직접 읽기)
- **확인 항목:**
  - 씬 트리 구조가 올바른지
  - 노드 참조 (NodePath)가 깨지지 않았는지
  - 리소스 (.tres) 파일이 존재하는지
  - Export 설정 확인

### 검증 2: 코드 추적
- **확인 항목:**
  - GDScript 로직이 TASK 명세에 부합하는지
  - Signal 연결이 올바른지
  - Autoload 의존성 확인
  - 테스트 커버리지

### 검증 3: UI 추적
- **확인 항목:**
  - Control 노드 포커스 체인
  - 테마/스타일 일관성
  - 입력 이벤트 전파 순서
  - 반응형 레이아웃

### 검증 4: 플레이 시나리오
- **시나리오 목록:**
  - 레벨 시작 → 클리어 → 다음 레벨 전환
  - 낙사 → 리스폰 → 상태 정상
  - 모든 움직임 조합 (점프+대시, 벽점프+대시 등)
  - 세이브/로드 → 진행도 유지

## 개발 방향/우선순위
- 조작감 + 레벨 디자인 > 비주얼 > 콘텐츠 양
- 버그 수정 > 신규 기능
