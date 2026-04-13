# SPEC-R-014: 에셋 파일 자동 검증

**관련 태스크:** R-014
**작성일:** 2026-04-13

---

## 개요
project.config.md의 에셋 규격(해상도, PPU, 포맷, 파일 크기)과 실제 파일을 비교 검증하는 스크립트.

## 상세 설명
Supervisor가 생성하거나 외부에서 추가한 에셋 파일이 project.config.md에 정의된 규격을 준수하는지 자동으로 검증한다. 이미지 파일의 해상도, 포맷(PNG/WebP), 파일 크기, 색상 모드 등을 체크하고, 위반 항목을 리포트로 출력한다. Supervisor/Developer 커밋 전 체크에 통합하거나 독립 실행할 수 있다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 검증 대상 | project.config.md의 `asset_path` 하위 이미지 | PNG, JPG, WebP, AVIF |
| 해상도 검증 | config의 `sprite_resolution` 배수 확인 | 예: 16x32의 배수 |
| 포맷 검증 | 허용 포맷 목록 대조 | config에서 정의 |
| 파일 크기 | 최대 크기 제한 | config에서 정의 (기본 1MB) |
| 검증 도구 | `identify` (ImageMagick) 또는 `file` 명령 | 크로스플랫폼 |
| 리포트 경로 | `orchestration/logs/ASSET-VALIDATION.md` | 최신 결과만 유지 |

## 데이터 구조
```markdown
# orchestration/logs/ASSET-VALIDATION.md
## 에셋 검증 리포트
**검증 시각:** 2026-04-13T14:30:00
**대상 경로:** Assets/Sprites/
**검증 항목:** 42개 파일

### ❌ 위반 (3건)
| 파일 | 위반 항목 | 실제 값 | 규격 값 |
|------|----------|---------|---------|
| player_idle.png | 해상도 | 20x40 | 16x32 배수 |
| enemy_boss.png | 파일 크기 | 2.3MB | 최대 1MB |
| item_sword.jpg | 포맷 | JPG | PNG만 허용 |

### ✅ 통과 (39건)
(생략)
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| validate-assets.sh | project.config.md | 에셋 규격 읽기 |
| validate-assets.sh | 에셋 디렉토리 | 파일 스캔 + 메타데이터 추출 |
| validate-assets.sh | ASSET-VALIDATION.md | 리포트 생성 |
| Supervisor 프롬프트 | validate-assets.sh | 에셋 생성 후 검증 |
| Developer 프롬프트 | validate-assets.sh | 커밋 전 검증 (선택) |

## UI 와이어프레임
```
$ ./validate-assets.sh --config orchestration/project.config.md

[검증] 에셋 경로: Assets/Sprites/
[검증] 규격: 16x32 배수, PNG만, 최대 1MB
[검증] 42개 파일 스캔 중...

❌ player_idle.png: 해상도 20x40 (16x32 배수 아님)
❌ enemy_boss.png: 파일 크기 2.3MB (최대 1MB 초과)
❌ item_sword.jpg: 포맷 JPG (PNG만 허용)
✅ 39/42 통과

리포트: orchestration/logs/ASSET-VALIDATION.md
```

## 호출 진입점
- **어디서:** Supervisor 에셋 생성 후 / Developer 커밋 전 / 독립 CLI
- **어떻게:** `./validate-assets.sh --config orchestration/project.config.md`

## 수용 기준
- [ ] `validate-assets.sh` 스크립트 구현
- [ ] 이미지 해상도 검증 (project.config.md 규격 기준)
- [ ] 이미지 포맷 검증 (허용 포맷만)
- [ ] 파일 크기 검증 (최대 크기 제한)
- [ ] ASSET-VALIDATION.md 리포트 자동 생성
- [ ] ImageMagick 미설치 시 `file` 명령 폴백
- [ ] 위반 건수 exit code 반환 (CI 연동 가능)
- [ ] Windows/macOS/Linux 크로스플랫폼 동작
