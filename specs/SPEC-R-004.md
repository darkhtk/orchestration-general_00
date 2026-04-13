# SPEC-R-004: add-feature.sh SPEC 자동 생성 연동

**관련 태스크:** R-004
**작성일:** 2026-04-13

---

## 개요
자연어 기능 요청 → TASK 변환 후 SPEC-XXX.md까지 자동 생성하는 add-feature 파이프라인 완성.

## 상세 설명
현재 add-feature.sh는 자연어 입력을 TASK 문서로 변환하는 기능까지 구현되어 있으나, 해당 TASK에 대응하는 SPEC 파일 자동 생성이 미완성이다. Claude 프롬프트를 확장하여 TASK 생성 직후 SPEC-TEMPLATE.md 기반의 기획서를 함께 생성하고, 복수 태스크로 분할이 필요한 경우 각각의 SPEC을 생성하도록 한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| SPEC 생성 트리거 | TASK 생성 직후 | 같은 Claude 세션에서 연속 실행 |
| SPEC 템플릿 | framework/templates/SPEC-TEMPLATE.md | 기존 템플릿 활용 |
| 복수 태스크 분할 기준 | 독립적으로 구현/테스트 가능한 단위 | Claude가 판단 |
| 최대 분할 수 | 5건 | 과도한 분할 방지 |

## 데이터 구조
```bash
# add-feature.sh 출력 구조 (확장)
orchestration/tasks/TASK-042.md     # 기존: TASK 문서
orchestration/specs/SPEC-042.md     # 신규: SPEC 문서 (자동 생성)
# 복수 분할 시:
orchestration/tasks/TASK-042a.md
orchestration/tasks/TASK-042b.md
orchestration/specs/SPEC-042a.md
orchestration/specs/SPEC-042b.md
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| add-feature.sh | Claude CLI | 프롬프트 전달 (TASK + SPEC 동시 생성) |
| add-feature.sh | BACKLOG_RESERVE.md | 생성된 태스크 등록 |
| add-feature.sh | orchestration/specs/ | SPEC 파일 저장 |
| Claude 프롬프트 | SPEC-TEMPLATE.md | 템플릿 구조 참조 |

## UI 와이어프레임
```
$ ./add-feature.sh "인벤토리에 아이템 정렬 기능 추가"

[1/3] 기능 분석 중...
[2/3] TASK 생성: TASK-042.md (인벤토리 아이템 정렬)
[3/3] SPEC 생성: SPEC-042.md (수치/UI/데이터 구조 포함)

✅ BACKLOG_RESERVE.md에 R-042 등록 완료
   - orchestration/tasks/TASK-042.md
   - orchestration/specs/SPEC-042.md
```

## 호출 진입점
- **어디서:** 터미널 CLI 또는 orchestration-tools.bat 메뉴 6번
- **어떻게:** `./add-feature.sh "자연어 기능 설명"` 또는 `add-feature.bat`

## 수용 기준
- [ ] add-feature.sh에서 TASK 생성 후 SPEC 자동 생성까지 연속 실행
- [ ] 생성된 SPEC이 SPEC-TEMPLATE.md 구조를 준수 (수치/데이터/연동/UI/진입점/수용기준)
- [ ] 복수 태스크 분할 시 각각의 SPEC 생성
- [ ] BACKLOG_RESERVE.md에 `specs/SPEC-XXX.md 참조` 문구 포함
- [ ] 기존 TASK-only 모드와 호환 유지 (--no-spec 옵션)
- [ ] 에러 발생 시 TASK만 생성하고 SPEC 실패 로그 출력 (부분 실패 허용)
