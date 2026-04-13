# SPEC-R-008: 샘플 설정 — Unreal Engine 프로젝트

**관련 태스크:** R-008
**작성일:** 2026-04-13

---

## 개요
Unreal Engine C++ Third-Person Shooter 프로젝트를 기준으로 한 샘플 project.config.md 작성.

## 상세 설명
기존 unity-2d-rpg.config.md, godot-platformer.config.md와 동일한 수준으로 Unreal Engine 프로젝트에 맞춘 완전한 샘플 설정 파일을 제공한다. UE5의 C++/Blueprint 혼합 개발, UE 빌드 시스템(UnrealBuildTool), 에디터 로그 경로, 에셋 규격(Texture, Mesh, Audio), 테스트 프레임워크(Automation), 커밋 컨벤션 등을 포함한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 엔진 | Unreal Engine 5.4 | 최신 안정 버전 기준 |
| 언어 | C++ + Blueprint | 혼합 개발 |
| 플랫폼 | Windows (PC) | 기본 타겟 |
| 소스 경로 | `Source/` | UE 표준 |
| 에셋 경로 | `Content/` | UE 표준 |
| 테스트 | Automation Framework | `Source/Tests/` |
| 에러 로그 | `Saved/Logs/PROJECT.log` | 프로젝트 내부 |
| 텍스처 규격 | 2048x2048 BC7, Power of 2 | 3D 프로젝트 기준 |
| 오디오 규격 | 48000Hz 16bit Stereo | UE 기본 |

## 데이터 구조
```markdown
# sample-config/unreal-tps.config.md 구조
## 1. 기본 정보
## 2. Git 설정
## 3. 디렉토리 매핑
## 4. 에이전트 권한
## 5. 빌드/에러 체크
## 6. 에셋 규격
## 7. 커밋/푸시 정책
## 8. 코드 아키텍처
## 9. 루프 간격
## 10. 리뷰 페르소나
## 11. 검증 체계
## 12. 개발 방향
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| auto-setup.sh | unreal-tps.config.md | Unreal 감지 시 참조 템플릿 |
| 사용자 | sample-config/ | 직접 참조하여 커스터마이징 |

## UI 와이어프레임
N/A

## 호출 진입점
- **어디서:** 사용자가 Unreal 프로젝트 설정 시 sample-config/ 디렉토리 참조
- **어떻게:** `sample-config/unreal-tps.config.md` 파일 열기 후 프로젝트에 맞게 수정

## 수용 기준
- [ ] `sample-config/unreal-tps.config.md` 파일 작성
- [ ] project.config.md 전체 섹션 커버 (기본 정보~개발 방향)
- [ ] UE5 C++/Blueprint 프로젝트 디렉토리 구조 반영
- [ ] UnrealBuildTool 빌드 명령어 포함
- [ ] UE Automation Framework 테스트 설정 포함
- [ ] UE 에셋 규격 (텍스처/메시/오디오) 명시
- [ ] 3~4명의 적절한 리뷰 페르소나 정의
- [ ] 기존 샘플과 포맷/품질 일관성 유지
