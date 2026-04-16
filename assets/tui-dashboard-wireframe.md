# TUI 대시보드 레이아웃 와이어프레임

## 개요
실시간 통합 대시보드의 터미널 레이아웃 설계 — 에이전트 상태, BOARD 요약, 최신 로그, 에러 현황을 한 화면에 배치하는 와이어프레임

## 전체 레이아웃 (터미널 80x24)

```
┌─────────────────────── AI Dev Orchestration Dashboard ────────────────────────┐
│ 🔄 Coordinator  🔧 Developer  📊 Supervisor  🎯 Client  │ Budget: $0.82/$1.00  │
├─────────────────────────────────────────────────────────────────────────────────┤
│ BOARD STATUS                              │ AGENT HEALTH                        │
├───────────────────────────────────────────┼─────────────────────────────────────┤
│ 📋 Done: 3      🔄 Progress: 1           │ Coordinator: ✅ Active              │
│ 📦 Backlog: 0   📝 Review: 0             │ Developer:   🔄 Running             │
│ 🚫 Rejected: 0  ⚠️ P0 Tasks: 0           │ Supervisor:  ⏸️ Idle               │
│                                           │ Client:      ✅ Ready               │
├───────────────────────────────────────────┼─────────────────────────────────────┤
│ LATEST TASKS                              │ ERROR MONITOR                       │
├───────────────────────────────────────────┼─────────────────────────────────────┤
│ T-023: 🔄 Fix login validation           │ 🟢 No critical errors              │
│ T-022: ✅ Update user auth flow          │ ⚠️ Unity build warnings: 2         │
│ T-021: ✅ Add payment integration        │ 📊 Last error: 2h ago              │
│ T-020: ✅ Optimize database queries      │ 🔍 Monitor status: Active          │
├───────────────────────────────────────────┼─────────────────────────────────────┤
│ ACTIVITY LOG                              │ SYSTEM INFO                         │
├───────────────────────────────────────────┼─────────────────────────────────────┤
│ [14:23] Developer: Starting T-023 impl   │ 💾 CPU: 45%    RAM: 68%           │
│ [14:20] Supervisor: Approved T-023       │ 🌡️ Temp: 62°C   GPU: 23%          │
│ [14:18] Coordinator: Created T-023       │ 📂 Disk: 156GB free                │
│ [14:15] Client: Validation passed        │ 🕒 Uptime: 2h 34m                 │
│ [14:12] Developer: Completed T-022       │ 🔌 Git: main branch, clean         │
├───────────────────────────────────────────┴─────────────────────────────────────┤
│ COMMAND INPUT                                                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│ > help                                                                          │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 컴포넌트 세부 설계

### 1. 헤더 바 (상단 2줄)
```
┌─────────────────────── AI Dev Orchestration Dashboard ────────────────────────┐
│ 🔄 Coordinator  🔧 Developer  📊 Supervisor  🎯 Client  │ Budget: $0.82/$1.00  │
```
- **좌측**: 4개 에이전트 상태 아이콘
- **우측**: 현재 API 예산 사용량
- **색상**: 타이틀은 파란색, 예산은 사용률에 따라 색상 변경

### 2. BOARD STATUS (좌측 상단)
```
│ BOARD STATUS                              │
├───────────────────────────────────────────┤
│ 📋 Done: 3      🔄 Progress: 1           │
│ 📦 Backlog: 0   📝 Review: 0             │
│ 🚫 Rejected: 0  ⚠️ P0 Tasks: 0           │
```
- **실시간 업데이트**: BOARD.md 변경 시 자동 갱신
- **색상**: P0 Tasks는 빨간색, 진행 중은 노란색

### 3. AGENT HEALTH (우측 상단)
```
│ AGENT HEALTH                        │
├─────────────────────────────────────┤
│ Coordinator: ✅ Active              │
│ Developer:   🔄 Running             │
│ Supervisor:  ⏸️ Idle               │
│ Client:      ✅ Ready               │
```
- **상태 표시**:
  - ✅ Active (정상 동작)
  - 🔄 Running (작업 중)
  - ⏸️ Idle (대기 중)
  - ❌ Error (에러 상태)
  - 🔌 Offline (비활성)

### 4. LATEST TASKS (좌측 중단)
```
│ LATEST TASKS                              │
├───────────────────────────────────────────┤
│ T-023: 🔄 Fix login validation           │
│ T-022: ✅ Update user auth flow          │
│ T-021: ✅ Add payment integration        │
│ T-020: ✅ Optimize database queries      │
```
- **최신 4개 태스크** 표시
- **상태 아이콘**: 🔄 진행중, ✅ 완료, 📝 리뷰, 🚫 거부

### 5. ERROR MONITOR (우측 중단)
```
│ ERROR MONITOR                       │
├─────────────────────────────────────┤
│ 🟢 No critical errors              │
│ ⚠️ Unity build warnings: 2         │
│ 📊 Last error: 2h ago              │
│ 🔍 Monitor status: Active          │
```
- **에러 상태**: 🟢 정상, 🟡 경고, 🔴 심각
- **빌드 상태**: 각 플랫폼별 빌드 결과
- **마지막 에러 시간**: 상대적 시간 표시

### 6. ACTIVITY LOG (좌측 하단)
```
│ ACTIVITY LOG                              │
├───────────────────────────────────────────┤
│ [14:23] Developer: Starting T-023 impl   │
│ [14:20] Supervisor: Approved T-023       │
│ [14:18] Coordinator: Created T-023       │
│ [14:15] Client: Validation passed        │
│ [14:12] Developer: Completed T-022       │
```
- **실시간 로그**: 최신 5개 액티비티
- **시간 포맷**: [HH:MM] 형식
- **에이전트별 색상**: 각 에이전트마다 다른 색상

### 7. SYSTEM INFO (우측 하단)
```
│ SYSTEM INFO                         │
├─────────────────────────────────────┤
│ 💾 CPU: 45%    RAM: 68%           │
│ 🌡️ Temp: 62°C   GPU: 23%          │
│ 📂 Disk: 156GB free                │
│ 🕒 Uptime: 2h 34m                 │
│ 🔌 Git: main branch, clean         │
```
- **시스템 모니터링**: CPU, RAM, 디스크 사용량
- **Git 상태**: 현재 브랜치, 변경사항 여부
- **업타임**: 대시보드 실행 시간

### 8. COMMAND INPUT (하단)
```
│ COMMAND INPUT                                                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│ > help                                                                          │
```
- **명령어 입력**: 대화형 명령어 실행
- **자동완성**: 사용 가능한 명령어 제안

## 상호작용 디자인

### 키보드 단축키
- `Tab`: 패널 간 이동
- `Enter`: 선택된 항목 상세보기
- `R`: 수동 새로고침
- `Q`: 종료
- `H`: 도움말
- `F1-F4`: 에이전트별 로그 보기

### 명령어 시스템
```
Available commands:
- help: 도움말 표시
- tasks: 전체 태스크 목록
- agent <name>: 특정 에이전트 상태
- logs <agent>: 에이전트별 로그
- board: BOARD.md 열기
- config: 설정 보기/수정
- budget: API 사용량 상세
- clear: 화면 지우기
```

## 반응형 레이아웃

### 작은 터미널 (80x16)
```
┌─── AI Dev Dashboard ───┐
│ 🔄📊🔧🎯 │ $0.82/$1.00  │
├─────────────────────────┤
│ Done:3 Progress:1       │
│ P0:0   Review:0         │
├─────────────────────────┤
│ Coord:✅ Dev:🔄        │
│ Sup:⏸️ Client:✅      │
├─────────────────────────┤
│ [14:23] Dev: T-023 impl │
│ [14:20] Sup: Approved   │
├─────────────────────────┤
│ 🟢 No errors  CPU:45%  │
│ > help                  │
└─────────────────────────┘
```

### 큰 터미널 (120x30)
- 추가 패널: Recent Commits, Performance Metrics
- 더 많은 로그 라인 표시
- 상세한 시스템 정보

## 색상 테마

### 다크 테마 (기본)
- 배경: 검은색
- 테두리: 회색
- 텍스트: 흰색
- 강조: 파란색, 녹색, 노란색, 빨간색

### 라이트 테마
- 배경: 흰색
- 테두리: 회색
- 텍스트: 검은색
- 강조: 파란색, 녹색, 주황색, 빨간색

## 구현 기술 스택

- **TUI 라이브러리**: Rich (Python) 또는 Blessed
- **실시간 업데이트**: 파일 감시 (watchdog)
- **시스템 모니터링**: psutil
- **Git 정보**: GitPython
- **설정 관리**: YAML/TOML

---

*생성일: 2026-04-16*
*태스크: A-002 TUI 대시보드 레이아웃 와이어프레임*