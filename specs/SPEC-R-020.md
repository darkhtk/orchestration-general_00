# SPEC-R-020: API 비용 추적

**관련 태스크:** R-020
**작성일:** 2026-04-13

---

## 개요
에이전트별 Claude API 사용량(토큰/비용)을 실시간 추적하고 일일/누적 리포트를 생성하는 비용 모니터.

## 상세 설명
4개 에이전트가 Claude API를 지속적으로 호출하므로 비용이 빠르게 누적될 수 있다. 에이전트별 API 호출 횟수, 입출력 토큰 수, 추정 비용을 추적하고, 일일/주간/누적 비용 리포트를 생성한다. 예산 한도를 설정하여 초과 시 경고 또는 자동 FREEZE를 트리거할 수 있다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 추적 데이터 | 호출 수, input tokens, output tokens | 에이전트별 |
| 비용 계산 | Anthropic 공식 가격표 기준 | 모델별 단가 |
| 비용 로그 경로 | `orchestration/logs/COST-YYYY-MM-DD.csv` | 일별 CSV |
| 리포트 경로 | `orchestration/logs/COST-REPORT.md` | 누적 요약 |
| 예산 경고 | project.config.md `daily_budget_usd` | 기본 $10/일 |
| 예산 초과 시 | FREEZE 삽입 + 알림 | 선택적 |
| 데이터 소스 | Claude CLI 출력 파싱 또는 API 응답 헤더 | usage 필드 |

## 데이터 구조
```csv
# orchestration/logs/COST-2026-04-13.csv
timestamp,agent,model,input_tokens,output_tokens,cost_usd
2026-04-13T14:00:00,SUPERVISOR,claude-sonnet-4-20250514,15000,3000,0.087
2026-04-13T14:02:00,DEVELOPER,claude-sonnet-4-20250514,12000,5000,0.081
...
```

```markdown
# orchestration/logs/COST-REPORT.md
## 비용 추적 리포트

### 오늘 (2026-04-13)
| 에이전트 | 호출 수 | Input 토큰 | Output 토큰 | 비용(USD) |
|----------|--------|-----------|------------|----------|
| SUPERVISOR | 45 | 675K | 135K | $3.92 |
| DEVELOPER | 48 | 576K | 240K | $3.89 |
| CLIENT | 42 | 630K | 168K | $3.68 |
| COORDINATOR | 47 | 470K | 141K | $2.83 |
| **합계** | **182** | **2,351K** | **684K** | **$14.32** |

### 누적 (2026-04-07 ~ 13)
| 일자 | 합계 비용 |
|------|----------|
| 04-07 | $12.50 |
| 04-08 | $15.30 |
| ... | ... |
| **주간 합계** | **$98.20** |
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| 에이전트 runner | COST-*.csv | API 응답에서 usage 추출 → CSV 기록 |
| cost-report.sh | COST-*.csv | CSV 파싱 → 리포트 생성 |
| cost-report.sh | COST-REPORT.md | 요약 리포트 |
| cost-report.sh | BOARD.md | 예산 초과 시 FREEZE 삽입 |
| project.config.md | cost-report.sh | 예산 한도 읽기 |
| daily-report.sh (R-019) | cost-report.sh | 일일 리포트에 비용 포함 |

## UI 와이어프레임
```
$ ./cost-report.sh --today

[비용] 오늘 사용량 집계 중...
[비용] SUPERVISOR: 45회, 675K+135K tokens, $3.92
[비용] DEVELOPER:  48회, 576K+240K tokens, $3.89
[비용] CLIENT:     42회, 630K+168K tokens, $3.68
[비용] COORDINATOR: 47회, 470K+141K tokens, $2.83
[비용] 합계: $14.32 / 예산 $20.00 (71.6%)

⚠️ 예산 71.6% 소진 — 일일 예산 내 잔여 $5.68

리포트: orchestration/logs/COST-REPORT.md
```

## 호출 진입점
- **어디서:** Coordinator 루프 (일일 집계) 또는 터미널 수동 실행
- **어떻게:** `./cost-report.sh --today` 또는 `--week` 또는 `--total`

## 수용 기준
- [ ] 에이전트 runner에서 API 응답 usage 추출 → CSV 기록 로직
- [ ] `cost-report.sh` 스크립트 구현 (CSV → 리포트)
- [ ] 에이전트별/일별/주간/누적 비용 계산
- [ ] Markdown 형식 COST-REPORT.md 생성
- [ ] project.config.md에서 일일 예산 한도 설정 가능
- [ ] 예산 초과 시 경고 알림 (R-018 연동)
- [ ] 선택적 FREEZE 자동 삽입 (예산 초과 정책 설정 가능)
- [ ] Claude CLI 출력에서 usage 파싱 가능 여부 확인 및 폴백
