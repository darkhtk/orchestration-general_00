# SPEC-R-016: 실시간 통합 대시보드 (TUI)

**관련 태스크:** R-016
**작성일:** 2026-04-13

---

## 개요
전체 에이전트 상태, BOARD 현황, 최신 리뷰, 에러 현황을 한 화면에서 실시간 모니터링하는 터미널 대시보드.

## 상세 설명
현재 에이전트 모니터링은 monitor-orchestration.ps1로 스냅샷 기반이다. 실시간으로 BOARD.md, 에이전트 로그, MONITOR.md를 감시하고 한 화면에 통합 표시하는 TUI(Terminal User Interface) 대시보드를 구현한다. ncurses 또는 Python Rich/Textual 기반으로, 에이전트 상태 패널, 태스크 보드 패널, 로그 스트림 패널, 에러 패널을 제공한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 갱신 주기 | 5초 | 파일 변경 감지 기반 |
| 최소 터미널 크기 | 120x40 | 4분할 레이아웃 |
| 구현 기술 | Python + Rich/Textual | 크로스플랫폼 |
| 에이전트 상태 표시 | 🟢 Active / 🟡 Idle / 🔴 Crashed / ⏸ Frozen | PID + 마지막 활동 |
| 로그 표시 줄 수 | 최신 20줄 | 에이전트별 |
| 에러 패널 | MONITOR.md CRITICAL/ERROR | 최신 10건 |

## 데이터 구조
```python
# dashboard.py 내부 구조
class DashboardState:
    agents: dict[str, AgentStatus]  # SUPERVISOR, DEVELOPER, CLIENT, COORDINATOR
    board: BoardSummary             # Backlog/InProgress/InReview/Done 건수
    recent_logs: dict[str, list]    # 에이전트별 최신 로그
    errors: list[ErrorEntry]        # MONITOR.md 에러 목록
    last_updated: datetime

class AgentStatus:
    name: str
    status: str       # active/idle/crashed/frozen
    pid: int
    last_activity: datetime
    current_task: str  # BOARD에서 추출
    loop_count: int
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| dashboard.py | BOARD.md | 파일 읽기 (5초 폴링) |
| dashboard.py | orchestration/logs/*.md | 에이전트 로그 tail |
| dashboard.py | orchestration/logs/MONITOR.md | 에러 현황 |
| dashboard.py | .pid_AGENT.lock | 에이전트 프로세스 상태 |
| dashboard.py | orchestration/reviews/ | 최신 리뷰 요약 |

## UI 와이어프레임
```
┌─────────────────────── Orchestration Dashboard ────────────────────────┐
│ ┌── Agents ──────────────────┐ ┌── Board Summary ──────────────────┐  │
│ │ 🟢 SUPERVISOR  PID:1234    │ │ 📋 Backlog:    3                  │  │
│ │    Loop: 42  Task: A-015   │ │ 🔧 In Progress: 1 (TASK-038)     │  │
│ │ 🟢 DEVELOPER   PID:1235   │ │ 👀 In Review:   1 (TASK-037)     │  │
│ │    Loop: 38  Task: R-037   │ │ ✅ Done:        8                  │  │
│ │ 🟡 CLIENT      PID:1236   │ │ ❌ Rejected:    0                  │  │
│ │    Loop: 12  Idle (2m)     │ │                                    │  │
│ │ 🟢 COORDINATOR PID:1237   │ │ RESERVE: 18건 남음                 │  │
│ │    Loop: 40  Sync OK       │ │                                    │  │
│ └────────────────────────────┘ └────────────────────────────────────┘  │
│ ┌── Recent Logs ─────────────────────────────────────────────────────┐ │
│ │ [14:30:15] DEV  커밋 완료: feat: 인벤토리 정렬 (#TASK-037)       │ │
│ │ [14:30:10] SUP  코드 감사 시작: PlayerController.cs               │ │
│ │ [14:29:55] CORD BOARD 동기화 완료: 로드맵 ↔ 활성 섹션 일치       │ │
│ │ [14:29:40] CLI  REVIEW-037-v1.md 작성 완료: APPROVE              │ │
│ │ [14:29:20] DEV  TASK-037 구현 시작: 인벤토리 아이템 정렬          │ │
│ └────────────────────────────────────────────────────────────────────┘ │
│ ┌── Errors (MONITOR.md) ─────────────────────────────────────────────┐│
│ │ (최근 에러 없음)                                                    ││
│ └────────────────────────────────────────────────────────────────────┘│
│ [q] Quit  [r] Refresh  [f] Filter  [1-4] Agent Log Detail           │
└───────────────────────────────────────────────────────────────────────┘
```

## 호출 진입점
- **어디서:** 터미널에서 직접 실행 또는 orchestration-tools.bat 메뉴
- **어떻게:** `python dashboard.py --project /path/to/project` 또는 `./dashboard.sh`

## 수용 기준
- [ ] Python Rich/Textual 기반 TUI 대시보드 구현
- [ ] 에이전트 상태 패널 (4개 에이전트 상태 실시간 표시)
- [ ] BOARD 요약 패널 (섹션별 건수, 현재 태스크명)
- [ ] 최신 로그 스트림 패널 (에이전트별 혼합 표시)
- [ ] 에러 현황 패널 (MONITOR.md CRITICAL/ERROR)
- [ ] 5초 간격 자동 갱신
- [ ] 키보드 단축키 (q: 종료, r: 새로고침, 1-4: 에이전트 상세)
- [ ] 최소 터미널 크기 미달 시 안내 메시지
- [ ] Windows Terminal + macOS Terminal + Linux 동작
