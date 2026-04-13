# SPEC-R-006: 웹 프로젝트 자동 감지 (auto-setup.sh)

**관련 태스크:** R-006
**작성일:** 2026-04-13

---

## 개요
auto-setup.sh에 package.json, tsconfig.json 기반 웹 프로젝트 자동 감지 및 설정 생성 로직 추가.

## 상세 설명
현재 auto-setup.sh는 Unity/Godot/Unreal만 감지한다. 웹 프로젝트(React, Next.js, Vue, Angular 등)를 package.json, tsconfig.json, 프레임워크별 설정 파일(next.config.js, vite.config.ts 등)로 감지하고, 해당 프로젝트에 맞는 project.config.md를 자동 생성한다. 엔진 대신 프레임워크, 빌드 도구, 테스트 러너 등을 감지 항목으로 포함한다.

## 수치/밸런스
| 항목 | 감지 파일 | 비고 |
|------|----------|------|
| Node.js 프로젝트 | `package.json` | 기본 감지 |
| TypeScript | `tsconfig.json` | 언어 판별 |
| React | `package.json` → `react` dep | 또는 `src/App.jsx` |
| Next.js | `next.config.js` / `next.config.mjs` | SSR 프레임워크 |
| Vue | `package.json` → `vue` dep | 또는 `vue.config.js` |
| Angular | `angular.json` | CLI 프레임워크 |
| Vite | `vite.config.ts` / `vite.config.js` | 빌드 도구 |
| 테스트 러너 | `jest.config.*` / `vitest.config.*` / `playwright.config.*` | 테스트 설정 |
| 에러 로그 | 브라우저 콘솔 / Node stderr | 엔진 로그 대체 |

## 데이터 구조
```bash
# auto-setup.sh 감지 결과 (웹 프로젝트용)
ENGINE="Web"
ENGINE_VERSION="Next.js 14.2"  # 또는 "React 18" 등
LANGUAGE="TypeScript"          # 또는 "JavaScript"
BUILD_TOOL="Vite"              # npm/yarn/pnpm + bundler
TEST_RUNNER="Vitest"
SOURCE_DIR="src/"
TEST_DIR="tests/" or "__tests__/" or "src/**/*.test.ts"
ASSET_DIR="public/"
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| auto-setup.sh | package.json | JSON 파싱 (jq 또는 grep) |
| auto-setup.sh | tsconfig.json | TypeScript 감지 |
| auto-setup.sh | next.config.* / vite.config.* | 프레임워크 감지 |
| auto-setup.sh | project.config.md | 설정 생성 |
| project.config.md | 에이전트 프롬프트 | 매 루프 참조 |

## UI 와이어프레임
```
$ ./auto-setup.sh /path/to/web-project

[감지] 프로젝트 유형: Web (Next.js 14.2)
[감지] 언어: TypeScript
[감지] 빌드: npm + Next.js (내장)
[감지] 테스트: Jest
[감지] 소스: src/
[감지] 정적 에셋: public/
[감지] 테스트: __tests__/

project.config.md 생성 완료.
```

## 호출 진입점
- **어디서:** orchestrate.bat → auto-setup.sh (기존 흐름)
- **어떻게:** auto-setup.sh 내부 감지 로직 확장 (추가 elif 분기)

## 수용 기준
- [ ] package.json 존재 시 웹 프로젝트로 감지
- [ ] React/Next.js/Vue/Angular 프레임워크 자동 판별
- [ ] TypeScript/JavaScript 언어 자동 판별
- [ ] 소스코드/테스트/에셋(public) 디렉토리 자동 매핑
- [ ] 빌드 명령어 자동 추출 (package.json scripts.build)
- [ ] 테스트 명령어 자동 추출 (package.json scripts.test)
- [ ] 생성된 project.config.md가 기존 포맷과 호환
- [ ] Unity/Godot/Unreal 감지 로직에 영향 없음
