# SPEC-R-022: 에이전트 로그 검색 도구

**관련 태스크:** R-022
**작성일:** 2026-04-13

---

## 개요
키워드, 날짜 범위, 에이전트 유형별로 오케스트레이션 로그를 검색하고 결과를 포맷팅하는 CLI 도구.

## 상세 설명
오케스트레이션 로그가 누적되면 과거 이벤트를 찾기 어려워진다. 키워드 검색, 날짜 범위 필터, 에이전트 유형 필터, 이벤트 유형 필터(커밋, 리뷰, 에러, 토론 등)를 조합하여 로그를 검색하고, 결과를 구조화된 형태로 출력하는 CLI 도구를 구현한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 검색 대상 | orchestration/logs/*.md | 에이전트 로그 |
| 추가 검색 대상 | BOARD.md, reviews/, decisions/, discussions/ | 선택적 확장 |
| 필터 | 키워드, 날짜 범위, 에이전트, 이벤트 유형 | AND 조합 |
| 출력 포맷 | 터미널 (컬러) / Markdown / JSON | 사용자 선택 |
| 최대 결과 수 | 100건 (기본) | --limit으로 조절 |

## 데이터 구조
```bash
# search-logs.sh 인터페이스
search-logs.sh --keyword "NEEDS_WORK" --agent CLIENT --after 2026-04-01
search-logs.sh --keyword "NullReference" --type error --format json
search-logs.sh --agent DEVELOPER --after 2026-04-10 --before 2026-04-13
search-logs.sh --keyword "TASK-037" --all  # 전체 오케스트레이션 파일 검색
```

```json
// JSON 출력 예시
{
  "results": [
    {
      "file": "orchestration/logs/CLIENT.md",
      "line": 42,
      "timestamp": "2026-04-13T14:30:00",
      "agent": "CLIENT",
      "content": "REVIEW-037-v1.md 작성 완료: NEEDS_WORK (UI 진입점 누락)",
      "context": ["(전후 2줄)"]
    }
  ],
  "total": 3,
  "query": {"keyword": "NEEDS_WORK", "agent": "CLIENT"}
}
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| search-logs.sh | orchestration/logs/*.md | grep + 날짜 파싱 |
| search-logs.sh | orchestration/reviews/*.md | 확장 검색 시 |
| search-logs.sh | orchestration/decisions/*.md | 확장 검색 시 |
| search-logs.sh | BOARD.md | 확장 검색 시 |
| orchestration-tools.bat | search-logs.sh | 메뉴 연동 (향후) |

## UI 와이어프레임
```
$ ./search-logs.sh --keyword "NEEDS_WORK" --after 2026-04-10

[검색] 키워드: "NEEDS_WORK" | 기간: 2026-04-10 ~ | 에이전트: ALL

  CLIENT.md:42 [2026-04-13 14:30]
    REVIEW-037-v1.md 작성 완료: NEEDS_WORK (UI 진입점 누락)

  COORDINATOR.md:88 [2026-04-13 14:31]
    TASK-037 → Rejected 이동 (NEEDS_WORK 판정)

  DEVELOPER.md:95 [2026-04-13 14:35]
    TASK-037 리워크 시작: NEEDS_WORK 항목 수정

결과: 3건 발견
```

## 호출 진입점
- **어디서:** 터미널에서 직접 실행
- **어떻게:** `./search-logs.sh [OPTIONS]`

## 수용 기준
- [ ] `search-logs.sh` 스크립트 구현
- [ ] 키워드 검색 (정규식 지원)
- [ ] 날짜 범위 필터 (--after, --before)
- [ ] 에이전트 유형 필터 (--agent)
- [ ] 컬러 터미널 출력 (기본)
- [ ] JSON 출력 옵션 (--format json)
- [ ] --all 옵션으로 전체 오케스트레이션 파일 검색
- [ ] 결과 건수 제한 (--limit)
- [ ] 검색 결과 전후 컨텍스트 표시 (--context N)
