# A-001: 프로젝트 타입별 설정 플로우 다이어그램

## 개요
각 엔진/플랫폼별 auto-setup.sh 감지 흐름과 생성되는 설정 항목을 보여주는 플로우 다이어그램

## 다이어그램

```mermaid
graph TD
    Start([auto-setup.sh 실행]) --> CheckProject{프로젝트 파일 존재?}

    CheckProject -->|Unity project| Unity[Unity 프로젝트 감지]
    CheckProject -->|Godot project| Godot[Godot 프로젝트 감지]
    CheckProject -->|Unreal project| Unreal[Unreal 프로젝트 감지]
    CheckProject -->|package.json| Web[웹 프로젝트 감지]
    CheckProject -->|Python files| Python[Python 프로젝트 감지]
    CheckProject -->|없음| Generic[범용 설정]

    Unity --> UnityConfig{기존 설정 존재?}
    UnityConfig -->|Yes| UnityLoad[unity-sample.config.md 로드]
    UnityConfig -->|No| UnityCreate[project.config.md 생성<br/>- Unity 빌드 경로<br/>- 에셋 규격<br/>- 로그 경로 설정]

    Godot --> GodotConfig{기존 설정 존재?}
    GodotConfig -->|Yes| GodotLoad[godot-sample.config.md 로드]
    GodotConfig -->|No| GodotCreate[project.config.md 생성<br/>- Godot 빌드 경로<br/>- 씬 구조 설정<br/>- 로그 경로 설정]

    Unreal --> UnrealConfig{기존 설정 존재?}
    UnrealConfig -->|Yes| UnrealLoad[unreal-tps.config.md 로드]
    UnrealConfig -->|No| UnrealCreate[project.config.md 생성<br/>- C++ 빌드 설정<br/>- 에셋 패키징<br/>- 로그 경로 설정]

    Web --> WebConfig{기존 설정 존재?}
    WebConfig -->|Yes| WebLoad[react-nextjs.config.md 로드]
    WebConfig -->|No| WebCreate[project.config.md 생성<br/>- npm/yarn 설정<br/>- 빌드 스크립트<br/>- 정적 에셋 경로]

    Python --> PythonConfig{기존 설정 존재?}
    PythonConfig -->|Yes| PythonLoad[typescript-node.config.md 로드]
    PythonConfig -->|No| PythonCreate[project.config.md 생성<br/>- venv/poetry 설정<br/>- 테스트 설정<br/>- 패키지 구조]

    Generic --> GenericCreate[기본 project.config.md 생성<br/>- 범용 파일 구조<br/>- git 설정<br/>- 기본 경로 설정]

    UnityLoad --> Validate[설정 검증]
    UnityCreate --> Validate
    GodotLoad --> Validate
    GodotCreate --> Validate
    UnrealLoad --> Validate
    UnrealCreate --> Validate
    WebLoad --> Validate
    WebCreate --> Validate
    PythonLoad --> Validate
    PythonCreate --> Validate
    GenericCreate --> Validate

    Validate --> ValidateResult{검증 통과?}
    ValidateResult -->|Yes| Success([설정 완료])
    ValidateResult -->|No| Error[에러 로깅 및<br/>수동 설정 안내]

    Error --> Manual[수동 설정 필요]
```

## 감지 조건 상세

### Unity 프로젝트
- **감지 파일**: `Assets/`, `ProjectSettings/`, `*.unity`
- **생성 설정**:
  - 빌드 타겟 경로
  - 에셋 번들 설정
  - Unity 에디터 로그 경로

### Godot 프로젝트
- **감지 파일**: `project.godot`, `*.tscn`, `*.cs`
- **생성 설정**:
  - 익스포트 템플릿
  - 씬 구조 규격
  - Godot 에디터 로그 경로

### Unreal 프로젝트
- **감지 파일**: `*.uproject`, `Source/`, `Config/`
- **생성 설정**:
  - C++ 컴파일 설정
  - 패키지 빌드 경로
  - Unreal 에디터 로그 경로

### 웹 프로젝트
- **감지 파일**: `package.json`, `tsconfig.json`, `next.config.js`
- **생성 설정**:
  - npm/yarn 스크립트
  - 빌드 및 배포 경로
  - 정적 리소스 규격

### Python 프로젝트
- **감지 파일**: `requirements.txt`, `pyproject.toml`, `setup.py`
- **생성 설정**:
  - 가상환경 설정
  - 테스트 프레임워크
  - 패키지 의존성 관리

## 설정 파일 템플릿 매핑

| 프로젝트 타입 | 템플릿 파일 | 생성 위치 |
|-------------|------------|----------|
| Unity | `sample-config/unity-sample.config.md` | `project.config.md` |
| Godot | `sample-config/godot-sample.config.md` | `project.config.md` |
| Unreal | `sample-config/unreal-tps.config.md` | `project.config.md` |
| Web | `sample-config/react-nextjs.config.md` | `project.config.md` |
| Python | `sample-config/typescript-node.config.md` | `project.config.md` |
| 범용 | `sample-config/generic.config.md` | `project.config.md` |

## 검증 단계

1. **파일 존재성 확인**: 설정된 경로의 파일/폴더 존재 여부
2. **권한 확인**: 빌드 경로 쓰기 권한
3. **의존성 확인**: 필수 도구 설치 여부 (Unity Hub, Godot, npm 등)
4. **구문 검증**: project.config.md 마크다운 문법 및 필드 유효성

## 에러 처리

- **파일 미발견**: 수동 설정 안내 문서 출력
- **권한 부족**: sudo 권한 요청 또는 경로 변경 제안
- **의존성 누락**: 설치 가이드 링크 제공
- **구문 오류**: 오류 위치 및 수정 예시 제공