# SPEC-R-015: 오디오 파일 자동 검증

**관련 태스크:** R-015
**작성일:** 2026-04-13

---

## 개요
project.config.md의 오디오 규격(Hz, 비트레이트, 채널)과 실제 파일을 비교 검증하는 스크립트.

## 상세 설명
프로젝트에 추가된 오디오 파일이 project.config.md에 정의된 규격(샘플레이트, 비트 깊이, 채널 수, 포맷)을 준수하는지 자동으로 검증한다. R-014(에셋 검증)과 유사한 구조로, `ffprobe` 또는 `soxi`를 활용하여 오디오 메타데이터를 추출하고 규격과 대조한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 검증 대상 | project.config.md의 `audio_path` 하위 | WAV, OGG, MP3 |
| 샘플레이트 검증 | config의 `audio_hz` | 예: 22050Hz |
| 비트 깊이 검증 | config의 `audio_bit` | 예: 16bit |
| 채널 검증 | config의 `audio_channels` | mono/stereo |
| 검증 도구 | `ffprobe` (FFmpeg) 또는 `soxi` (SoX) | 크로스플랫폼 |
| 리포트 경로 | `orchestration/logs/AUDIO-VALIDATION.md` | 최신 결과만 유지 |

## 데이터 구조
```markdown
# orchestration/logs/AUDIO-VALIDATION.md
## 오디오 검증 리포트
**검증 시각:** 2026-04-13T14:30:00
**대상 경로:** Assets/Audio/
**검증 항목:** 15개 파일

### ❌ 위반 (2건)
| 파일 | 위반 항목 | 실제 값 | 규격 값 |
|------|----------|---------|---------|
| bgm_battle.wav | 샘플레이트 | 44100Hz | 22050Hz |
| sfx_click.mp3 | 포맷 | MP3 | WAV/OGG만 허용 |

### ✅ 통과 (13건)
(생략)
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| validate-audio.sh | project.config.md | 오디오 규격 읽기 |
| validate-audio.sh | 오디오 디렉토리 | 파일 스캔 + 메타데이터 추출 |
| validate-audio.sh | AUDIO-VALIDATION.md | 리포트 생성 |
| validate-assets.sh | validate-audio.sh | 통합 실행 시 연계 호출 |

## UI 와이어프레임
```
$ ./validate-audio.sh --config orchestration/project.config.md

[검증] 오디오 경로: Assets/Audio/
[검증] 규격: 22050Hz, 16bit, mono, WAV/OGG
[검증] 15개 파일 스캔 중...

❌ bgm_battle.wav: 샘플레이트 44100Hz (22050Hz 필요)
❌ sfx_click.mp3: 포맷 MP3 (WAV/OGG만 허용)
✅ 13/15 통과

리포트: orchestration/logs/AUDIO-VALIDATION.md
```

## 호출 진입점
- **어디서:** 에셋 검증과 함께 실행 / 독립 CLI
- **어떻게:** `./validate-audio.sh --config orchestration/project.config.md`

## 수용 기준
- [ ] `validate-audio.sh` 스크립트 구현
- [ ] 샘플레이트 검증 (project.config.md 규격 기준)
- [ ] 비트 깊이 검증
- [ ] 채널 수 검증 (mono/stereo)
- [ ] 오디오 포맷 검증 (허용 포맷만)
- [ ] AUDIO-VALIDATION.md 리포트 자동 생성
- [ ] ffprobe 미설치 시 soxi 폴백, 둘 다 없으면 `file` 명령 기본 정보
- [ ] 위반 건수 exit code 반환
- [ ] Windows/macOS/Linux 크로스플랫폼 동작
