# SPEC-R-024: BOARD 변경 이력 시각화

**관련 태스크:** R-024
**작성일:** 2026-04-13

---

## 개요
BOARD.md의 git diff 이력을 파싱하여 태스크별 상태 변화를 타임라인으로 시각화하는 도구.

## 상세 설명
BOARD.md는 git으로 버전 관리되므로, 과거 커밋의 diff를 분석하면 각 태스크가 언제 어떤 상태로 이동했는지 추적할 수 있다. git log + diff를 파싱하여 태스크별 상태 전이 타임라인(Backlog → In Progress → In Review → Done/Rejected)을 재구성하고, 터미널 또는 Markdown/HTML로 시각화한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 분석 대상 | BOARD.md의 git history | `git log -p BOARD.md` |
| 감지 패턴 | 섹션 이동 (📋→🔧→👀→✅/❌) | 정규식 매칭 |
| 출력 포맷 | 터미널 ASCII / Markdown / HTML | 사용자 선택 |
| 분석 기간 | 최근 7일 (기본), 커스텀 가능 | --days 옵션 |
| 태스크 필터 | 특정 태스크만 추적 | --task TASK-037 |

## 데이터 구조
```bash
# board-timeline.sh 내부 데이터
# 각 커밋에서 BOARD.md diff를 분석하여 태스크 상태 변화 추출
{
  "TASK-037": [
    {"timestamp": "2026-04-13T10:00:00", "from": null, "to": "Backlog", "by": "SUPERVISOR"},
    {"timestamp": "2026-04-13T10:30:00", "from": "Backlog", "to": "In Progress", "by": "DEVELOPER"},
    {"timestamp": "2026-04-13T12:00:00", "from": "In Progress", "to": "In Review", "by": "DEVELOPER"},
    {"timestamp": "2026-04-13T13:00:00", "from": "In Review", "to": "Rejected", "by": "COORDINATOR"},
    {"timestamp": "2026-04-13T13:30:00", "from": "Rejected", "to": "In Progress", "by": "DEVELOPER"},
    {"timestamp": "2026-04-13T14:30:00", "from": "In Progress", "to": "In Review", "by": "DEVELOPER"},
    {"timestamp": "2026-04-13T15:00:00", "from": "In Review", "to": "Done", "by": "COORDINATOR"}
  ]
}
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| board-timeline.sh | git log BOARD.md | git diff 파싱 |
| board-timeline.sh | 터미널 | ASCII 타임라인 출력 |
| board-timeline.sh | orchestration/logs/TIMELINE.md | Markdown 저장 (선택) |
| daily-report.sh (R-019) | board-timeline.sh | 일일 리포트에 타임라인 포함 (선택) |

## UI 와이어프레임
```
$ ./board-timeline.sh --days 1

BOARD 태스크 타임라인 (2026-04-13)
══════════════════════════════════════════════════════

TASK-037: 인벤토리 아이템 정렬
  10:00 ─── 📋 Backlog
  10:30 ─── 🔧 In Progress (DEVELOPER)
  12:00 ─── 👀 In Review
  13:00 ─── ❌ Rejected (UI 진입점 누락)
  13:30 ─── 🔧 In Progress (리워크)
  14:30 ─── 👀 In Review
  15:00 ─── ✅ Done
  ⏱ 총 소요: 5시간 (리워크 1회)

TASK-038: 세이브 슬롯 확장
  11:00 ─── 📋 Backlog
  11:30 ─── 🔧 In Progress (DEVELOPER)
  ...
```

## 호출 진입점
- **어디서:** 터미널에서 직접 실행 또는 orchestration-tools.bat 메뉴
- **어떻게:** `./board-timeline.sh [--days N] [--task TASK-XXX] [--format md|html]`

## 수용 기준
- [ ] `board-timeline.sh` 스크립트 구현
- [ ] git log BOARD.md diff에서 태스크 상태 전이 추출
- [ ] 태스크별 타임라인 ASCII 출력
- [ ] 날짜 범위 필터 (--days)
- [ ] 특정 태스크 필터 (--task)
- [ ] 각 상태 전이의 소요 시간 계산
- [ ] 리워크 횟수 표시
- [ ] 태스크별 총 소요 시간 계산
- [ ] Markdown 출력 옵션 (--format md)
