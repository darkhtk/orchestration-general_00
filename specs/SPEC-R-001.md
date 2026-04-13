# SPEC-R-001: BOARD.md 동시 수정 충돌 방지 메커니즘

**관련 태스크:** R-001
**작성일:** 2026-04-13

---

## 개요
여러 에이전트가 동시에 BOARD.md를 수정할 때 발생하는 git merge conflict를 방지하는 파일 잠금 및 순차 쓰기 메커니즘.

## 상세 설명
현재 4개 에이전트가 각각 2분 간격으로 루프를 실행하며, BOARD.md는 모든 에이전트가 읽고 쓰는 공유 파일이다. 3초 시작 간격만으로는 루프 진행 중 동시 수정을 완전히 방지할 수 없다. 파일 기반 잠금(lock file)을 도입하여 한 번에 하나의 에이전트만 BOARD.md를 수정할 수 있도록 하고, 잠금 획득 실패 시 재시도 로직을 추가한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 잠금 파일 경로 | `orchestration/.board.lock` | 숨김 파일 |
| 잠금 타임아웃 | 30초 | 타임아웃 초과 시 stale lock으로 간주 |
| 재시도 간격 | 2초 | 잠금 획득 실패 시 |
| 최대 재시도 횟수 | 10회 | 초과 시 로그에 CRITICAL 기록 |
| 잠금 내용 | 에이전트명 + PID + 타임스탬프 | stale 판별용 |

## 데이터 구조
```
# orchestration/.board.lock (잠금 파일 내용)
AGENT=COORDINATOR
PID=12345
TIMESTAMP=2026-04-13T14:30:00+09:00
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| 각 에이전트 프롬프트 | .board.lock | 파일 생성/삭제 (쉘 명령) |
| launch.sh | 에이전트 runner | 잠금 유틸리티 함수 소싱 |
| lock-board.sh | .board.lock | atomic 파일 생성 (mkdir 기반) |
| unlock-board.sh | .board.lock | 파일 삭제 |

## UI 와이어프레임
N/A

## 호출 진입점
- **어디서:** 각 에이전트의 BOARD.md 수정 직전/직후
- **어떻게:** `source orchestration/scripts/board-lock.sh && acquire_lock AGENT_NAME` / `release_lock`

## 수용 기준
- [ ] `orchestration/scripts/board-lock.sh`에 `acquire_lock`/`release_lock` 함수 구현
- [ ] 잠금 획득 시 `.board.lock` 파일 생성, 해제 시 삭제
- [ ] 30초 초과 stale lock 자동 해제 (이전 에이전트 크래시 대응)
- [ ] 잠금 대기 중 로그에 `BOARD_LOCK_WAIT` 기록
- [ ] 최대 재시도 초과 시 로그에 `BOARD_LOCK_TIMEOUT` CRITICAL 기록
- [ ] 4개 에이전트 동시 실행 시 BOARD.md merge conflict 발생률 0%
- [ ] 각 에이전트 프롬프트에 잠금 획득/해제 절차 안내 추가
