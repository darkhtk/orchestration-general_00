# SPEC-R-019: 에이전트 실행 통계 / 일일 리포트

**관련 태스크:** R-019
**작성일:** 2026-04-13

---

## 개요
에이전트별 루프 횟수, 태스크 완료 수, APPROVE/REJECT 비율, 평균 처리 시간 등을 집계하는 일일 리포트 생성기.

## 상세 설명
오케스트레이션 효율을 정량적으로 파악하기 위해, 에이전트 로그와 BOARD 이력을 분석하여 일일 통계 리포트를 자동 생성한다. 에이전트별 활동량, 태스크 처리 속도, 리뷰 통과율, 병목 구간 등을 계산하여 Markdown 리포트로 출력한다. Coordinator 루프에서 1일 1회 자동 생성하거나 수동 실행할 수 있다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 생성 주기 | 1일 1회 (자동) 또는 수동 | 날짜별 리포트 |
| 리포트 경로 | `orchestration/logs/DAILY-REPORT-YYYY-MM-DD.md` | 날짜별 파일 |
| 보관 기간 | 30일 | 초과 시 자동 삭제 |
| 통계 항목 | 루프 수, 태스크 수, 시간, 비율 | 에이전트별 + 전체 |

## 데이터 구조
```markdown
# orchestration/logs/DAILY-REPORT-2026-04-13.md
## 일일 오케스트레이션 리포트 — 2026-04-13

### 전체 요약
| 항목 | 값 |
|------|---|
| 총 루프 수 | 182 (SUP:45, DEV:48, CLI:42, COR:47) |
| 태스크 완료 | 5건 (TASK-033~037) |
| 태스크 Rejected | 1건 (TASK-035 → 리워크 후 통과) |
| APPROVE 비율 | 83% (5/6 리뷰) |
| 평균 태스크 처리 시간 | 2시간 15분 |
| CRITICAL 에러 | 0건 |
| RESERVE 잔여 | 18건 |

### 에이전트별 상세
#### Supervisor
| 항목 | 값 |
|------|---|
| 루프 수 | 45 |
| 에셋 생성 | 3건 |
| 코드 감사 수정 | 7건 |
| DECISION 작성 | 6건 |

#### Developer
| 항목 | 값 |
|------|---|
| 루프 수 | 48 |
| 태스크 완료 | 5건 |
| 커밋 수 | 8건 |
| 리워크 | 1건 |

#### Client
| 항목 | 값 |
|------|---|
| 루프 수 | 42 |
| 리뷰 작성 | 6건 |
| APPROVE | 5건 |
| NEEDS_WORK | 1건 |
| 깊은 리뷰 | 1건 |

#### Coordinator
| 항목 | 값 |
|------|---|
| 루프 수 | 47 |
| BOARD 동기화 수정 | 3건 |
| SPEC 작성 | 2건 |
| RESERVE 보충 | 5건 |
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| daily-report.sh | orchestration/logs/*.md | 에이전트 로그 파싱 |
| daily-report.sh | BOARD.md | 태스크 상태 집계 |
| daily-report.sh | orchestration/reviews/ | 리뷰 결과 집계 |
| daily-report.sh | git log | 커밋 수 / 날짜별 필터 |
| daily-report.sh | DAILY-REPORT-*.md | 리포트 생성 |
| Coordinator 프롬프트 | daily-report.sh | 1일 1회 실행 |

## UI 와이어프레임
```
$ ./daily-report.sh --date 2026-04-13

[리포트] 2026-04-13 일일 리포트 생성 중...
[리포트] 에이전트 로그 분석: 182 루프
[리포트] BOARD 분석: 5 완료, 1 Rejected
[리포트] 리뷰 분석: 83% APPROVE 비율

✅ 리포트 생성: orchestration/logs/DAILY-REPORT-2026-04-13.md
```

## 호출 진입점
- **어디서:** Coordinator 루프 (1일 1회) 또는 터미널 수동 실행
- **어떻게:** `./daily-report.sh --date YYYY-MM-DD` 또는 `--today`

## 수용 기준
- [ ] `daily-report.sh` 스크립트 구현
- [ ] 에이전트별 루프 횟수 집계
- [ ] 태스크 완료/Rejected 수 집계
- [ ] APPROVE/NEEDS_WORK 비율 계산
- [ ] 평균 태스크 처리 시간 계산
- [ ] CRITICAL 에러 발생 건수 집계
- [ ] Markdown 형식 리포트 파일 생성
- [ ] 30일 초과 리포트 자동 삭제
- [ ] 데이터 부족 시 (로그 없음 등) 부분 리포트 생성 + 안내
