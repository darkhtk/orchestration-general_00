# SPEC-R-013: CI/CD 파이프라인 통합

**관련 태스크:** R-013
**작성일:** 2026-04-13

---

## 개요
빌드/테스트 결과를 자동으로 BOARD에 반영하고, 실패 시 P0 태스크를 자동 생성하는 CI/CD 연동 파이프라인.

## 상세 설명
현재 오케스트레이션은 CI/CD와 분리되어 있어 빌드 실패나 테스트 실패가 자동으로 BOARD에 반영되지 않는다. GitHub Actions, GitLab CI, Jenkins 등 주요 CI 시스템의 빌드/테스트 결과를 웹훅 또는 폴링으로 수집하고, 실패 시 P0 태스크를 자동 생성하여 Developer가 즉시 대응하도록 한다. 성공 시에는 BOARD의 관련 태스크 비고에 빌드 상태를 기록한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 지원 CI | GitHub Actions (1차), GitLab CI, Jenkins | 단계적 지원 |
| 폴링 간격 | 5분 | CI 결과 확인 주기 |
| 빌드 실패 → 태스크 | P0 자동 생성 | TASK-CI-BUILD-YYYYMMDD |
| 테스트 실패 → 태스크 | P1 자동 생성 | TASK-CI-TEST-YYYYMMDD |
| 결과 기록 위치 | BOARD.md 비고 컬럼 | ✅ Build #42 / ❌ Build #43 |
| CI 설정 경로 | `orchestration/.ci_config.md` | CI 연동 설정 |

## 데이터 구조
```markdown
# orchestration/.ci_config.md
## CI/CD 설정
| 항목 | 값 |
|------|---|
| CI 시스템 | GitHub Actions |
| 저장소 | owner/repo |
| 빌드 워크플로우 | build.yml |
| 테스트 워크플로우 | test.yml |
| 폴링 간격 | 5분 |
| 자동 태스크 생성 | 활성 |

# 자동 생성 태스크 예시
# orchestration/tasks/TASK-CI-BUILD-20260413.md
## CI 빌드 실패 대응
- **우선순위:** P0
- **트리거:** GitHub Actions build.yml Run #43 실패
- **에러 로그:** (CI 로그 발췌)
- **관련 커밋:** abc1234
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| ci-monitor.sh | GitHub API (gh CLI) | `gh run list` / `gh run view` |
| ci-monitor.sh | BOARD.md | 빌드 상태 비고 기록 |
| ci-monitor.sh | orchestration/tasks/ | 실패 시 P0/P1 TASK 자동 생성 |
| ci-monitor.sh | BACKLOG_RESERVE.md | 실패 태스크 등록 |
| Coordinator | ci-monitor.sh | 루프 중 실행 |
| project.config.md | ci-monitor.sh | CI 설정 읽기 |

## UI 와이어프레임
```
$ ./ci-monitor.sh --check

[CI] GitHub Actions 확인 중...
[CI] build.yml: Run #43 ❌ 실패 (2분 전)
     에러: TypeScript compilation error in src/api/routes.ts:42
[CI] test.yml: Run #22 ✅ 성공

[CI] P0 태스크 자동 생성: TASK-CI-BUILD-20260413
[CI] BOARD.md 비고 업데이트: ❌ Build #43
```

## 호출 진입점
- **어디서:** Coordinator 루프에서 주기적 실행 또는 독립 cron
- **어떻게:** `./ci-monitor.sh --check --config orchestration/.ci_config.md`

## 수용 기준
- [ ] `ci-monitor.sh` 스크립트 구현 (gh CLI 기반 GitHub Actions 연동)
- [ ] 빌드 실패 시 P0 TASK 자동 생성 + BOARD 등록
- [ ] 테스트 실패 시 P1 TASK 자동 생성 + BOARD 등록
- [ ] 성공 시 BOARD 비고에 빌드 상태 기록
- [ ] CI 미설정 시 graceful skip
- [ ] 중복 태스크 방지 (같은 Run에 대해 1회만 생성)
- [ ] project.config.md 또는 .ci_config.md에 CI 설정 문서화
- [ ] GitHub Actions 이외 CI 시스템은 향후 확장 가능한 구조
