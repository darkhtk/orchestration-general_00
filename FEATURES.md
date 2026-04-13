# Claude Orchestration - Feature List

## Core Systems

### 에이전트 아키텍처 (4-Agent System)
- **Status:** Done
- **Description:** 4개의 전문 AI 에이전트가 파일 기반 비동기 협업으로 프로젝트를 자율 운영하는 멀티 에이전트 시스템
- **Sub-features:**
  - [x] Supervisor 에이전트 — 태스크 정의, 리뷰 판단, 에셋 생성, 코드 품질 개선
  - [x] Developer 에이전트 — 코드 구현, 테스트, 커밋, 자가진행
  - [x] Client 에이전트 — 멀티 페르소나 리뷰, 4계층 검증
  - [x] Coordinator 에이전트 — 보드 동기화, RESERVE 보충, 기획서 선제 작성, 에이전트 상태 감시
  - [x] 에이전트별 역할 정의 문서 (framework/agents/*.md)
  - [x] 에이전트별 실행 프롬프트 (framework/prompts/*.txt)
  - [x] 에이전트별 권한 분리 (수정 가능/금지 경로 명시)
  - [x] 첫 루프 초기화 프로토콜 (.initialized_* 마커 파일)
  - [x] 에이전트별 로그 롤링 (30루프 이력 유지)

### BOARD 상태 머신 (Task Lifecycle)
- **Status:** Done
- **Description:** BOARD.md 기반 태스크 생명주기 관리 — Backlog → In Progress → In Review → Done/Rejected
- **Sub-features:**
  - [x] 로드맵 테이블 (번호, 태스크명, 우선순위, 상태 이모지, 비고)
  - [x] 5개 활성 섹션: ❌ Rejected / 🔧 In Progress / 👀 In Review / ✅ Done / 📋 Backlog
  - [x] 수정 권한 매트릭스 (에이전트별 이동 가능 범위 명시)
  - [x] 우선순위 체계: P0(빌드 불가/크래시) ~ P3(Nice-to-have)
  - [x] Rejected 즉시 처리 규칙 (새 태스크보다 리워크 우선)
  - [x] ⛔ BLOCKED 삽입 프로토콜 (P0 Rejected + Developer 다른 작업 중)
  - [x] 로드맵 ↔ 활성 섹션 자동 동기화 (Coordinator 담당)
  - [x] Done 섹션 10건 초과 시 아카이브 (old/BOARD-DONE-ARCHIVE.md)
  - [x] BOARD 템플릿 (framework/templates/BOARD-TEMPLATE.md)

### BACKLOG RESERVE (예비 태스크 풀)
- **Status:** Done
- **Description:** BOARD Backlog가 0건일 때 Developer가 자가 배정하는 상시 개선 태스크 풀
- **Sub-features:**
  - [x] 위에서부터 순서대로 선택 규칙
  - [x] 한 번에 1건만 가져가기 규칙
  - [x] 🎨 태그 태스크 — Supervisor 전용 (Developer 스킵)
  - [x] ~~취소선~~ 규칙 — Done 확정 시에만 (In Progress/In Review 금지)
  - [x] Coordinator 자동 보충 (10건 이하 → 20건+ 대량 보충)
  - [x] Supervisor 보충 (10건 이하 시 🎨 포함 보충)
  - [x] BACKLOG 템플릿 (framework/templates/BACKLOG-TEMPLATE.md)
  - [x] specs/SPEC-XXX.md 연동 (존재 시 기획서 따라 구현)

### 제어 플래그 시스템 (Control Flags)
- **Status:** Done
- **Description:** BOARD.md 상단에 삽입하여 모든 에이전트의 동작을 즉시 제어하는 플래그 시스템
- **Sub-features:**
  - [x] 🛑 FREEZE — 즉시 정지, 코드/에셋/오케스트레이션 변경 금지
  - [x] 🛑 DRAIN_FOR_TEST — 현재 태스크 안전 지점까지 완료 후 정지, 새 작업 금지
  - [x] 모든 에이전트 프롬프트에 Step 0 FREEZE 확인 내장
  - [x] manage-orchestration 스크립트로 플래그 설정/해제
  - [x] test-orchestration 스크립트로 테스트 윈도우 진입

### Git 통합 (Git Integration)
- **Status:** Done
- **Description:** 에이전트 작업 결과의 Git 커밋/푸시 정책을 프로젝트 설정으로 제어
- **Sub-features:**
  - [x] 커밋 컨벤션: feat: / fix: / refactor: / test: / asset: / docs:
  - [x] 한 태스크 = 한 커밋 원칙
  - [x] Push 정책 4종: task / review / batch / manual
  - [x] 에이전트 간 시작 간격 3초 (동시 git 충돌 방지)
  - [x] amend 금지 규칙 (리워크 시 새 커밋)

### 프로젝트 설정 (Project Configuration)
- **Status:** Done
- **Description:** project.config.md 단일 파일로 프로젝트 전체 설정을 관리 — 모든 에이전트가 매 루프마다 참조
- **Sub-features:**
  - [x] 기본 정보 (프로젝트명, 엔진, 언어, 플랫폼)
  - [x] Git 설정 (Remote, Branch)
  - [x] 디렉토리 매핑 (소스코드, 에셋, 테스트, 씬, 도구 경로)
  - [x] 에이전트별 권한 설정 (수정 가능 경로)
  - [x] 빌드/컴파일 에러 체크 (로그 경로, 에러/경고 패턴)
  - [x] 에셋 규격 (이미지 해상도/PPU, 오디오 포맷)
  - [x] 커밋/푸시 정책
  - [x] 코드 아키텍처 규칙
  - [x] 루프 간격 설정 (에이전트별)
  - [x] 이메일 알림 설정 (subject, 체크 주기)
  - [x] 리뷰 페르소나 정의 (3~9명)
  - [x] 검증 체계 정의 (4계층)
  - [x] 개발 방향/우선순위
  - [x] 샘플 설정: Unity 2D RPG (sample-config/unity-2d-rpg.config.md)
  - [x] 샘플 설정: Godot Platformer (sample-config/godot-platformer.config.md)
  - [ ] 샘플 설정: Unreal Engine 프로젝트
  - [ ] 샘플 설정: 웹 프로젝트 (React/Next.js 등)
  - [ ] 샘플 설정: 순수 TypeScript/Node.js 프로젝트

### 파일 기반 비동기 통신 (File-Based Async)
- **Status:** Done
- **Description:** 실시간 API 없이 Git 커밋을 "이벤트"로, Markdown 파일을 "메시지"로 사용하는 비동기 통신 체계
- **Sub-features:**
  - [x] BOARD.md — 상태 대시보드
  - [x] orchestration/tasks/ — 태스크 명세 (Supervisor 작성)
  - [x] orchestration/reviews/ — 리뷰 보고서 (Client 작성)
  - [x] orchestration/decisions/ — 판단 기록 (Supervisor 작성)
  - [x] orchestration/specs/ — 기획서 (Coordinator 작성)
  - [x] orchestration/discussions/ — 에이전트 간 토론
  - [x] orchestration/discussions/concluded/ — 합의 완료 토론 아카이브
  - [x] orchestration/logs/ — 에이전트별 루프 로그
  - [x] 로그 롤링: Supervisor/Developer/Coordinator 30루프, Client 최신만

---

## Orchestration Features

### Supervisor 워크플로우
- **Status:** Done
- **Description:** 프로젝트 전체를 조율하는 오케스트레이터 — 태스크 정의, 리뷰 판단, 에셋/코드 품질 직접 관리
- **Sub-features:**
  - [x] 🎨 에셋 태스크 최우선 실행 (RESERVE에서 🎨 태그 확인)
  - [x] 5단계 자동 행동 순환 (에셋 선제생성 → 코드 감사 → 에러 점검 → 성능 최적화 → UX 개선)
  - [x] 런타임 모니터 리포트 확인 (MONITOR.md CRITICAL 즉시 수정)
  - [x] 아키텍처 체크리스트 (코드 수정 전 GitQueue/EventBus/인코딩 점검)
  - [x] Developer 동시 수정 방지 (In Progress 파일 확인 후 다른 파일로 이동)
  - [x] RESERVE 보충 (10건 이하 → 20건+ 대량 보충, 🎨 포함)
  - [x] 토론 응답 ([감독관 응답] 섹션 확인 및 작성)
  - [x] 커밋 전 테스트 실행 검증

### Developer 워크플로우
- **Status:** Done
- **Description:** 감독관이 배정한 태스크를 구현하는 실행자 — 자가진행 규칙으로 병목 제거
- **Sub-features:**
  - [x] 절대 규칙: Backlog/RESERVE에 태스크 남아있으면 IDLE 금지
  - [x] 빌드+런타임 에러 최우선 점검 (Step 0.1, BOARD 읽기 전)
  - [x] SUPERVISOR 감사 이력 확인 (수정 대상 파일의 기존 BUG 패턴 참조)
  - [x] 할 일 우선순위: Rejected > In Progress > In Review > Backlog > RESERVE
  - [x] NEEDS_WORK grep 필수 (reviews/ 디렉토리 검색)
  - [x] 아키텍처 체크리스트 (구현 전 GitQueue/EventBus/인코딩 점검)
  - [x] UI 통합 자가 검증 (호출처, UI 진입점, SPEC 와이어프레임 대조)
  - [x] 리뷰 필수 여부 확인 (새 시스템 = 필수, QA/검증 = 자가진행 허용)
  - [x] 자가진행 프로토콜 (APPROVE → Done + 다음 픽업, NEEDS_WORK → 즉시 수정)
  - [x] specs/SPEC-XXX.md 참조 필수 (로그에 "specs 참조: Y/N" 기록)
  - [x] 커밋 전 체크 (빌드 에러, 테스트 실행, 기존 테스트 실패 시 제출 금지)
  - [x] 토론 응답 ([개발자 응답] 섹션)

### Client 리뷰 시스템
- **Status:** Done
- **Description:** 멀티 페르소나가 각각 독립적으로 리뷰하고, 4계층 검증을 수행하는 QA 시스템
- **Sub-features:**
  - [x] 4계층 검증 체계:
    - [x] 검증 1: 엔진 검증 (에디터 쿼리, 씬/프리팹 상태 확인)
    - [x] 검증 2: 코드 추적 (git diff + 소스코드 로직 정확성)
    - [x] 검증 3: UI 추적 (입력→이벤트→반응 체인, 패널 열기/닫기)
    - [x] 검증 4: 플레이 시나리오 (사용자 행동 시뮬레이션)
  - [x] 멀티 페르소나 리뷰 (3~9명, project.config.md에서 정의)
  - [x] 페르소나별 독립 의견 (인상, 문제점, 제안)
  - [x] 페르소나 회의록 (의견 불일치 시 토론 → 합의안 도출)
  - [x] 종합 판정 테이블 (페르소나별 ✅/⚠️/❌ + 핵심 사유)
  - [x] 최종 권고: APPROVE / NEEDS_WORK
  - [x] 깊은 리뷰 (5건 중 1건, 코드 직접 읽기, [깊은 리뷰] 태그)
  - [x] In Review 태스크만 리뷰 (In Progress/Backlog 절대 금지)
  - [x] REVIEW 버전 관리 (REVIEW-XXX-vN.md)
  - [x] 토론 응답 ([고객사 응답] 섹션, UX/플레이어 관점)

### Coordinator 운영 관리
- **Status:** Done
- **Description:** 에이전트 간 소통 흐름 관리, 보드 동기화, 기획서 선제 작성, 시스템 자기 개선
- **Sub-features:**
  - [x] BOARD 동기화 점검 (로드맵 vs 활성 섹션 일치 확인 + 자동 수정)
  - [x] APPROVE → Done 이동 + 로드맵 ✅ (리뷰 파일 경로 비고에 기록)
  - [x] NEEDS_WORK → Rejected 이동 + 로드맵 ❌ (리뷰 파일 경로 비고에 기록)
  - [x] RESERVE 잔여 점검 (10건 이하 → 20건+ 보충, 기존 기능 개선 > 신규)
  - [x] 에이전트 상태 감시 (BACKLOG_EMPTY, AGENT_STALE 30분+, 3회+ NEEDS_WORK)
  - [x] 기획서 선제 작성 (다음 3건의 SPEC-XXX.md, 수치/연동/UI/데이터/세이브)
  - [x] SPEC 소진 후 폴백 체인 (BOARD 검증 → 프롬프트 개선 제안 → 미래 배치 기획 → 현황 스냅샷)
  - [x] 컨텍스트 트리밍 (로그 30루프 초과 정리, Done 10건 초과 아카이브)
  - [x] 메일 점검 (Gmail subject 검색, BOARD/RESERVE 반영)
  - [x] 자기 개선 (효율성 평가, 프롬프트 자기수정, 다른 에이전트 개선 DISCUSS 제안)
  - [x] 토론 응답 ([Coordinator 응답] 섹션)
  - [ ] 메일 통합 구현 (Gmail API 또는 CLI 연동 — 현재 스켈레톤)

### 토론 시스템 (Discussions)
- **Status:** Done
- **Description:** 에이전트 간 구조화된 비동기 토론으로 프로세스 개선과 쟁점 해결
- **Sub-features:**
  - [x] DISCUSS 템플릿 (배경/문제, 안건, 4개 에이전트 응답 섹션, 합의)
  - [x] 에이전트별 응답 섹션 ([감독관 응답], [개발자 응답], [고객사 응답], [Coordinator 응답])
  - [x] 합의 후 discussions/concluded/로 이동
  - [x] Coordinator가 반복 이슈 감지 시 자동 생성
  - [x] 프롬프트 개선 제안 (DISCUSS-PROMPT-XXX.md, 직접 수정 금지)

### 태스크 문서 체계 (Document Pipeline)
- **Status:** Done
- **Description:** 태스크의 생명주기를 따라가는 구조화된 문서 파이프라인
- **Sub-features:**
  - [x] TASK 템플릿 — 우선순위, 배경, 요구사항, 수용 기준, 참고자료, 파일 위치
  - [x] SPEC 템플릿 — 수치/밸런스, 데이터 구조, 연동 경로, UI 와이어프레임, 호출 진입점, 세이브 연동
  - [x] REVIEW 템플릿 — 4계층 검증 결과, 페르소나별 리뷰, 종합 판정, 페르소나 회의록
  - [x] DECISION 템플릿 — 리뷰 요약, 판단(APPROVE/REWORK/REJECT), 근거, 수정 지시
  - [x] DISCUSS 템플릿 — 배경, 안건, 에이전트별 응답, 합의

---

## 실행/설정 도구 (Scripts & Tools)

### 자동 셋업 (Auto-Setup)
- **Status:** Done
- **Description:** 기존 프로젝트를 분석하여 오케스트레이션 시스템을 자동 구성하는 셋업 스크립트
- **Sub-features:**
  - [x] 엔진 자동 감지: Unity (.meta, ProjectVersion.txt)
  - [x] 엔진 자동 감지: Godot (project.godot, GDScript/C# 판별)
  - [x] 엔진 자동 감지: Unreal (.uproject, C++/Blueprint)
  - [x] Unity 버전 자동 추출 (ProjectVersion.txt → ProjectSettings.asset 폴백)
  - [x] 디렉토리 구조 자동 스캔 (소스코드, 에셋, 테스트, 씬, 도구)
  - [x] project.config.md 자동 생성
  - [x] orchestration/ 디렉토리 구조 생성
  - [x] 에이전트 runner 스크립트 자동 생성 (.run_*.sh)
  - [x] 에이전트 역할 정의 복사 (agents/)
  - [x] 프롬프트 복사 (prompts/)
  - [x] 템플릿 복사 (templates/)
  - [ ] 웹 프로젝트 자동 감지 (package.json, tsconfig.json 기반)
  - [ ] Python 프로젝트 자동 감지 (requirements.txt, pyproject.toml 기반)

### 에이전트 런처 (Agent Launcher)
- **Status:** Done
- **Description:** 4개 에이전트를 각각 새 터미널에서 병렬 실행하는 런처
- **Sub-features:**
  - [x] 프레임워크→프로젝트 프롬프트 자동 동기화 (launch.sh 실행 시)
  - [x] 전체 또는 특정 에이전트만 실행 (supervisor, developer, client, coordinator)
  - [x] 약칭 지원 (s, d, c, co)
  - [x] OS 자동 감지 (Windows/Mac/Linux)
  - [x] Windows Terminal 탭 실행 (wt.exe)
  - [x] macOS Terminal.app 실행
  - [x] Linux gnome-terminal/tmux 실행
  - [x] 실행 중인 에이전트 확인 (--stop)
  - [x] 에이전트 간 3초 시작 간격 (git 충돌 방지)

### 통합 진입점 (orchestrate.bat)
- **Status:** Done
- **Description:** 의존성 확인부터 에이전트 실행까지 전체 셋업 + 실행을 한 번에 처리하는 Windows 메인 스크립트
- **Sub-features:**
  - [x] 의존성 자동 확인 (Git for Windows, Claude CLI, framework/, Windows Terminal)
  - [x] GUI 폴더 선택 (PowerShell 다이얼로그)
  - [x] 기존 오케스트레이션 감지 (Resume / Reconfigure / Cancel)
  - [x] 자동 preflight scaffold 실행
  - [x] auto-setup 실행
  - [x] feature 추출 + backlog seed (선택적)
  - [x] 설정 리뷰 단계 (project.config.md 확인 기회)
  - [x] 에이전트 실행

### 운영 도구 허브 (orchestration-tools.bat)
- **Status:** Done
- **Description:** 일상 운영의 단일 진입점 — 설정, 모니터링, 제어, 테스트를 한 곳에서 접근
- **Sub-features:**
  - [x] 초기 설정 또는 재개
  - [x] 진행 상태 모니터링
  - [x] FREEZE / DRAIN_FOR_TEST 제어
  - [x] 테스트 윈도우 준비
  - [x] 런타임 에러 모니터링
  - [x] 자연어 기반 기능 추가

### 런타임 모니터 (monitor.sh)
- **Status:** Done
- **Description:** 엔진 로그를 실시간 감시하여 에러/크래시를 자동 분류하고 오케스트레이션에 보고
- **Sub-features:**
  - [x] Editor.log / Player.log 감시 (Unity)
  - [x] Godot/Unreal 로그 지원
  - [x] OS별 LOCALAPPDATA 자동 해석 (Windows/Mac/Linux)
  - [x] project.config.md에서 에러 로그 경로 자동 읽기
  - [x] 에러 분류: CRITICAL / ERROR / WARNING / UI
  - [x] CRITICAL 패턴: NullReferenceException, StackOverflow, OutOfMemory, CRASH, Segfault
  - [x] orchestration/logs/MONITOR.md 자동 생성 (Supervisor가 읽고 수정)
  - [x] --player 모드 (빌드 버전 로그)
  - [x] --analyze 모드 (현재 로그 1회 분석)

### Preflight 문서 자동 생성
- **Status:** Done
- **Description:** 대상 프로젝트에 최소 문서 구조를 자동 scaffold
- **Sub-features:**
  - [x] docs/PRE-FLIGHT-CHECKLIST.md 생성
  - [x] docs/current-state.md 생성 (프로젝트 스냅샷 템플릿)
  - [x] docs/dev-priorities.md 생성 (개발 우선순위 템플릿)
  - [x] docs/testing.md 생성 (테스트 가이드 템플릿)
  - [x] docs/architecture.md 생성 (아키텍처 문서 템플릿)
  - [x] 최소 README.md 생성 (없을 때만)
  - [x] 기존 파일 덮어쓰기 방지

### 운영 제어 스크립트
- **Status:** Done
- **Description:** FREEZE/DRAIN 설정, 모니터링, 테스트 윈도우를 제어하는 PowerShell/Batch 스크립트
- **Sub-features:**
  - [x] manage-orchestration.ps1 — FREEZE 설정/해제, DRAIN_FOR_TEST 설정/해제
  - [x] monitor-orchestration.ps1 — 보드 상태, 에이전트 헬스, 최신 리뷰, Git 상태
  - [x] test-orchestration.ps1 — 테스트 윈도우 진입, safe point 대기, 테스트 모드
  - [x] 각 .bat 래퍼 파일

### 기능 추가 도구 (add-feature)
- **Status:** In Progress
- **Description:** 자연어 기능 요청을 TASK + SPEC 초안으로 변환하여 BACKLOG에 추가
- **Sub-features:**
  - [x] add-feature.sh 스크립트 기본 구조
  - [x] add-feature.bat 래퍼
  - [x] Claude 프롬프트를 통한 NL→태스크 변환
  - [ ] SPEC 자동 생성 연동 완성
  - [ ] 복수 태스크 분할 지원

### Feature 추출 / Backlog Seed
- **Status:** Done
- **Description:** 프로젝트 코드에서 기능을 추출하고 초기 BACKLOG_RESERVE를 생성
- **Sub-features:**
  - [x] extract-features.sh — 프로젝트에서 feature 목록 추출
  - [x] seed-backlog.sh — BACKLOG_RESERVE.md 초기 항목 생성
  - [x] orchestrate.bat에서 선택적 실행

---

## UI/UX

### 터미널 인터페이스
- **Status:** Done
- **Description:** 에이전트 실행 현황을 모니터링하는 터미널 기반 인터페이스
- **Sub-features:**
  - [x] Windows Terminal 멀티탭 에이전트 실행
  - [x] 에이전트별 독립 터미널 윈도우
  - [x] orchestration-tools.bat 메뉴 기반 허브
  - [x] 실행 중 에이전트 프로세스 확인 (--stop)
  - [ ] 실시간 통합 대시보드 (TUI — 전체 에이전트 상태 한 화면)
  - [ ] 에이전트 로그 실시간 스트리밍 뷰

### GUI 폴더 선택
- **Status:** Done
- **Description:** Windows PowerShell 기반 GUI 폴더 선택 다이얼로그
- **Sub-features:**
  - [x] pick-folder.ps1 — FolderBrowserDialog 기반 폴더 선택
  - [x] 명령줄 인자로 직접 경로 전달도 가능

---

## Art & Audio

### Sprites
- [x] 에셋 규격 정의 시스템 (project.config.md에서 해상도/PPU/스타일 지정)
- [x] 🎨 에셋 태스크 태그 (Supervisor 전용 에셋 생성)
- [x] 에셋 선제 생성 (RESERVE 다음 5건 필요 에셋 미리 생성)
- [ ] 에셋 자동 검증 (파일 크기, 해상도, 포맷 자동 체크)

### Audio
- [x] 오디오 규격 정의 시스템 (project.config.md에서 Hz/bit/mono 지정)
- [ ] 오디오 파일 자동 검증 (Hz, 비트레이트, 채널 자동 체크)

---

## Polish & QoL

- [x] 프레임워크→프로젝트 프롬프트 자동 동기화 (launch.sh/init.sh 실행 시)
- [x] 기존 오케스트레이션 Resume/Reconfigure 선택
- [x] 기존 파일 덮어쓰기 방지 (preflight, init)
- [x] 에이전트 약칭 지원 (s, d, c, co)
- [x] OS 크로스플랫폼 지원 (Windows/Mac/Linux)
- [x] 환경변수 자동 치환 (%LOCALAPPDATA%, %APPDATA%)
- [x] 한국어 + 영어 혼합 지원 (프롬프트 한국어, 코드 영어)
- [ ] 에이전트 루프 완료 알림 (데스크톱 알림 또는 사운드)
- [ ] 에이전트 실행 통계 요약 (일일 리포트)
- [ ] 프로젝트 간 설정 프리셋 저장/불러오기
- [ ] 에이전트 로그 검색 도구 (키워드, 날짜, 에이전트별)
- [ ] BOARD 변경 이력 시각화 (타임라인 뷰)
- [ ] 커밋 히스토리와 태스크 연동 시각화

---

## Known Issues / TODO

- [ ] 메일 통합 미구현 — Coordinator Step 5에서 Gmail 검색 참조하나 실제 API/CLI 연동 없음
- [ ] MCP 엔진 통합 미구현 — Client 검증 1(엔진 검증)에서 MCP-Unity 참조하나 MCP 클라이언트 코드 없음
- [ ] 웹/비게임 프로젝트 지원 부족 — auto-setup.sh가 Unity/Godot/Unreal만 감지, 웹/서버 프로젝트 미지원
- [ ] 에러 모니터 Godot/Unreal 경로 — monitor.sh에서 Godot/Unreal 로그 경로 자동 감지 개선 필요
- [ ] 에이전트 충돌 복구 — 에이전트가 중간에 크래시했을 때 자동 재시작 메커니즘 없음
- [ ] BOARD.md 동시 수정 충돌 — 여러 에이전트가 거의 동시에 BOARD를 수정하면 git merge conflict 가능
- [ ] add-feature.sh SPEC 자동 생성 — NL→TASK 변환은 있으나 SPEC 자동 생성 연동 미완성
- [ ] 에이전트 간 우선순위 조율 — Supervisor와 Developer가 같은 파일을 동시 수정하는 edge case 완화 필요
- [ ] CI/CD 파이프라인 통합 — 빌드/테스트 결과를 자동으로 BOARD에 반영하는 연동 없음
- [ ] 비용 추적 — 에이전트별 Claude API 사용량/비용 실시간 추적 없음
- [ ] 다국어 프롬프트 — 현재 한국어 중심, 영어 전용 프롬프트 세트 미제공
