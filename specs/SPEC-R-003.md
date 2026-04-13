# SPEC-R-003: 에이전트 간 파일 수정 우선순위 조율

**관련 태스크:** R-003
**작성일:** 2026-04-13

---

## 개요
Supervisor와 Developer가 같은 소스코드 파일을 동시에 수정하는 edge case를 감지하고 회피하는 조율 로직.

## 상세 설명
현재 Supervisor는 코드 감사/품질 개선으로, Developer는 태스크 구현으로 같은 파일을 수정할 수 있다. Supervisor 프롬프트에 "Developer In Progress 파일 확인 후 다른 파일로 이동" 규칙이 있지만, 실시간 감지가 아닌 BOARD 읽기 시점 기준이라 타이밍 갭이 존재한다. 파일 수정 의도를 선언하는 매니페스트 파일을 도입하여 충돌을 사전 방지한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 매니페스트 경로 | `orchestration/.file_manifest.md` | 현재 수정 중인 파일 목록 |
| 매니페스트 갱신 주기 | 파일 수정 시작/종료 시 | 에이전트가 직접 갱신 |
| 충돌 감지 시 행동 | 해당 파일 스킵, 로그 기록 | 다른 파일로 이동 |
| 매니페스트 만료 시간 | 10분 | 에이전트 크래시 시 stale 항목 정리 |

## 데이터 구조
```markdown
# orchestration/.file_manifest.md
| 에이전트 | 파일 경로 | 시작 시각 | 작업 유형 |
|----------|----------|-----------|----------|
| DEVELOPER | Assets/Scripts/Player/PlayerController.cs | 2026-04-13T14:30:00 | 구현 |
| SUPERVISOR | Assets/Scripts/UI/MainMenu.cs | 2026-04-13T14:31:00 | 코드 감사 |
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| Developer 프롬프트 | .file_manifest.md | 구현 시작 시 파일 등록, 커밋 후 해제 |
| Supervisor 프롬프트 | .file_manifest.md | 코드 감사 시작 시 확인 + 등록 |
| Coordinator | .file_manifest.md | 10분 초과 stale 항목 정리 |
| board-lock.sh | .file_manifest.md | BOARD 잠금과 독립 운영 |

## UI 와이어프레임
N/A

## 호출 진입점
- **어디서:** 각 에이전트가 소스코드 파일 수정 직전
- **어떻게:** 매니페스트 파일 읽기 → 충돌 확인 → 없으면 등록 후 수정 시작

## 수용 기준
- [ ] `.file_manifest.md` 스펙 정의 및 생성
- [ ] Supervisor 프롬프트에 매니페스트 확인/등록 절차 추가
- [ ] Developer 프롬프트에 매니페스트 확인/등록 절차 추가
- [ ] Coordinator가 10분 초과 stale 항목 자동 정리
- [ ] 동일 파일 수정 시도 시 후순위 에이전트가 자동 스킵 + 로그 기록
- [ ] 매니페스트 파일이 git conflict를 유발하지 않도록 .gitignore에 추가
