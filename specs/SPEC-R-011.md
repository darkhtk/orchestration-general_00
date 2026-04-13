# SPEC-R-011: Gmail API/CLI 메일 통합

**관련 태스크:** R-011
**작성일:** 2026-04-13

---

## 개요
Coordinator Step 5의 메일 점검 기능을 실제 Gmail API 또는 CLI로 연동하여 외부 피드백을 BOARD/RESERVE에 반영.

## 상세 설명
현재 Coordinator 프롬프트의 Step 5(메일 점검)는 Gmail subject 검색을 참조하지만 실제 API/CLI 연동이 없는 스켈레톤 상태이다. Google Gmail API(OAuth2) 또는 CLI 도구(예: `gmail-cli`, `msmtp`)를 통해 특정 subject 패턴의 이메일을 검색하고, 내용을 파싱하여 기능 요청/버그 리포트/피드백을 BOARD 또는 RESERVE에 자동 반영하는 파이프라인을 구현한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 메일 체크 주기 | project.config.md의 `email_check_interval` | 기본 30분 |
| 검색 subject | project.config.md의 `email_subject` | 예: "[ProjectName]" |
| 인증 방식 | OAuth2 (Gmail API) 또는 App Password | 사용자 선택 |
| 토큰 저장 | `orchestration/.gmail_token.json` | .gitignore 등록 |
| 메일→태스크 변환 | Claude 프롬프트 | 자연어 → TASK/RESERVE 항목 |
| 처리 완료 라벨 | `orchestration-processed` | Gmail 라벨로 중복 방지 |

## 데이터 구조
```bash
# 메일 체크 스크립트 출력
check-mail.sh --config orchestration/project.config.md
# 결과:
# [MAIL] 3건 발견 (subject: [MyGame])
# [MAIL] #1: "인벤토리 정렬 기능 추가 요청" → RESERVE R-043 등록
# [MAIL] #2: "로그인 화면 크래시 보고" → BOARD P0 등록
# [MAIL] #3: "UI 색상 변경 제안" → RESERVE R-044 등록

# orchestration/.gmail_config.json
{
  "auth_type": "oauth2",
  "client_id": "...",
  "token_path": "orchestration/.gmail_token.json",
  "search_subject": "[MyGame]",
  "check_interval_minutes": 30,
  "processed_label": "orchestration-processed"
}
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| Coordinator 프롬프트 (Step 5) | check-mail.sh | 스크립트 실행 |
| check-mail.sh | Gmail API | REST API (OAuth2) |
| check-mail.sh | Claude CLI | 메일 내용 → 태스크 변환 |
| check-mail.sh | BOARD.md / BACKLOG_RESERVE.md | 태스크 등록 |
| project.config.md | check-mail.sh | 메일 설정 읽기 |

## UI 와이어프레임
```
$ ./check-mail.sh --config orchestration/project.config.md

[메일] Gmail 연결 중...
[메일] Subject "[MyGame]" 검색: 3건 발견
[메일] #1 "인벤토리 정렬 요청" → RESERVE R-043 등록
[메일] #2 "로그인 크래시" → BOARD P0 TASK-043 등록
[메일] #3 "UI 색상 제안" → RESERVE R-044 등록
[메일] 처리 완료 라벨 적용: 3건
```

## 호출 진입점
- **어디서:** Coordinator 루프 Step 5
- **어떻게:** `./check-mail.sh --config orchestration/project.config.md`

## 수용 기준
- [ ] Gmail OAuth2 인증 설정 스크립트 (`setup-gmail.sh`) 구현
- [ ] 특정 subject 패턴 메일 검색 기능 구현
- [ ] 메일 내용 → TASK/RESERVE 항목 자동 변환 (Claude 프롬프트 활용)
- [ ] 처리 완료 메일에 라벨 적용 (중복 처리 방지)
- [ ] 인증 토큰을 .gitignore에 등록 (보안)
- [ ] Gmail API 미설정 시 graceful skip (기존 동작 유지)
- [ ] project.config.md에 메일 설정 섹션 문서화
