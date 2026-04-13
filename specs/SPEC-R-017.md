# SPEC-R-017: 에이전트 로그 실시간 스트리밍 뷰

**관련 태스크:** R-017
**작성일:** 2026-04-13

---

## 개요
에이전트별 로그를 실시간으로 tail하며 필터링/검색할 수 있는 터미널 스트리밍 뷰.

## 상세 설명
R-016(TUI 대시보드)의 보완 기능으로, 특정 에이전트의 로그를 상세하게 실시간 스트리밍하는 전용 뷰를 제공한다. `tail -f`와 유사하지만, 에이전트 선택, 키워드 필터, 에러 하이라이팅, 여러 에이전트 동시 스트리밍(멀티플렉스) 기능을 추가한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 갱신 주기 | 1초 | 실시간 tail |
| 버퍼 크기 | 최신 500줄 | 메모리 내 유지 |
| 필터 지원 | 키워드, 에러 레벨, 에이전트명 | 실시간 적용 |
| 하이라이팅 | ERROR=빨강, WARNING=노랑, 커밋=초록 | ANSI 색상 |
| 동시 스트림 | 최대 4개 (전체 에이전트) | 분할 또는 인터리브 |

## 데이터 구조
```bash
# log-stream.sh 옵션
--agent SUPERVISOR|DEVELOPER|CLIENT|COORDINATOR|ALL
--filter "keyword"
--level ERROR|WARNING|INFO|ALL
--format split|interleave  # 분할 뷰 또는 혼합 뷰
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| log-stream.sh | orchestration/logs/SUPERVISOR.md | tail -f 또는 inotifywait |
| log-stream.sh | orchestration/logs/DEVELOPER.md | tail -f |
| log-stream.sh | orchestration/logs/CLIENT.md | tail -f |
| log-stream.sh | orchestration/logs/COORDINATOR.md | tail -f |
| dashboard.py (R-016) | log-stream | 상세 뷰 전환 시 호출 |

## UI 와이어프레임
```
$ ./log-stream.sh --agent ALL --format interleave

[14:30:15] [SUP] 🔍 코드 감사 시작: PlayerController.cs
[14:30:16] [DEV] 📝 TASK-037 구현 중: SortInventory() 메서드 작성
[14:30:18] [DEV] ✅ 테스트 통과: InventorySort_ByName_ReturnsAlphabetical
[14:30:20] [CLI] 👀 REVIEW-037 검증 1: 코드 추적 시작
[14:30:22] [SUP] ⚠️ WARNING: MainMenu.cs 미사용 using 문 발견
[14:30:25] [COR] 📊 BOARD 동기화: 로드맵 vs 활성 섹션 일치 확인

-- [/] 검색  [f] 필터  [1-4] 에이전트 선택  [q] 종료 --
```

## 호출 진입점
- **어디서:** 터미널에서 직접 실행 또는 R-016 대시보드에서 전환
- **어떻게:** `./log-stream.sh --agent DEVELOPER` 또는 대시보드에서 숫자키

## 수용 기준
- [ ] `log-stream.sh` 스크립트 구현 (또는 Python 스크립트)
- [ ] 단일 에이전트 로그 실시간 스트리밍
- [ ] 전체 에이전트 인터리브 스트리밍
- [ ] 키워드 필터링 (`--filter`)
- [ ] 에러 레벨별 컬러 하이라이팅
- [ ] 에이전트별 색상 구분 (SUP=파랑, DEV=초록, CLI=노랑, COR=보라)
- [ ] R-016 대시보드에서 상세 뷰 전환 가능
- [ ] Windows/macOS/Linux 크로스플랫폼 동작
