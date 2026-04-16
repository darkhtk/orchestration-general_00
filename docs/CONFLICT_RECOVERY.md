# 에이전트 충돌 자동 복구 시스템

## 개요

여러 에이전트가 동시에 실행될 때 발생할 수 있는 충돌을 자동으로 감지하고 복구하는 시스템입니다.

## 주요 기능

### 1. 파일 잠금 충돌 감지 및 복구
- 중요 파일(`BOARD.md`, `BACKLOG_RESERVE.md`)의 스테일 잠금 감지
- 5분 이상 된 잠금 파일 자동 제거
- 다중 프로세스 쓰기 감지

### 2. 프로세스 데드락 해결
- I/O 대기 상태의 에이전트 프로세스 감지
- 강제 복구 모드에서 데드락 프로세스 종료

### 3. 중복 작업 방지
- 에이전트 로그 분석을 통한 중복 작업 감지
- 동일한 유형의 작업이 동시에 실행되는 경우 경고

### 4. 에이전트 상태 동기화
- 활성 에이전트 프로세스 추적
- 실시간 상태 모니터링

## 사용법

### 기본 체크 (1회 검사)
```bash
bash conflict-recovery.sh /path/to/project
# 또는
bash conflict-recovery.sh /path/to/project --check
```

### 지속적 감시 모드
```bash
bash conflict-recovery.sh /path/to/project --monitor
```

### 강제 복구 모드
```bash
bash conflict-recovery.sh /path/to/project --repair
```

## 자동 통합

### launch.sh와의 통합
- 2개 이상의 에이전트가 실행될 때 자동으로 충돌 복구 시스템이 백그라운드에서 시작됩니다.
- PID가 `orchestration/.locks/recovery.pid`에 저장됩니다.

### 로그 파일
- `orchestration/logs/RECOVERY.md`: 복구 이벤트 로그
- `orchestration/logs/RECOVERY.log`: 시스템 실행 로그

## 감지되는 충돌 유형

### 1. 스테일 잠금 (stale_lock)
```
stale_lock:/path/to/file:pid:300초
```
- **복구**: 잠금 파일 자동 제거

### 2. 다중 쓰기 (multiple_writers)
```
multiple_writers:/path/to/file:3
```
- **복구**: 경고 로그 (수동 개입 필요)

### 3. 중복 작업 (duplicate_keywords)
```
duplicate_keywords:5
```
- **복구**: 경고 로그 (에이전트 간 조율 필요)

### 4. I/O 대기 (io_wait)
```
io_wait:script_name:pid
```
- **복구**: 강제 복구 모드에서 프로세스 종료

## 구성 파일

### 잠금 디렉토리
- `orchestration/.locks/`: 잠금 파일 저장 위치

### 감시 대상 파일
- `orchestration/BOARD.md`
- `orchestration/BACKLOG_RESERVE.md`

### 에이전트 로그
- `orchestration/logs/DEVELOPER.md`
- `orchestration/logs/SUPERVISOR.md`
- `orchestration/logs/CLIENT.md`
- `orchestration/logs/COORDINATOR.md`

## 예시 시나리오

### 시나리오 1: 스테일 잠금 복구
```bash
$ bash conflict-recovery.sh . --check

🔍 충돌 검사 중...
  활성 에이전트: 2개
    - launch.sh:12345
    - monitor.sh:12346

📁 파일 잠금 충돌 검사...
  ⚠️  충돌 감지: stale_lock:BOARD.md:12340:320초
  복구: 스테일 잠금 제거: BOARD.md.lock

🔄 중복 작업 검사...
  ✅ 중복 작업 없음

🔒 데드락 검사...
  ✅ 데드락 없음

============================================
 검사 완료
============================================

  📊 총 이슈: 1개
  📝 상세 로그: orchestration/logs/RECOVERY.md
```

### 시나리오 2: 지속적 감시
```bash
$ bash conflict-recovery.sh . --monitor

👁️  에이전트 충돌 지속 감시 중... (Ctrl+C로 중지)

  📊 09:50:15 — 활성 에이전트: 3개, 이슈: 0개
  ⚠️  09:52:30 — 1개 충돌 감지
  복구: 자동 복구 시작: stale_lock
  정보: 스테일 잠금 제거: BOARD.md.lock
  📊 09:55:15 — 활성 에이전트: 3개, 이슈: 0개
```

## 문제 해결

### Q: 복구 시스템이 시작되지 않는 경우
A: `conflict-recovery.sh`에 실행 권한이 있는지 확인:
```bash
chmod +x conflict-recovery.sh
```

### Q: 잠금 파일이 계속 생성되는 경우
A: 에이전트 프로세스가 비정상 종료되었을 가능성이 있습니다. 강제 복구를 실행:
```bash
bash conflict-recovery.sh . --repair
```

### Q: 복구 로그가 너무 큰 경우
A: 1MB를 초과하면 자동으로 압축됩니다. 수동으로 정리하려면:
```bash
rm orchestration/logs/RECOVERY.md.*.gz
```

## 개발자 참고사항

### 새로운 감지 패턴 추가
`detect_*_conflicts()` 함수를 수정하여 새로운 유형의 충돌을 감지할 수 있습니다.

### 복구 로직 확장
`auto_recover()` 함수에 새로운 case문을 추가하여 복구 로직을 확장할 수 있습니다.

### 모니터링 간격 조정
`CHECK_INTERVAL` 변수를 수정하여 감시 주기를 조정할 수 있습니다 (기본: 10초).