# SPEC-R-021: 프로젝트 간 설정 프리셋 저장/불러오기

**관련 태스크:** R-021
**작성일:** 2026-04-13

---

## 개요
project.config.md 설정을 프리셋으로 저장하고, 새 프로젝트에서 기존 프리셋을 불러와 빠르게 적용하는 기능.

## 상세 설명
여러 프로젝트를 오케스트레이션할 때 유사한 설정(리뷰 페르소나, 검증 체계, 커밋 정책, 루프 간격 등)을 반복 설정하는 번거로움을 줄이기 위해, 설정을 프리셋으로 저장/불러오는 기능을 제공한다. sample-config/에 있는 엔진별 샘플 설정과 별개로, 사용자가 자신의 프로젝트에서 커스터마이징한 설정을 저장하고 재사용할 수 있다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 프리셋 저장 경로 | `~/.orchestration/presets/` | 사용자 홈 디렉토리 |
| 프리셋 포맷 | project.config.md 그대로 복사 | Markdown |
| 프리셋 이름 | 사용자 지정 (예: "my-unity-rpg") | 파일명으로 사용 |
| 프리셋 메타 | 생성일, 소스 프로젝트, 설명 | 파일 상단 주석 |
| 불러오기 모드 | 전체 교체 / 섹션별 선택 | 사용자 선택 |

## 데이터 구조
```bash
# 프리셋 저장 구조
~/.orchestration/
└── presets/
    ├── my-unity-rpg.config.md     # 사용자 프리셋 1
    ├── my-web-app.config.md       # 사용자 프리셋 2
    └── presets.json               # 프리셋 인덱스
```

```json
// presets.json
{
  "presets": [
    {
      "name": "my-unity-rpg",
      "description": "Unity 2D RPG 기본 설정 + 커스텀 페르소나",
      "created": "2026-04-13",
      "source_project": "/path/to/my-rpg-game",
      "engine": "Unity"
    }
  ]
}
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| config-preset.sh save | project.config.md | 현재 설정 읽기 |
| config-preset.sh save | ~/.orchestration/presets/ | 프리셋 저장 |
| config-preset.sh load | ~/.orchestration/presets/ | 프리셋 읽기 |
| config-preset.sh load | project.config.md | 설정 덮어쓰기/병합 |
| auto-setup.sh | config-preset.sh | 셋업 시 프리셋 선택 옵션 제공 |
| orchestrate.bat | config-preset.sh | 셋업 플로우에 통합 |

## UI 와이어프레임
```
$ ./config-preset.sh save --name "my-unity-rpg" --desc "Unity RPG 기본 + 4명 페르소나"

[프리셋] project.config.md → ~/.orchestration/presets/my-unity-rpg.config.md
[프리셋] 저장 완료!

$ ./config-preset.sh list

[프리셋] 저장된 프리셋:
  1. my-unity-rpg    — Unity RPG 기본 + 4명 페르소나 (2026-04-13)
  2. my-web-app      — Next.js 풀스택 설정 (2026-04-10)

$ ./config-preset.sh load --name "my-unity-rpg"

[프리셋] ~/.orchestration/presets/my-unity-rpg.config.md → project.config.md
[프리셋] 적용 완료! 프로젝트별 경로(디렉토리 매핑)는 수동 확인 필요.
```

## 호출 진입점
- **어디서:** 터미널 CLI 또는 orchestrate.bat 설정 리뷰 단계
- **어떻게:** `./config-preset.sh save|load|list [--name NAME]`

## 수용 기준
- [ ] `config-preset.sh` 스크립트 구현 (save/load/list/delete 서브커맨드)
- [ ] 프리셋 저장 시 메타 정보(생성일, 소스, 설명) 포함
- [ ] 프리셋 불러오기 시 프로젝트 경로 관련 항목 경고 (수동 수정 필요)
- [ ] 프리셋 목록 조회
- [ ] 프리셋 삭제
- [ ] auto-setup.sh에서 프리셋 선택 옵션 연동
- [ ] 프리셋 디렉토리 자동 생성 (~/.orchestration/presets/)
- [ ] Windows/macOS/Linux 크로스플랫폼 경로 처리
