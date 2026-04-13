# SPEC-R-010: 샘플 설정 — TypeScript/Node.js 프로젝트

**관련 태스크:** R-010
**작성일:** 2026-04-13

---

## 개요
순수 TypeScript/Node.js 백엔드 프로젝트(REST API, CLI 도구 등)를 기준으로 한 샘플 project.config.md 작성.

## 상세 설명
프론트엔드 프레임워크 없이 TypeScript/Node.js로 구성된 백엔드 API 서버, CLI 도구, 라이브러리 프로젝트를 위한 참조 설정 파일을 제공한다. Express/Fastify 기반 API, 데이터베이스 연동, Docker 배포 등 백엔드 특화 항목을 포함하고, 리뷰 페르소나를 API 소비자/DevOps/보안 관점으로 정의한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 런타임 | Node.js 20 LTS | 최신 LTS |
| 언어 | TypeScript 5.x | strict mode |
| 프레임워크 | Fastify | 고성능 HTTP |
| ORM | Prisma | DB 연동 |
| 테스트 | Vitest | 유닛 + 통합 |
| 린터 | ESLint + Prettier | 코드 품질 |
| 빌드 | tsc + tsx (dev) | TypeScript 빌드 |
| 에러 로그 | stdout/stderr + Winston | 서버 로그 |

## 데이터 구조
```markdown
# sample-config/typescript-node.config.md 구조
## 1. 기본 정보 (프로젝트명, 런타임, 언어, 플랫폼=Server)
## 2. Git 설정
## 3. 디렉토리 매핑 (src/, tests/, prisma/, docker/)
## 4. 에이전트 권한
## 5. 빌드/에러 체크 (tsc --noEmit, eslint, vitest)
## 6. 에셋 규격 (N/A — 또는 OpenAPI 스펙 문서)
## 7. 커밋/푸시 정책
## 8. 코드 아키텍처 (레이어 분리, DI 패턴)
## 9. 루프 간격
## 10. 리뷰 페르소나 (API 소비자, DevOps, 보안)
## 11. 검증 체계 (빌드, 코드, API 테스트, 부하 테스트)
## 12. 개발 방향
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| auto-setup.sh | typescript-node.config.md | TS 프로젝트 감지 시 참조 |
| 사용자 | sample-config/ | 직접 참조 |

## UI 와이어프레임
N/A

## 호출 진입점
- **어디서:** 사용자가 Node.js 백엔드 프로젝트 설정 시 sample-config/ 참조
- **어떻게:** `sample-config/typescript-node.config.md` 파일 열기 후 수정

## 수용 기준
- [ ] `sample-config/typescript-node.config.md` 파일 작성
- [ ] 백엔드 프로젝트에 맞는 디렉토리 구조 반영 (src/, routes/, middleware/, models/)
- [ ] TypeScript 빌드 + ESLint 설정 포함
- [ ] Vitest 유닛/통합 테스트 설정 포함
- [ ] API 엔드포인트 검증 관점의 리뷰 페르소나 3~4명 정의
- [ ] 검증 체계를 서버에 맞게 정의 (빌드, 코드, API 테스트, 부하)
- [ ] 기존 샘플과 포맷/품질 일관성 유지
