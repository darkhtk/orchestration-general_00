# Project Configuration — React Web Project 예시

> React 웹 프로젝트에서 실제 사용된 설정을 기반으로 한 샘플입니다.

## 기본 정보
- **프로젝트명:** My React App
- **엔진/프레임워크:** React 18.x
- **언어:** TypeScript
- **플랫폼:** Web (Browser)

## 디렉토리 매핑

| 용도 | 경로 |
|------|------|
| 소스코드 | src/components/, src/hooks/, src/utils/ |
| 에셋 (이미지) | src/assets/images/, public/images/ |
| 에셋 (오디오) | src/assets/audio/, public/audio/ |
| 에셋 (리소스) | src/assets/, public/assets/ |
| 테스트 | src/__tests__/, src/**/*.test.tsx |
| 페이지/라우팅 | src/pages/, src/routes/ |
| 스타일 | src/styles/, src/**/*.module.css |

## 에이전트 권한

### Supervisor (감독관) 수정 가능
- src/ (코드 직접 수정 OK)
- public/
- package.json, tsconfig.json
- orchestration/logs/SUPERVISOR.md
- orchestration/BACKLOG_RESERVE.md
- orchestration/BOARD.md

### Developer (개발자) 수정 가능
- src/components/, src/hooks/, src/utils/
- src/__tests__/
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
- **에러 로그 경로:** npm run build output, 브라우저 console
- **에러 패턴:** "Error:", "Failed to compile", "Module not found"
- **경고 패턴:** "Warning:", "Compiled with warnings"

## 에셋 규격

### 이미지
- 로고/아이콘: SVG 또는 PNG (다중 해상도)
- UI 이미지: WebP 또는 PNG
- 반응형 이미지: srcset 지원
- 최대 파일 크기: 2MB

### 미디어
- 오디오: MP3, WebM (브라우저 호환성)
- 비디오: MP4, WebM

## 커밋 컨벤션
- 접두사: feat: / fix: / refactor: / test: / style: / docs:
- 한 태스크 = 한 커밋 원칙

## 코드 아키텍처 규칙
- 함수형 컴포넌트 + React Hooks
- Context API 또는 상태 관리 라이브러리 (Redux, Zustand)
- 커스텀 훅으로 로직 분리
- PropTypes 또는 TypeScript 타입 정의
- CSS Modules 또는 Styled Components

## 루프 간격
- Supervisor: 2m
- Developer: 2m
- Client: 2m
- Coordinator: 2m

## 알림
- **이메일 subject:** [My React App]
- **메일 체크 주기:** 5분

## 리뷰 페르소나

### 페르소나 1
- **이름:** 민수
- **아이콘:** 🎮
- **역할:** 일반 사용자
- **배경:** 웹 서비스 일반 사용자, 모바일과 데스크톱 모두 사용
- **관점:** 직관성, 반응 속도, 접근성
- **말투:** 솔직하고 짧음. "이게 뭐야?", "로딩이 너무 느려"
- **주로 잡는 문제:** 불친절한 UI, 느린 로딩, 모바일 호환성

### 페르소나 2
- **이름:** 김개발
- **아이콘:** ⚔️
- **역할:** 프론트엔드 개발자
- **배경:** React 전문가, 성능 최적화와 코드 품질을 중시
- **관점:** 코드 구조, 성능, 최신 베스트 프랙티스
- **말투:** 분석적. "이 컴포넌트 구조가...", "렌더링 최적화가 필요해"
- **주로 잡는 문제:** 코드 중복, 성능 이슈, 아키텍처 문제

### 페르소나 3
- **이름:** 박디자인
- **아이콘:** 🎨
- **역할:** UX/UI 디자이너
- **배경:** 웹 디자인 전문가, 사용자 경험 중시
- **관점:** 시각적 일관성, 사용성, 접근성
- **말투:** 전문적이지만 명확. "시각적 계층이 부족해요", "인터랙션이 부자연스러워요"
- **주로 잡는 문제:** 디자인 일관성, 사용성 이슈, 접근성

### 페르소나 4
- **이름:** 이테스트
- **아이콘:** 🔍
- **역할:** QA 엔지니어
- **배경:** 웹 애플리케이션 테스팅 전문가
- **관점:** 안정성, 크로스 브라우저 호환성, 에러 처리
- **말투:** 체계적. "재현 절차: 1)... 2)... 3)...", "Chrome에서는 정상, Safari에서 버그"
- **주로 잡는 문제:** 브라우저 호환성, 에러 처리, 엣지 케이스

## 검증 체계

### 검증 1: 빌드 검증
- **도구:** npm run build, TypeScript 컴파일러
- **확인 항목:**
  - 빌드 성공 여부
  - TypeScript 타입 에러 없음
  - 번들 크기 최적화
  - 환경변수 및 설정 정상

### 검증 2: 코드 추적
- **확인 항목:**
  - React 컴포넌트 구조가 명세에 부합하는지
  - Hooks 사용법이 올바른지 (dependency array, cleanup 등)
  - 상태 관리가 적절한지
  - 테스트 커버리지가 충분한지
  - ESLint, Prettier 규칙 준수

### 검증 3: UI 검증
- **확인 항목:**
  - 사용자 인터랙션 (클릭, 입력) → 상태 변화 → UI 업데이트 체인
  - 반응형 디자인 (모바일, 태블릿, 데스크톱)
  - 로딩 상태 및 에러 상태 처리
  - 접근성 (ARIA, 키보드 네비게이션)
  - 브라우저 호환성 (Chrome, Firefox, Safari)

### 검증 4: 플레이 시나리오
- **시나리오 목록:**
  - 페이지 로드 → 초기 렌더링 → 인터랙션 → 결과 확인
  - 폼 입력 → 검증 → 제출 → 피드백 확인
  - 라우팅: 페이지 이동 → 브라우저 뒤로가기 → 상태 복원
  - 에러 상황: 네트워크 오류, 잘못된 입력, 권한 없음
  - 성능: 대용량 데이터 렌더링, 스크롤 성능

## 개발 방향/우선순위
- 성능 + 접근성 + 사용성 > 기능 > 디자인
- 기존 기능 안정화 > 신규 기능