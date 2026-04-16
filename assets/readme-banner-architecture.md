# README 배너 및 아키텍처 다이어그램

## 개요
README.md용 프로젝트 배너 이미지, 4-에이전트 아키텍처 다이어그램, 태스크 생명주기 플로우차트

## 1. 프로젝트 배너

### ASCII 아트 배너
```
 █████╗ ██╗    ██████╗ ███████╗██╗   ██╗
██╔══██╗██║    ██╔══██╗██╔════╝██║   ██║
███████║██║    ██║  ██║█████╗  ██║   ██║
██╔══██║██║    ██║  ██║██╔══╝  ╚██╗ ██╔╝
██║  ██║██║    ██████╔╝███████╗ ╚████╔╝
╚═╝  ╚═╝╚═╝    ╚═════╝ ╚══════╝  ╚═══╝

   🤖 Autonomous Intelligence Development Orchestration
   ────────────────────────────────────────────────────
   4개 전문 에이전트가 협업하는 자동화된 게임 개발 시스템
```

### 컴팩트 배너 (Markdown)
```markdown
# 🎮 AI-Dev Orchestration

> **자율 지능형 게임 개발 오케스트레이션 시스템**
> 4개 전문 AI 에이전트(Coordinator, Developer, Supervisor, Client)가
> 협업하여 게임 개발을 자동화하는 혁신적인 개발 환경

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Agents](https://img.shields.io/badge/agents-4-orange.svg)](#architecture)
[![Platform](https://img.shields.io/badge/platform-Unity%20%7C%20Godot%20%7C%20Unreal-purple.svg)](#supported-engines)
```

## 2. 4-에이전트 아키텍처 다이어그램

```mermaid
graph TB
    subgraph "🎯 User Interaction Layer"
        USER[👤 사용자]
        CMD[💬 명령어/요청]
    end

    subgraph "🧠 AI Agent Orchestration"
        COORD[🔄 Coordinator<br/>조율자<br/>━━━━━━━━<br/>• 태스크 생성/관리<br/>• 우선순위 결정<br/>• 에이전트 조율<br/>• 외부 통합]

        DEV[🔧 Developer<br/>개발자<br/>━━━━━━━━<br/>• 코드 구현<br/>• 기능 개발<br/>• 버그 수정<br/>• 테스트 실행]

        SUP[📊 Supervisor<br/>감독자<br/>━━━━━━━━<br/>• 코드 리뷰<br/>• 품질 검증<br/>• 승인/거부<br/>• 표준 준수]

        CLIENT[🎯 Client<br/>클라이언트<br/>━━━━━━━━<br/>• 엔진 검증<br/>• 빌드 테스트<br/>• 성능 측정<br/>• 배포 확인]
    end

    subgraph "📋 Task Management"
        BOARD[📄 BOARD.md<br/>메인 태스크 보드]
        RESERVE[📋 BACKLOG_RESERVE.md<br/>예비 태스크 풀]
    end

    subgraph "🔧 Development Tools"
        PROJ_CONFIG[⚙️ project.config.md<br/>프로젝트 설정]
        BUILD_SCRIPTS[🛠️ Build Scripts<br/>빌드 자동화]
        MONITOR[👀 monitor.sh<br/>실시간 모니터링]
    end

    subgraph "🎮 Game Engines"
        UNITY[🎯 Unity]
        GODOT[🦎 Godot]
        UNREAL[🔷 Unreal]
    end

    subgraph "📁 Project Files"
        SRC[💻 Source Code]
        ASSETS[🎨 Game Assets]
        CONFIGS[⚙️ Config Files]
    end

    %% 사용자 상호작용
    USER --> CMD
    CMD --> COORD

    %% 에이전트 간 협업 플로우
    COORD --> DEV
    DEV --> SUP
    SUP --> CLIENT
    CLIENT --> COORD

    %% 태스크 관리
    COORD <--> BOARD
    COORD <--> RESERVE
    DEV <--> BOARD
    SUP <--> BOARD
    CLIENT <--> BOARD

    %% 도구 및 설정
    DEV <--> PROJ_CONFIG
    DEV <--> BUILD_SCRIPTS
    CLIENT <--> BUILD_SCRIPTS
    COORD <--> MONITOR

    %% 게임 엔진 연동
    DEV <--> UNITY
    DEV <--> GODOT
    DEV <--> UNREAL
    CLIENT <--> UNITY
    CLIENT <--> GODOT
    CLIENT <--> UNREAL

    %% 프로젝트 파일 관리
    DEV <--> SRC
    DEV <--> ASSETS
    DEV <--> CONFIGS
    SUP --> SRC
    CLIENT --> SRC

    %% 스타일링
    classDef userLayer fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef agentLayer fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef taskLayer fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef toolLayer fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef engineLayer fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef fileLayer fill:#f1f8e9,stroke:#33691e,stroke-width:2px

    class USER,CMD userLayer
    class COORD,DEV,SUP,CLIENT agentLayer
    class BOARD,RESERVE taskLayer
    class PROJ_CONFIG,BUILD_SCRIPTS,MONITOR toolLayer
    class UNITY,GODOT,UNREAL engineLayer
    class SRC,ASSETS,CONFIGS fileLayer
```

## 3. 태스크 생명주기 플로우차트

```mermaid
stateDiagram-v2
    [*] --> 요청접수 : 사용자 요청/자동감지

    요청접수 --> 태스크생성 : Coordinator 처리

    state 태스크생성 {
        [*] --> 우선순위설정
        우선순위설정 --> BOARD등록
        BOARD등록 --> [*]
    }

    태스크생성 --> Backlog : P1-P3 일반 태스크
    태스크생성 --> InProgress : P0 긴급 태스크

    state Backlog {
        [*] --> 대기중
        대기중 --> [*]
    }

    Backlog --> InProgress : Developer 선택

    state InProgress {
        [*] --> 구현시작
        구현시작 --> 코드작성
        코드작성 --> 테스트실행
        테스트실행 --> 구현완료
        구현완료 --> [*]
    }

    InProgress --> InReview : Developer 완료

    state InReview {
        [*] --> 코드리뷰
        코드리뷰 --> 품질검증
        품질검증 --> 표준준수확인
        표준준수확인 --> 리뷰완료
        리뷰완료 --> [*]
    }

    InReview --> InProgress : REJECT (수정 필요)
    InReview --> 최종검증 : APPROVE

    state 최종검증 {
        [*] --> 엔진호환성
        엔진호환성 --> 빌드테스트
        빌드테스트 --> 성능측정
        성능측정 --> 배포준비
        배포준비 --> [*]
    }

    최종검증 --> InReview : Client 검증 실패
    최종검증 --> Done : Client 검증 통과

    Done --> [*] : 태스크 완료

    state "에러 처리" as ErrorHandling {
        [*] --> 에러감지
        에러감지 --> 에러분석
        에러분석 --> P0태스크생성
        P0태스크생성 --> [*]
    }

    InProgress --> ErrorHandling : 빌드/테스트 실패
    InReview --> ErrorHandling : 검증 에러
    최종검증 --> ErrorHandling : 배포 에러

    ErrorHandling --> InProgress : 에러 수정 태스크

    note right of 태스크생성
        • P0: 긴급 (에러, 빌드 실패)
        • P1: 높음 (핵심 기능)
        • P2: 보통 (개선 사항)
        • P3: 낮음 (최적화, 정리)
    end note

    note left of InReview
        Supervisor가 다음 항목 검토:
        • 코드 품질
        • 아키텍처 준수
        • 테스트 커버리지
        • 문서화 상태
    end note

    note right of 최종검증
        Client가 실제 환경에서:
        • 빌드 성공 여부
        • 런타임 에러 확인
        • 성능 벤치마크
        • 다양한 플랫폼 테스트
    end note
```

## 4. 에이전트 역할 상세도

```mermaid
mindmap
  root((AI Dev<br/>Orchestration))
    🔄 Coordinator
      태스크 관리
        우선순위 설정
        데드라인 추적
        진행 상황 모니터링
      외부 통합
        이메일 모니터링
        이슈 트래킹 연동
        CI/CD 파이프라인
      에이전트 조율
        작업 분배
        충돌 해결
        리소스 관리

    🔧 Developer
      코드 구현
        기능 개발
        버그 수정
        리팩토링
      테스트 실행
        유닛 테스트
        통합 테스트
        성능 테스트
      도구 활용
        IDE 연동
        버전 관리
        빌드 시스템

    📊 Supervisor
      품질 관리
        코드 리뷰
        아키텍처 검증
        보안 점검
      표준 준수
        코딩 스타일
        문서화 기준
        베스트 프랙티스
      승인 프로세스
        APPROVE/REJECT
        개선 제안
        멘토링

    🎯 Client
      실환경 테스트
        빌드 검증
        런타임 테스트
        성능 벤치마크
      배포 관리
        플랫폼별 빌드
        배포 파이프라인
        롤백 계획
      사용자 관점
        UX 검증
        접근성 확인
        호환성 테스트
```

## 5. 시스템 구성도

```mermaid
C4Context
    title System Context Diagram - AI Dev Orchestration

    Person(user, "Game Developer", "게임 개발자")
    Person(pm, "Project Manager", "프로젝트 매니저")

    System(aidev, "AI Dev Orchestration", "4개 AI 에이전트가 협업하는 자동화된 게임 개발 시스템")

    System_Ext(unity, "Unity Editor", "게임 엔진")
    System_Ext(godot, "Godot Engine", "게임 엔진")
    System_Ext(unreal, "Unreal Engine", "게임 엔진")

    System_Ext(git, "Git Repository", "소스 코드 저장소")
    System_Ext(ci, "CI/CD Pipeline", "빌드 및 배포 파이프라인")
    System_Ext(email, "Email System", "외부 요청 수신")

    Rel(user, aidev, "명령어/요청", "CLI/텍스트")
    Rel(pm, aidev, "태스크 요청", "이메일")

    Rel(aidev, unity, "프로젝트 빌드/테스트", "MCP")
    Rel(aidev, godot, "프로젝트 빌드/테스트", "CLI")
    Rel(aidev, unreal, "프로젝트 빌드/테스트", "CLI")

    Rel(aidev, git, "코드 커밋/푸시", "Git API")
    Rel(aidev, ci, "빌드 트리거", "Webhook")
    Rel(aidev, email, "요청 모니터링", "IMAP/API")

    UpdateRelStyle(user, aidev, $offsetY="-50", $offsetX="-90")
    UpdateRelStyle(aidev, git, $offsetY="-40")
    UpdateRelStyle(aidev, ci, $offsetY="-20")
```

## 6. 배너 사용 가이드

### README.md 상단 배치
```markdown
<!-- 프로젝트 상단에 배치 -->
<div align="center">

# 🎮 AI-Dev Orchestration

> **자율 지능형 게임 개발 오케스트레이션 시스템**
> 4개 전문 AI 에이전트가 협업하여 게임 개발을 자동화하는 혁신적인 개발 환경

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Agents](https://img.shields.io/badge/agents-4-orange.svg)](#architecture)

</div>

---

<!-- 아키텍처 다이어그램은 별도 섹션에 배치 -->
## 🏗️ 아키텍처

[아키텍처 다이어그램 삽입]

## 🔄 태스크 플로우

[태스크 생명주기 다이어그램 삽입]
```

### 다이어그램 파일 생성 스크립트
```bash
# Mermaid 다이어그램을 이미지로 변환
npx @mermaid-js/mermaid-cli -i architecture.mmd -o architecture.png -t dark -b transparent
npx @mermaid-js/mermaid-cli -i task-lifecycle.mmd -o task-lifecycle.png -t dark -b transparent
```

---

*생성일: 2026-04-16*
*태스크: A-003 프로젝트 README 배너 및 아키텍처 다이어그램*