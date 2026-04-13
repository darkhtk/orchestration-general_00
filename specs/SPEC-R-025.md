# SPEC-R-025: 커밋 히스토리와 태스크 연동 시각화

**관련 태스크:** R-025
**작성일:** 2026-04-13

---

## 개요
커밋 메시지의 태스크 번호를 파싱하여 태스크별 커밋 이력, 코드 변경량, 시간대를 시각화하는 도구.

## 상세 설명
오케스트레이션 프레임워크의 커밋 컨벤션(feat: / fix: / refactor: 등)과 태스크 번호 연동을 활용하여, 각 태스크에 연결된 커밋 목록, 코드 변경량(insertions/deletions), 작업 시간대 등을 추출하고 시각화한다. R-024(BOARD 타임라인)이 상태 전이에 집중한다면, 이 도구는 실제 코드 변경에 집중한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 커밋 파싱 | `git log --all --oneline --stat` | 전체 이력 |
| 태스크 연결 | 커밋 메시지에서 TASK-XXX / R-XXX 추출 | 정규식 |
| 변경량 | insertions + deletions | git diff --stat |
| 에이전트 식별 | 커밋 author 또는 메시지 패턴 | Supervisor/Developer 구분 |
| 출력 포맷 | 터미널 ASCII / Markdown / CSV | 사용자 선택 |
| 분석 기간 | 전체 (기본), 날짜 필터 가능 | --after/--before |

## 데이터 구조
```bash
# commit-history.sh 내부 데이터 구조
{
  "TASK-037": {
    "title": "인벤토리 아이템 정렬",
    "commits": [
      {
        "hash": "abc1234",
        "message": "feat: 인벤토리 아이템 정렬 기능 구현",
        "author": "DEVELOPER",
        "date": "2026-04-13T12:00:00",
        "insertions": 85,
        "deletions": 12,
        "files_changed": 3
      },
      {
        "hash": "def5678",
        "message": "fix: 인벤토리 정렬 UI 진입점 수정 (리워크)",
        "author": "DEVELOPER",
        "date": "2026-04-13T14:30:00",
        "insertions": 22,
        "deletions": 5,
        "files_changed": 2
      }
    ],
    "total_insertions": 107,
    "total_deletions": 17,
    "total_files": 4,
    "duration": "4h30m",
    "rework_commits": 1
  }
}
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| commit-history.sh | git log | 커밋 이력 파싱 |
| commit-history.sh | BOARD.md | 태스크 제목 매칭 |
| commit-history.sh | 터미널 | ASCII 시각화 출력 |
| commit-history.sh | orchestration/logs/COMMIT-HISTORY.md | Markdown 저장 (선택) |
| daily-report.sh (R-019) | commit-history.sh | 일일 리포트에 커밋 통계 포함 |
| board-timeline.sh (R-024) | commit-history.sh | 타임라인 + 커밋 통합 뷰 (향후) |

## UI 와이어프레임
```
$ ./commit-history.sh --days 1

커밋-태스크 연동 리포트 (2026-04-13)
══════════════════════════════════════════════════════

TASK-037: 인벤토리 아이템 정렬
  ┌─ abc1234 feat: 인벤토리 아이템 정렬 기능 구현
  │  12:00  +85 -12  3 files (DEVELOPER)
  │
  ├─ def5678 fix: 인벤토리 정렬 UI 진입점 수정 (리워크)
  │  14:30  +22 -5   2 files (DEVELOPER)
  │
  └─ 합계: +107 -17, 4 files, 리워크 1회, 4h30m

TASK-038: 세이브 슬롯 확장
  ┌─ ghi9012 feat: 세이브 슬롯 3→5 확장
  │  11:30  +120 -30  5 files (DEVELOPER)
  │
  ├─ jkl3456 asset: 세이브 슬롯 UI 아이콘 추가
  │  11:45  +5 -0    2 files (SUPERVISOR)
  │
  └─ 합계: +125 -30, 6 files, 리워크 0회, 2h15m

══════════════════════════════════════════════════════
전체 요약: 4 커밋, +232 -47, 리워크 비율 25%
```

## 호출 진입점
- **어디서:** 터미널에서 직접 실행
- **어떻게:** `./commit-history.sh [--days N] [--task TASK-XXX] [--format md|csv]`

## 수용 기준
- [ ] `commit-history.sh` 스크립트 구현
- [ ] 커밋 메시지에서 TASK-XXX / R-XXX 번호 추출
- [ ] 태스크별 커밋 그룹핑 + 코드 변경량 집계
- [ ] 에이전트별(Supervisor/Developer) 커밋 구분
- [ ] 태스크별 총 소요 시간 계산 (첫 커밋 ~ 마지막 커밋)
- [ ] 리워크 커밋 식별 (fix: 접두사 + 같은 태스크)
- [ ] ASCII 타임라인 터미널 출력
- [ ] Markdown / CSV 출력 옵션
- [ ] 날짜 범위 필터 및 태스크 필터 지원
