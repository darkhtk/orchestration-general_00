# SPEC-R-009: 샘플 설정 — 웹 프로젝트 (React/Next.js)

**관련 태스크:** R-009
**작성일:** 2026-04-13

---

## 개요
React/Next.js 풀스택 웹 프로젝트를 기준으로 한 샘플 project.config.md 작성.

## 상세 설명
게임 엔진이 아닌 웹 프로젝트에서 오케스트레이션 프레임워크를 사용하기 위한 참조 설정 파일을 제공한다. 게임 엔진 특화 항목(씬, PPU, 스프라이트)을 웹 프로젝트에 맞게 재해석하여, 컴포넌트 구조, API 라우트, E2E 테스트, 정적 에셋, 번들 사이즈, Lighthouse 점수 등을 포함한다. 리뷰 페르소나도 웹 서비스 사용자 관점으로 재정의한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 프레임워크 | Next.js 14 (App Router) | 최신 안정 버전 기준 |
| 언어 | TypeScript | 타입 안전 |
| 스타일링 | Tailwind CSS | 인기 선택 |
| 테스트 | Vitest + Playwright | 유닛 + E2E |
| 린터 | ESLint + Prettier | 코드 품질 |
| 빌드 도구 | Next.js 내장 (Turbopack) | |
| 에러 로그 | 브라우저 콘솔 + Next.js 서버 로그 | 엔진 로그 대체 |
| 에셋 규격 | WebP/AVIF, 최대 200KB/이미지 | 웹 최적화 |

## 데이터 구조
```markdown
# sample-config/react-nextjs.config.md 구조
## 1. 기본 정보 (프로젝트명, 프레임워크, 언어, 플랫폼=Web)
## 2. Git 설정
## 3. 디렉토리 매핑 (src/app/, src/components/, public/, tests/)
## 4. 에이전트 권한 (소스코드, 설정, 테스트)
## 5. 빌드/에러 체크 (npm run build, TypeScript 에러, ESLint)
## 6. 에셋 규격 (이미지 포맷/크기, 폰트, 아이콘)
## 7. 커밋/푸시 정책
## 8. 코드 아키텍처 (App Router 규칙, 서버/클라이언트 컴포넌트)
## 9. 루프 간격
## 10. 리뷰 페르소나 (웹 사용자 관점)
## 11. 검증 체계 (빌드, 코드, 접근성, 사용자 시나리오)
## 12. 개발 방향
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| auto-setup.sh | react-nextjs.config.md | 웹 프로젝트 감지 시 참조 |
| 사용자 | sample-config/ | 직접 참조 |

## UI 와이어프레임
N/A

## 호출 진입점
- **어디서:** 사용자가 웹 프로젝트 설정 시 sample-config/ 디렉토리 참조
- **어떻게:** `sample-config/react-nextjs.config.md` 파일 열기 후 수정

## 수용 기준
- [ ] `sample-config/react-nextjs.config.md` 파일 작성
- [ ] 게임 엔진 항목을 웹 프로젝트에 맞게 재해석 (씬→라우트, 에셋→정적파일 등)
- [ ] App Router 기반 디렉토리 구조 반영
- [ ] TypeScript + ESLint + Prettier 빌드/린트 설정 포함
- [ ] Vitest + Playwright 테스트 설정 포함
- [ ] 웹 서비스 사용자 관점 리뷰 페르소나 3~4명 정의
- [ ] 검증 체계를 웹에 맞게 재정의 (빌드, 코드, 접근성, 사용자 시나리오)
- [ ] 기존 샘플과 포맷/품질 일관성 유지
