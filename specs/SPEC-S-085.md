# SPEC-S-085: 웹 프로젝트 자동 감지 기능 구현

**관련 태스크:** S-085
**작성일:** 2026-04-16
**작성자:** Coordinator

---

## 개요

프로젝트 디렉토리를 스캔하여 웹 프로젝트(React, Vue, Angular 등) 여부를 자동으로 감지하는 기능

## 상세 설명

오케스트레이션 시스템이 새로운 프로젝트를 분석할 때, 해당 프로젝트가 웹 기반 프로젝트인지 자동으로 판단해야 합니다. 이를 통해 웹 특화 작업 흐름과 도구를 적용할 수 있으며, 적절한 빌드/배포 전략을 제안할 수 있습니다.

감지 후에는 프로젝트 메타데이터에 웹 프로젝트 타입과 관련 설정을 저장하여, 후속 오케스트레이션 작업에 활용합니다.

## 수치/밸런스

| 항목 | 값 | 비고 |
|------|---|------|
| 스캔 깊이 | 3단계 | 루트에서 최대 3단계 하위 디렉토리까지 |
| 감지 시간 제한 | 5초 | 대용량 프로젝트에서 타임아웃 방지 |
| 캐시 유효기간 | 1시간 | 프로젝트 구조 변경 감지를 위한 재스캔 |

## 데이터 구조

```typescript
interface WebProjectInfo {
  type: 'react' | 'vue' | 'angular' | 'nextjs' | 'nuxtjs' | 'unknown';
  packageManager: 'npm' | 'yarn' | 'pnpm' | 'unknown';
  hasTypeScript: boolean;
  frameworkVersion?: string;
  buildTool?: 'webpack' | 'vite' | 'rollup' | 'parcel';
  configFiles: string[];
  entryPoints: string[];
}
```

## 연동 경로

| From | To | 방식 |
|------|----|------|
| ProjectScanner | WebDetector | 직접호출 |
| WebDetector | ProjectMetadata | 직접호출 |
| Coordinator | WebDetector.scan() | 직접호출 |

## 감지 패턴

### React 프로젝트
- package.json에 "react" 의존성
- src/App.js 또는 src/App.tsx 존재
- public/index.html 존재

### Vue 프로젝트
- package.json에 "vue" 의존성
- src/main.js 또는 src/main.ts 존재
- vue.config.js 또는 vite.config.js 존재

### Angular 프로젝트
- package.json에 "@angular/core" 의존성
- angular.json 존재
- src/app/app.module.ts 존재

### Next.js 프로젝트
- package.json에 "next" 의존성
- next.config.js 또는 next.config.ts 존재
- pages/ 또는 app/ 디렉토리 존재

### Nuxt.js 프로젝트
- package.json에 "nuxt" 의존성
- nuxt.config.js 또는 nuxt.config.ts 존재
- pages/ 디렉토리 존재

## 호출 진입점

- **어디서:** 프로젝트 초기 분석 단계
- **어떻게:** Coordinator.analyzeProject() 메서드 내부에서 자동 호출
- **트리거:** 새로운 프로젝트 디렉토리가 등록될 때

## 세이브 연동

- 저장 필드: ProjectMetadata.webInfo
- 로드 시 복원: 프로젝트별 웹 설정 정보 복원
- 마이그레이션: 기존 프로젝트에 webInfo 필드 추가

## 수용 기준

- [ ] package.json 파싱하여 프레임워크 의존성 확인
- [ ] 주요 프레임워크별 설정 파일 감지
- [ ] TypeScript 사용 여부 판단
- [ ] 빌드 도구 식별
- [ ] 패키지 매니저 식별
- [ ] 감지 결과를 ProjectMetadata에 저장
- [ ] 캐시 메커니즘으로 성능 최적화
- [ ] 에러 핸들링 (권한 없음, 파일 손상 등)
- [ ] 단위 테스트 커버리지 90% 이상