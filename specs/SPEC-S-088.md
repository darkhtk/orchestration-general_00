# SPEC-S-088: 에이전트 실행 통계 요약 일일 리포트 기능

> **태스크 ID:** S-088
> **우선순위:** P3
> **관련 BACKLOG_RESERVE:** R-019
> **작성일:** 2026-04-16

## 목표

에이전트별 루프 횟수, 태스크 완료 수, APPROVE/REJECT 비율, 평균 처리 시간 등을 집계하는 일일 리포트 생성기를 구현한다.

## 요구사항

### 1. 통계 수집 데이터

#### 1.1 에이전트별 기본 통계
- **루프 실행 횟수**: 하루 동안 몇 번 실행되었는지
- **평균 실행 시간**: 루프 한 번당 평균 소요시간
- **마지막 실행 시간**: 가장 최근 실행 시각
- **에러 발생 횟수**: 실행 중 에러가 발생한 횟수

#### 1.2 SUPERVISOR 특화 통계
- **태스크 검토 횟수**: Review 상태 태스크 검토 횟수
- **APPROVE 비율**: 승인된 태스크 / 전체 검토 태스크
- **REJECT 비율**: 거부된 태스크 / 전체 검토 태스크
- **평균 검토 시간**: 검토 완료까지 평균 시간

#### 1.3 DEVELOPER 특화 통계
- **구현 완료 태스크 수**: Done으로 이동한 태스크 수
- **구현 실패 태스크 수**: 구현 중 실패한 태스크 수
- **평균 구현 시간**: 태스크 하나당 평균 구현 시간
- **코드 라인 변경량**: git diff 기반 추가/삭제 라인 수

#### 1.4 CLIENT 특화 통계
- **검증 실행 횟수**: 검증 단계별 실행 횟수
- **검증 통과 비율**: 성공한 검증 / 전체 검증 시도
- **엔진 연결 성공률**: MCP 연결 성공 / 연결 시도
- **빌드 성공률**: 빌드 성공 / 빌드 시도

#### 1.5 COORDINATOR 특화 통계
- **BOARD 업데이트 횟수**: BOARD.md 수정 횟수
- **BACKLOG 보충 횟수**: RESERVE에서 태스크 추가 횟수
- **이메일 처리 횟수**: 메일 체크 및 태스크 변환 횟수
- **우선순위 조정 횟수**: 태스크 우선순위 변경 횟수

### 2. 로그 파싱 로직

#### 2.1 로그 파일 위치
- `orchestration/logs/SUPERVISOR.md`
- `orchestration/logs/DEVELOPER.md`
- `orchestration/logs/CLIENT.md`
- `orchestration/logs/COORDINATOR.md`

#### 2.2 파싱할 로그 패턴
```bash
# 실행 시작/종료 패턴
"=== SUPERVISOR 루프 시작 ==="
"=== SUPERVISOR 루프 완료 ==="

# 태스크 처리 패턴
"✅ 승인: S-XXX"
"❌ 거부: S-XXX"
"🔄 구현 완료: S-XXX"

# 에러 패턴
"ERROR:"
"FAILED:"
"Exception:"

# 시간 패턴
"[2026-04-16 10:30:45]"
```

### 3. 리포트 생성 스크립트

#### 3.1 scripts/generate-daily-report.sh 생성
```bash
#!/bin/bash
# 일일 리포트 생성 스크립트

REPORT_DATE=${1:-$(date +%Y-%m-%d)}
LOGS_DIR="orchestration/logs"
REPORTS_DIR="orchestration/reports"

mkdir -p "$REPORTS_DIR"

generate_agent_stats() {
    local agent=$1
    local log_file="$LOGS_DIR/${agent}.md"
    local today_logs=$(grep "^\[$REPORT_DATE" "$log_file" 2>/dev/null || echo "")

    # 루프 실행 횟수
    local loop_count=$(echo "$today_logs" | grep -c "루프 시작" || echo 0)

    # 에러 발생 횟수
    local error_count=$(echo "$today_logs" | grep -c "ERROR\|FAILED" || echo 0)

    # 마지막 실행 시간
    local last_run=$(echo "$today_logs" | tail -1 | grep -o '^\[[^]]*\]' | tr -d '[]' || echo "없음")

    echo "## $agent 통계"
    echo "- **루프 실행**: ${loop_count}회"
    echo "- **에러 발생**: ${error_count}회"
    echo "- **마지막 실행**: $last_run"
    echo ""
}

generate_supervisor_stats() {
    local log_file="$LOGS_DIR/SUPERVISOR.md"
    local today_logs=$(grep "^\[$REPORT_DATE" "$log_file" 2>/dev/null || echo "")

    local approve_count=$(echo "$today_logs" | grep -c "✅ 승인" || echo 0)
    local reject_count=$(echo "$today_logs" | grep -c "❌ 거부" || echo 0)
    local total_reviews=$((approve_count + reject_count))

    local approve_rate=0
    local reject_rate=0
    if [[ $total_reviews -gt 0 ]]; then
        approve_rate=$(( (approve_count * 100) / total_reviews ))
        reject_rate=$(( (reject_count * 100) / total_reviews ))
    fi

    echo "### SUPERVISOR 세부 통계"
    echo "- **총 검토**: ${total_reviews}건"
    echo "- **승인**: ${approve_count}건 (${approve_rate}%)"
    echo "- **거부**: ${reject_count}건 (${reject_rate}%)"
    echo ""
}

generate_developer_stats() {
    local log_file="$LOGS_DIR/DEVELOPER.md"
    local today_logs=$(grep "^\[$REPORT_DATE" "$log_file" 2>/dev/null || echo "")

    local completed_tasks=$(echo "$today_logs" | grep -c "🔄 구현 완료" || echo 0)
    local failed_tasks=$(echo "$today_logs" | grep -c "구현 실패" || echo 0)

    # git log에서 오늘 커밋 통계
    local commits_today=$(git log --since="$REPORT_DATE 00:00" --until="$REPORT_DATE 23:59" --oneline | wc -l || echo 0)
    local lines_added=$(git log --since="$REPORT_DATE 00:00" --until="$REPORT_DATE 23:59" --numstat | awk '{added+=$1} END {print added+0}')
    local lines_deleted=$(git log --since="$REPORT_DATE 00:00" --until="$REPORT_DATE 23:59" --numstat | awk '{deleted+=$2} END {print deleted+0}')

    echo "### DEVELOPER 세부 통계"
    echo "- **완료 태스크**: ${completed_tasks}건"
    echo "- **실패 태스크**: ${failed_tasks}건"
    echo "- **커밋 수**: ${commits_today}개"
    echo "- **코드 변경**: +${lines_added}/-${lines_deleted} 라인"
    echo ""
}

generate_client_stats() {
    local log_file="$LOGS_DIR/CLIENT.md"
    local today_logs=$(grep "^\[$REPORT_DATE" "$log_file" 2>/dev/null || echo "")

    local verification_attempts=$(echo "$today_logs" | grep -c "검증 [0-9]" || echo 0)
    local verification_success=$(echo "$today_logs" | grep -c "검증.*완료" || echo 0)
    local build_attempts=$(echo "$today_logs" | grep -c "빌드 시도" || echo 0)
    local build_success=$(echo "$today_logs" | grep -c "빌드 성공" || echo 0)

    local verification_rate=0
    local build_rate=0
    if [[ $verification_attempts -gt 0 ]]; then
        verification_rate=$(( (verification_success * 100) / verification_attempts ))
    fi
    if [[ $build_attempts -gt 0 ]]; then
        build_rate=$(( (build_success * 100) / build_attempts ))
    fi

    echo "### CLIENT 세부 통계"
    echo "- **검증 시도**: ${verification_attempts}회"
    echo "- **검증 성공률**: ${verification_rate}%"
    echo "- **빌드 시도**: ${build_attempts}회"
    echo "- **빌드 성공률**: ${build_rate}%"
    echo ""
}

generate_coordinator_stats() {
    local log_file="$LOGS_DIR/COORDINATOR.md"
    local today_logs=$(grep "^\[$REPORT_DATE" "$log_file" 2>/dev/null || echo "")

    local board_updates=$(echo "$today_logs" | grep -c "BOARD 업데이트" || echo 0)
    local backlog_refills=$(echo "$today_logs" | grep -c "BACKLOG 보충" || echo 0)
    local email_checks=$(echo "$today_logs" | grep -c "메일 체크" || echo 0)

    echo "### COORDINATOR 세부 통계"
    echo "- **BOARD 업데이트**: ${board_updates}회"
    echo "- **BACKLOG 보충**: ${backlog_refills}회"
    echo "- **메일 체크**: ${email_checks}회"
    echo ""
}

# 메인 리포트 생성
main() {
    local report_file="$REPORTS_DIR/daily-report-$REPORT_DATE.md"

    cat > "$report_file" << EOF
# 일일 에이전트 활동 리포트

> **날짜:** $REPORT_DATE
> **생성 시간:** $(date '+%Y-%m-%d %H:%M:%S')

---

EOF

    # 각 에이전트 통계 추가
    generate_agent_stats "SUPERVISOR" >> "$report_file"
    generate_supervisor_stats >> "$report_file"

    generate_agent_stats "DEVELOPER" >> "$report_file"
    generate_developer_stats >> "$report_file"

    generate_agent_stats "CLIENT" >> "$report_file"
    generate_client_stats >> "$report_file"

    generate_agent_stats "COORDINATOR" >> "$report_file"
    generate_coordinator_stats >> "$report_file"

    # BOARD 현황 스냅샷
    cat >> "$report_file" << EOF
## BOARD 현황 스냅샷

$(cat orchestration/BOARD.md | grep -A 20 "## 로드맵")

---

**리포트 생성:** \`scripts/generate-daily-report.sh\`
EOF

    echo "✅ 일일 리포트 생성 완료: $report_file"
}

main "$@"
```

### 4. 자동 실행 설정

#### 4.1 crontab 설정
```bash
# 매일 오후 11시 59분에 일일 리포트 생성
59 23 * * * cd /path/to/orchestration && ./scripts/generate-daily-report.sh
```

#### 4.2 COORDINATOR에 통합
COORDINATOR 에이전트의 Step 6에 리포트 생성 추가:
```bash
step_6_generate_daily_report() {
    local today=$(date +%Y-%m-%d)
    local report_file="orchestration/reports/daily-report-$today.md"

    if [[ ! -f "$report_file" ]]; then
        log_coordinator "일일 리포트 생성 중..."
        ./scripts/generate-daily-report.sh
        log_coordinator "✅ 일일 리포트 생성 완료"
    else
        log_coordinator "오늘 리포트가 이미 존재합니다."
    fi
}
```

### 5. 리포트 출력 형식

#### 5.1 샘플 리포트
```markdown
# 일일 에이전트 활동 리포트

> **날짜:** 2026-04-16
> **생성 시간:** 2026-04-16 23:59:30

---

## SUPERVISOR 통계
- **루프 실행**: 24회
- **에러 발생**: 1회
- **마지막 실행**: 2026-04-16 23:45:00

### SUPERVISOR 세부 통계
- **총 검토**: 3건
- **승인**: 2건 (67%)
- **거부**: 1건 (33%)

## DEVELOPER 통계
- **루프 실행**: 18회
- **에러 발생**: 0회
- **마지막 실행**: 2026-04-16 23:30:00

### DEVELOPER 세부 통계
- **완료 태스크**: 2건
- **실패 태스크**: 0건
- **커밋 수**: 5개
- **코드 변경**: +247/-89 라인

...
```

### 6. 주간/월간 리포트 확장

#### 6.1 주간 리포트 생성
```bash
# scripts/generate-weekly-report.sh
generate_weekly_summary() {
    local week_start=$(date -d "monday-1week" +%Y-%m-%d)
    local week_end=$(date -d "sunday" +%Y-%m-%d)

    # 해당 주의 일일 리포트들을 집계
    aggregate_weekly_stats "$week_start" "$week_end"
}
```

## 구현 파일
- `scripts/generate-daily-report.sh` 생성
- `scripts/generate-weekly-report.sh` 생성
- `orchestration/reports/` 디렉토리 생성
- `scripts/coordinator.sh` 수정

## 테스트 시나리오

1. **일일 리포트 생성 테스트**
   - 각 에이전트를 하루 동안 실행
   - 리포트 생성 스크립트 실행
   - 통계 정확성 확인

2. **에러 상황 테스트**
   - 로그 파일이 없는 경우
   - 빈 로그 파일인 경우
   - 잘못된 로그 형식인 경우

3. **자동 실행 테스트**
   - COORDINATOR에서 자동 리포트 생성
   - crontab 스케줄링 테스트

## 완료 기준
- [ ] 4개 에이전트별 통계 수집 구현
- [ ] 일일 리포트 자동 생성 스크립트 완성
- [ ] COORDINATOR 통합 및 자동 실행
- [ ] 로그 파싱 로직 안정성 확보
- [ ] 샘플 리포트 출력 정상 확인
- [ ] 주간 리포트 확장 기능 구현