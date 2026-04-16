#!/bin/bash

# BOARD.md 동시 수정 충돌 방지를 위한 파일 잠금 메커니즘
# SPEC-R-001 구현

# 설정값
LOCK_FILE="orchestration/.board.lock"
LOCK_TIMEOUT=30  # 30초 타임아웃
RETRY_INTERVAL=2  # 2초 재시도 간격
MAX_RETRIES=10    # 최대 10회 재시도

# 로그 함수
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >&2
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $1" >&2
}

log_critical() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CRITICAL: $1" >&2
}

# stale lock 확인 및 제거 함수
remove_stale_lock() {
    if [ ! -f "$LOCK_FILE" ]; then
        return 0
    fi

    # lock 파일의 타임스탬프 추출
    local lock_timestamp
    lock_timestamp=$(grep "^TIMESTAMP=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)

    if [ -z "$lock_timestamp" ]; then
        log_warn "잘못된 형식의 lock 파일 발견, 제거합니다: $LOCK_FILE"
        rm -f "$LOCK_FILE"
        return 0
    fi

    # 현재 시간과 lock 시간 비교 (초 단위)
    local current_time
    local lock_time
    current_time=$(date +%s)
    lock_time=$(date -d "$lock_timestamp" +%s 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_warn "lock 파일의 타임스탬프 파싱 실패, 제거합니다: $LOCK_FILE"
        rm -f "$LOCK_FILE"
        return 0
    fi

    local age=$((current_time - lock_time))
    if [ $age -gt $LOCK_TIMEOUT ]; then
        local agent
        local pid
        agent=$(grep "^AGENT=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)
        pid=$(grep "^PID=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)
        log_warn "stale lock 감지 (${age}초 경과), 제거합니다: AGENT=$agent PID=$pid"
        rm -f "$LOCK_FILE"
        return 0
    fi

    return 1
}

# BOARD.md 잠금 획득 함수
acquire_lock() {
    local agent_name="$1"

    if [ -z "$agent_name" ]; then
        log_critical "acquire_lock: 에이전트명이 지정되지 않았습니다"
        return 1
    fi

    local retry_count=0

    while [ $retry_count -lt $MAX_RETRIES ]; do
        # stale lock 제거 시도
        remove_stale_lock

        # atomic lock 생성 시도 (exclusive file creation)
        if (set -C; echo "AGENT=$agent_name
PID=$$
TIMESTAMP=$(date -Iseconds)" > "$LOCK_FILE") 2>/dev/null; then
            log_info "BOARD.md 잠금 획득 성공: $agent_name (PID=$$)"
            return 0
        fi

        # 잠금 획득 실패
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_info "BOARD_LOCK_WAIT: 잠금 대기 중... ($retry_count/$MAX_RETRIES)"
            sleep $RETRY_INTERVAL
        fi
    done

    # 최대 재시도 횟수 초과
    log_critical "BOARD_LOCK_TIMEOUT: 최대 재시도 횟수 초과, BOARD.md 잠금 획득 실패: $agent_name"
    return 1
}

# BOARD.md 잠금 해제 함수
release_lock() {
    local agent_name="$1"

    if [ ! -f "$LOCK_FILE" ]; then
        log_warn "release_lock: 잠금 파일이 존재하지 않습니다"
        return 0
    fi

    # 현재 프로세스가 잠금을 소유하는지 확인
    local lock_agent
    local lock_pid
    lock_agent=$(grep "^AGENT=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)
    lock_pid=$(grep "^PID=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)

    if [ "$lock_agent" != "$agent_name" ] || [ "$lock_pid" != "$$" ]; then
        log_warn "release_lock: 다른 프로세스의 잠금을 해제하려고 시도함 (소유자: $lock_agent PID=$lock_pid, 요청자: $agent_name PID=$$)"
        return 1
    fi

    # 잠금 해제
    rm -f "$LOCK_FILE"
    log_info "BOARD.md 잠금 해제 완료: $agent_name (PID=$$)"
    return 0
}

# 잠금 상태 확인 함수
check_lock() {
    if [ ! -f "$LOCK_FILE" ]; then
        echo "BOARD.md 잠금 상태: 해제됨"
        return 0
    fi

    local agent
    local pid
    local timestamp
    agent=$(grep "^AGENT=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)
    pid=$(grep "^PID=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)
    timestamp=$(grep "^TIMESTAMP=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)

    echo "BOARD.md 잠금 상태: 잠김"
    echo "  에이전트: $agent"
    echo "  PID: $pid"
    echo "  잠금 시간: $timestamp"

    # stale 여부 확인
    local current_time
    local lock_time
    current_time=$(date +%s)
    lock_time=$(date -d "$timestamp" +%s 2>/dev/null)

    if [ $? -eq 0 ]; then
        local age=$((current_time - lock_time))
        echo "  경과 시간: ${age}초"
        if [ $age -gt $LOCK_TIMEOUT ]; then
            echo "  상태: STALE (${LOCK_TIMEOUT}초 초과)"
        else
            echo "  상태: ACTIVE"
        fi
    fi
}

# CLI 인터페이스
case "$1" in
    "acquire")
        acquire_lock "$2"
        ;;
    "release")
        release_lock "$2"
        ;;
    "check")
        check_lock
        ;;
    "clean")
        remove_stale_lock
        echo "stale lock 정리 완료"
        ;;
    *)
        echo "사용법: $0 {acquire|release|check|clean} [AGENT_NAME]"
        echo ""
        echo "명령어:"
        echo "  acquire AGENT_NAME  - BOARD.md 잠금 획득"
        echo "  release AGENT_NAME  - BOARD.md 잠금 해제"
        echo "  check              - 현재 잠금 상태 확인"
        echo "  clean              - stale lock 정리"
        echo ""
        echo "예제:"
        echo "  source $0"
        echo "  acquire_lock COORDINATOR"
        echo "  # BOARD.md 수정 작업"
        echo "  release_lock COORDINATOR"
        exit 1
        ;;
esac