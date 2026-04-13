# SPEC-R-002: 에이전트 충돌 자동 복구

**관련 태스크:** R-002
**작성일:** 2026-04-13

---

## 개요
에이전트 프로세스가 크래시/중단되었을 때 자동으로 상태를 복원하고 재시작하는 감시(watchdog) 메커니즘.

## 상세 설명
현재 에이전트가 중간에 크래시하면 수동으로 재시작해야 한다. 각 에이전트의 실행 상태를 주기적으로 점검하는 watchdog 스크립트를 도입하여, 비정상 종료 감지 시 자동 재시작하고 마지막 안전 지점(last safe checkpoint)부터 작업을 재개하도록 한다. BOARD.md의 In Progress 상태에서 크래시한 경우 해당 태스크를 안전하게 유지한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 헬스체크 간격 | 60초 | watchdog이 각 에이전트 프로세스 확인 |
| PID 파일 경로 | `orchestration/.pid_AGENT.lock` | 에이전트별 PID 기록 |
| 최대 자동 재시작 횟수 | 3회/시간 | 초과 시 FREEZE 삽입 + 알림 |
| 재시작 대기 시간 | 10초 | 크래시 후 재시작까지 쿨다운 |
| 크래시 로그 경로 | `orchestration/logs/CRASH-AGENT.md` | 크래시 이력 기록 |

## 데이터 구조
```
# orchestration/.pid_SUPERVISOR.lock
PID=12345
STARTED=2026-04-13T14:00:00+09:00
LOOP_COUNT=15
LAST_CHECKPOINT=BOARD_READ

# orchestration/logs/CRASH-SUPERVISOR.md
## Crash Log
| 시각 | PID | 루프 | 마지막 체크포인트 | 재시작 |
|------|-----|------|-------------------|--------|
| 2026-04-13T14:30:00 | 12345 | 15 | BOARD_READ | 자동 |
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| watchdog.sh | .pid_AGENT.lock | PID 존재/프로세스 활성 확인 |
| watchdog.sh | launch.sh | 재시작 호출 (특정 에이전트만) |
| watchdog.sh | BOARD.md | FREEZE 삽입 (재시작 한도 초과 시) |
| 에이전트 runner | .pid_AGENT.lock | 시작 시 PID 기록, 종료 시 삭제 |
| watchdog.sh | CRASH-AGENT.md | 크래시 이력 기록 |

## UI 와이어프레임
N/A

## 호출 진입점
- **어디서:** launch.sh 실행 후 백그라운드 데몬으로 자동 시작
- **어떻게:** `watchdog.sh --start` (launch.sh가 자동 호출) / `watchdog.sh --stop`

## 수용 기준
- [ ] `watchdog.sh` 스크립트 구현 (백그라운드 실행, 60초 간격 헬스체크)
- [ ] 에이전트 비정상 종료 감지 시 10초 후 자동 재시작
- [ ] PID 파일 기반 프로세스 생존 확인
- [ ] 시간당 3회 초과 크래시 시 BOARD.md에 FREEZE 삽입
- [ ] 크래시 이력을 CRASH-AGENT.md에 기록
- [ ] Windows/macOS/Linux 크로스플랫폼 동작
- [ ] `launch.sh --stop`으로 watchdog도 함께 종료
