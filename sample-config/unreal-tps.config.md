# Project Configuration — Unreal Engine 5 TPS 예시

> Third-Person Shooter 프로젝트에서 사용하기 위한 샘플입니다.

## 기본 정보
- **프로젝트명:** UnrealTPS
- **엔진/프레임워크:** Unreal Engine 5.4
- **언어:** C++ + Blueprint
- **플랫폼:** Windows (PC)

## 디렉토리 매핑

| 용도 | 경로 |
|------|------|
| 소스코드 | Source/UnrealTPS/ |
| 에셋 (메시) | Content/Meshes/ |
| 에셋 (텍스처) | Content/Textures/ |
| 에셋 (오디오) | Content/Audio/ |
| 에셋 (블루프린트) | Content/Blueprints/ |
| 테스트 | Source/UnrealTPS/Tests/ |
| 레벨/맵 | Content/Maps/ |
| 도구 | Tools/ |
| 빌드 출력 | Binaries/ |

## 에이전트 권한

### Supervisor (감독관) 수정 가능
- Source/UnrealTPS/ (C++ 코드 직접 수정 OK)
- Content/Blueprints/
- Content/Meshes/, Textures/, Audio/
- Tools/
- orchestration/logs/SUPERVISOR.md
- orchestration/BACKLOG_RESERVE.md
- orchestration/BOARD.md

### Developer (개발자) 수정 가능
- Source/UnrealTPS/
- Content/Blueprints/
- Source/UnrealTPS/Tests/
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

## 빌드/에러 체크

### 빌드 명령어
```
# Development 빌드
UnrealBuildTool.exe UnrealTPS Win64 Development -Project="PROJECT_PATH/UnrealTPS.uproject"

# Shipping 빌드
UnrealBuildTool.exe UnrealTPS Win64 Shipping -Project="PROJECT_PATH/UnrealTPS.uproject"

# 에디터 빌드
UnrealBuildTool.exe UnrealTPSEditor Win64 Development -Project="PROJECT_PATH/UnrealTPS.uproject"
```

### 에러 로그 경로
- **주 로그:** `Saved/Logs/UnrealTPS.log`
- **에디터 로그:** `Saved/Logs/UnrealEditor.log`
- **빌드 로그:** `Saved/Logs/UnrealBuildTool.log`

### 체크 항목
- [ ] C++ 컴파일 에러 (MSVC)
- [ ] Blueprint 컴파일 에러
- [ ] 링크 에러
- [ ] 애셋 임포트 에러
- [ ] 게임 런타임 크래시
- [ ] 메모리 릭 체크

## 에셋 규격

### 텍스처
- **해상도:** 2048x2048 이하 (Power of 2)
- **포맷:** BC7 (일반), BC5 (노말맵), BC1 (Diffuse)
- **Mipmap:** 자동 생성
- **최적화:** True

### 메시 (Static Mesh)
- **삼각면 수:** LOD0 10,000개 이하
- **UV 매핑:** 겹치지 않는 라이트맵 UV
- **Collision:** 단순화된 Collision Mesh

### 오디오
- **샘플률:** 48,000Hz
- **비트 깊이:** 16bit
- **채널:** Stereo
- **압축:** OGG Vorbis

### Blueprint
- **명명 규칙:** BP_ClassName
- **부모 클래스:** 명확한 상속 구조
- **성능:** Tick 최소화, Event-driven 선호

## 커밋/푸시 정책

### 커밋 단위
- 1개 기능/버그픽스 = 1개 커밋
- C++과 Blueprint 변경사항을 함께 커밋

### 메시지 컨벤션
```
feat: 플레이어 점프 능력 추가
fix: 총알 충돌 감지 버그 수정
refactor: PlayerController 클래스 리팩토링
content: 새로운 무기 에셋 추가
```

### 푸시 타이밍
- 기능 완성 후 즉시 푸시
- 빌드 에러가 없는 상태에서만 푸시

### 브랜치 전략
- main: 안정 버전
- feature/*: 기능 개발
- bugfix/*: 버그 수정

## 코드 아키텍처

### C++ 클래스 구조
```
GameModeBase ← TPSGameMode
Character ← TPSCharacter
PlayerController ← TPSPlayerController
GameInstanceSubsystem ← InventorySubsystem
ActorComponent ← WeaponComponent
```

### Blueprint 구조
- **UI:** Content/Blueprints/UI/
- **게임플레이:** Content/Blueprints/Gameplay/
- **에셋:** Content/Blueprints/Assets/

### 코딩 컨벤션
- **C++:** Unreal Coding Standards 준수
- **변수:** bIsActive, PlayerHealth, WeaponArray
- **함수:** GetPlayerHealth(), SetWeaponDamage()
- **클래스:** ATPS로 시작 (ATPSCharacter)

## 루프 간격
- **Supervisor:** 120초
- **Developer:** 120초
- **Client:** 180초
- **Coordinator:** 150초

## 리뷰 페르소나

### 1. 게임 디자이너 (Alex)
- **관점:** 게임플레이와 밸런스
- **체크 포인트:** 플레이어 경험, 게임 루프, 난이도 곡선
- **전문 분야:** 레벨 디자인, 캐릭터 능력, 무기 밸런싱

### 2. 테크니컬 아티스트 (Maya)
- **관점:** 성능과 최적화
- **체크 포인트:** 렌더링 성능, 메모리 사용량, 에셋 최적화
- **전문 분야:** 셰이더, 라이팅, LOD 시스템

### 3. QA 엔지니어 (Jordan)
- **관점:** 버그와 안정성
- **체크 포인트:** 크래시, 예외 상황, 엣지 케이스
- **전문 분야:** 테스트 자동화, 에러 재현, 시스템 테스트

### 4. UI/UX 디자이너 (Sam)
- **관점:** 사용자 인터페이스와 경험
- **체크 포인트:** UI 반응성, 접근성, 직관성
- **전문 분야:** 메뉴 시스템, HUD 디자인, 사용자 흐름

## 검증 체계

### 빌드 검증 (Tier 1)
- [ ] C++ 코드 컴파일
- [ ] Blueprint 컴파일
- [ ] 게임 실행 가능
- [ ] 치명적 에러 없음

### 코드 검증 (Tier 2)
- [ ] Coding Standards 준수
- [ ] 메모리 누수 없음
- [ ] 성능 회귀 없음
- [ ] 유닛 테스트 통과

### 기능 검증 (Tier 3)
- [ ] 기능 요구사항 충족
- [ ] 게임플레이 테스트 통과
- [ ] UI/UX 요구사항 충족
- [ ] 성능 목표 달성 (60 FPS)

### 통합 검증 (Tier 4)
- [ ] 전체 시스템 동작
- [ ] 다양한 하드웨어에서 테스트
- [ ] 장시간 플레이 테스트
- [ ] 멀티플레이 기능 (해당 시)

## 개발 방향

### 우선순위
1. **핵심 게임플레이:** 이동, 조준, 사격
2. **무기 시스템:** 다양한 무기와 업그레이드
3. **적 AI:** 지능적인 적 행동 패턴
4. **레벨 디자인:** 전략적 맵 구조

### 품질 기준
- **성능:** 평균 60 FPS 유지
- **안정성:** 크래시 없이 30분 이상 플레이 가능
- **사용성:** 튜토리얼 없이도 직관적 조작

### 기술 부채 관리
- 매주 코드 리팩토링 시간 할당
- 정기적인 성능 프로파일링
- 에셋 최적화 및 정리