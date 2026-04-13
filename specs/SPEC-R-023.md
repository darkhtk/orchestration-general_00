# SPEC-R-023: 다국어 프롬프트 (영어 전용 세트)

**관련 태스크:** R-023
**작성일:** 2026-04-13

---

## 개요
현재 한국어 중심 프롬프트를 영어 전용 프롬프트 세트로도 제공하여 비한국어권 사용자 지원.

## 상세 설명
현재 framework/prompts/*.txt와 framework/agents/*.md가 한국어로 작성되어 있어 비한국어권 사용자가 활용하기 어렵다. 영어 전용 프롬프트 세트를 별도로 제공하고, project.config.md에서 프롬프트 언어를 선택할 수 있도록 한다. 향후 추가 언어 지원을 위한 구조(i18n 디렉토리 체계)도 함께 설계한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 1차 지원 언어 | 한국어 (기존), 영어 | 2개 언어 |
| 프롬프트 파일 | framework/prompts/en/*.txt | 언어별 서브디렉토리 |
| 에이전트 역할 | framework/agents/en/*.md | 언어별 서브디렉토리 |
| 템플릿 | framework/templates/en/*.md | 언어별 서브디렉토리 |
| 언어 선택 | project.config.md `language: en` | 기본: ko |
| init.sh/launch.sh | 언어 설정에 따라 해당 언어 파일 복사 | 자동 분기 |

## 데이터 구조
```
framework/
├── prompts/
│   ├── SUPERVISOR.txt          # 한국어 (기존, 기본)
│   ├── DEVELOPER.txt
│   ├── CLIENT.txt
│   ├── COORDINATOR.txt
│   └── en/                     # 영어
│       ├── SUPERVISOR.txt
│       ├── DEVELOPER.txt
│       ├── CLIENT.txt
│       └── COORDINATOR.txt
├── agents/
│   ├── SUPERVISOR.md           # 한국어 (기존)
│   └── en/
│       ├── SUPERVISOR.md
│       ├── DEVELOPER.md
│       ├── CLIENT.md
│       └── COORDINATOR.md
└── templates/
    ├── BOARD-TEMPLATE.md       # 한국어 (기존)
    └── en/
        ├── BOARD-TEMPLATE.md
        ├── BACKLOG-TEMPLATE.md
        ├── TASK-TEMPLATE.md
        ├── SPEC-TEMPLATE.md
        ├── REVIEW-TEMPLATE.md
        ├── DECISION-TEMPLATE.md
        └── DISCUSS-TEMPLATE.md
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| project.config.md (`language`) | init.sh / launch.sh | 언어 설정 읽기 |
| init.sh | framework/prompts/en/ | 영어 선택 시 해당 경로에서 복사 |
| launch.sh | framework/prompts/en/ | 프롬프트 동기화 시 언어별 분기 |
| auto-setup.sh | project.config.md | language 필드 설정 (감지 또는 질문) |

## UI 와이어프레임
```
$ ./auto-setup.sh /path/to/project

...
[설정] 프롬프트 언어 선택:
  1. 한국어 (Korean) — 기본
  2. English
선택 (1/2): 2

[설정] language: en → project.config.md
```

## 호출 진입점
- **어디서:** auto-setup.sh (초기 설정 시) 또는 project.config.md 직접 수정
- **어떻게:** project.config.md에서 `language: en` 설정 후 init.sh/launch.sh 실행

## 수용 기준
- [ ] framework/prompts/en/ 디렉토리에 4개 영어 프롬프트 작성
- [ ] framework/agents/en/ 디렉토리에 4개 영어 역할 정의 작성
- [ ] framework/templates/en/ 디렉토리에 7개 영어 템플릿 작성
- [ ] project.config.md에 `language` 필드 추가 (기본: ko)
- [ ] init.sh에서 언어 설정에 따른 파일 복사 분기
- [ ] launch.sh에서 언어 설정에 따른 프롬프트 동기화 분기
- [ ] auto-setup.sh에서 언어 선택 옵션 제공
- [ ] 영어 프롬프트가 한국어 프롬프트와 기능적으로 동일 (번역 품질 보장)
- [ ] 기존 한국어 프롬프트에 영향 없음 (하위 호환)
