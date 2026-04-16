# A-001: 프로젝트 타입별 설정 플로우 다이어그램

## 개요
각 엔진/플랫폼(Unity, Godot, Unreal, Web, Python)별 auto-setup 감지 흐름과 생성되는 설정 항목을 보여주는 플로우 다이어그램.

## 플로우 다이어그램

```mermaid
flowchart TD
    A[auto-setup.sh 실행] --> B[프로젝트 루트 스캔]

    B --> C{Unity 프로젝트?<br/>Assets/ + ProjectSettings/}
    C -->|YES| D[Unity 설정 생성]
    C -->|NO| E{Godot 프로젝트?<br/>project.godot}

    E -->|YES| F[Godot 설정 생성]
    E -->|NO| G{Unreal 프로젝트?<br/>*.uproject}

    G -->|YES| H[Unreal 설정 생성]
    G -->|NO| I{웹 프로젝트?<br/>package.json + tsconfig.json}

    I -->|YES| J[웹 프로젝트 설정 생성]
    I -->|NO| K{Python 프로젝트?<br/>requirements.txt OR pyproject.toml}

    K -->|YES| L[Python 설정 생성]
    K -->|NO| M[기본 설정 생성]

    %% Unity 상세 설정
    D --> D1[project.config.md<br/>Unity 템플릿 기반]
    D1 --> D2[Asset/ 폴더 구조 생성]
    D2 --> D3[Unity 에디터 스크립트<br/>빌드 자동화 설정]
    D3 --> D4[MCP-Unity 연동 설정]

    %% Godot 상세 설정
    F --> F1[project.config.md<br/>Godot 템플릿 기반]
    F1 --> F2[Scene/ 폴더 구조 생성]
    F2 --> F3[Godot 빌드 스크립트<br/>export_presets.cfg 설정]
    F3 --> F4[Godot 에디터 플러그인 설정]

    %% Unreal 상세 설정
    H --> H1[project.config.md<br/>Unreal 템플릿 기반]
    H1 --> H2[Content/ 폴더 구조 생성]
    H2 --> H3[C++ 빌드 설정<br/>Target.cs 파일 구성]
    H3 --> H4[Blueprint 자동화<br/>에디터 설정]

    %% 웹 프로젝트 상세 설정
    J --> J1[project.config.md<br/>웹 템플릿 기반]
    J1 --> J2[src/ 폴더 구조 생성]
    J2 --> J3[TypeScript/ESLint<br/>설정 파일 생성]
    J3 --> J4[빌드 도구<br/>webpack/vite 설정]

    %% Python 상세 설정
    L --> L1[project.config.md<br/>Python 템플릿 기반]
    L1 --> L2[src/ 폴더 구조 생성]
    L2 --> L3[pytest/black/flake8<br/>설정 파일 생성]
    L3 --> L4[가상환경<br/>자동화 스크립트]

    %% 공통 최종 단계
    D4 --> Z[설정 완료 안내]
    F4 --> Z
    H4 --> Z
    J4 --> Z
    L4 --> Z
    M --> Z

    Z --> Z1[project.config.md 검증]
    Z1 --> Z2[에이전트 초기화 실행]
    Z2 --> Z3[오케스트레이션 시작 준비]

    %% 스타일링
    classDef engineBox fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
    classDef configBox fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef finalBox fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px

    class D,F,H,J,L engineBox
    class D1,F1,H1,J1,L1 configBox
    class Z,Z1,Z2,Z3 finalBox
```

## 감지 조건 상세

### Unity 프로젝트 감지
- **필수 파일/폴더**: `Assets/` + `ProjectSettings/`
- **추가 확인**: `ProjectSettings/ProjectVersion.txt`
- **생성 설정**: Unity 에디터 버전별 빌드 설정, 에셋 임포트 설정

### Godot 프로젝트 감지
- **필수 파일**: `project.godot`
- **추가 확인**: Godot 버전 정보
- **생성 설정**: Scene 기반 프로젝트 구조, GDScript/C# 설정

### Unreal Engine 프로젝트 감지
- **필수 파일**: `*.uproject` (프로젝트 파일)
- **추가 확인**: `Source/` 폴더 (C++ 프로젝트인 경우)
- **생성 설정**: Blueprint/C++ 혼합 설정, 패키징 설정

### 웹 프로젝트 감지
- **필수 파일**: `package.json` + `tsconfig.json`
- **추가 확인**: React/Next.js/Vue 등 프레임워크 감지
- **생성 설정**: 프론트엔드 빌드 체인, 타입스크립트 설정

### Python 프로젝트 감지
- **필수 파일**: `requirements.txt` OR `pyproject.toml` OR `setup.py`
- **추가 확인**: Python 버전, 가상환경 설정
- **생성 설정**: 패키지 관리, 테스트 프레임워크 설정

## 출력 파일

각 프로젝트 타입별로 생성되는 주요 파일들:

```
프로젝트루트/
├── project.config.md          # 프로젝트 설정 (엔진별 템플릿)
├── BOARD.md                   # 태스크 보드
├── BACKLOG_RESERVE.md        # 예비 태스크
├── agents/                    # 에이전트 설정
├── scripts/                   # 자동화 스크립트
└── sample-config/            # 참조용 설정 예시
```

## 관련 파일
- `auto-setup.sh` - 메인 설정 스크립트
- `sample-config/*.config.md` - 엔진별 설정 템플릿
- `specs/SPEC-R-006.md` - 웹 프로젝트 감지 스펙
- `specs/SPEC-R-007.md` - Python 프로젝트 감지 스펙