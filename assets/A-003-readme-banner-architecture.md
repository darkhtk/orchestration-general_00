# A-003: 프로젝트 README 배너 및 아키텍처 다이어그램

## 개요
README.md용 프로젝트 배너 이미지, 4-에이전트 아키텍처 다이어그램, 태스크 생명주기 플로우차트 제작.

## 1. 프로젝트 배너 디자인

### ASCII 아트 버전 (텍스트 기반)
```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║    🎯 MULTI-AGENT ORCHESTRATION FRAMEWORK                   ║
║                                                               ║
║    ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       ║
║    │ 👥 SUP  │──│ 👨‍💻 DEV │──│ 👀 REV  │──│ 🎮 CLI  │       ║
║    └─────────┘  └─────────┘  └─────────┘  └─────────┘       ║
║                                                               ║
║    Unity • Godot • Unreal • Web • Python 프로젝트 자동화    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

### 컬러 버전 (마크다운 배지 스타일)
```markdown
<div align="center">

# 🎯 Multi-Agent Orchestration

<p>
  <img src="https://img.shields.io/badge/Unity-100000?style=for-the-badge&logo=unity&logoColor=white" alt="Unity"/>
  <img src="https://img.shields.io/badge/Godot-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white" alt="Godot"/>
  <img src="https://img.shields.io/badge/Unreal-0E1128?style=for-the-badge&logo=unrealengine&logoColor=white" alt="Unreal"/>
  <img src="https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript"/>
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"/>
</p>

**자율 에이전트가 관리하는 지능형 프로젝트 오케스트레이션 프레임워크**

*Autonomous • Scalable • Game-Engine Ready*

</div>
```

## 2. 4-에이전트 아키텍처 다이어그램

```mermaid
graph TB
    %% 외부 입력
    USER[👤 사용자<br/>요청/피드백]
    EMAIL[📧 이메일<br/>알림]
    CLOCK[⏰ 시간 트리거<br/>정기 실행]

    %% 4대 에이전트 (핵심 순환)
    SUP[🎯 Supervisor<br/>감독관]
    DEV[👨‍💻 Developer<br/>개발자]
    REV[👀 Reviewer<br/>리뷰어]
    CLI[🎮 Client<br/>클라이언트]

    %% 데이터 레이어
    subgraph "📊 데이터 레이어"
        BOARD[(📋 BOARD.md<br/>태스크 보드)]
        CONFIG[(⚙️ project.config.md<br/>프로젝트 설정)]
        BACKLOG[(📚 BACKLOG_RESERVE.md<br/>예비 태스크)]
        LOGS[(📄 로그 파일들<br/>agents/logs/)]
    end

    %% 외부 시스템
    subgraph "🌐 외부 시스템"
        GIT[(🔄 Git Repository<br/>버전 관리)]
        MCP[🔌 MCP 서버<br/>Unity/Godot 연동]
        API[🤖 Claude API<br/>AI 모델]
        FILES[(📁 프로젝트 파일들<br/>Assets/Scripts)]
    end

    %% 입력 흐름
    USER -.->|요청| SUP
    EMAIL -.->|알림| SUP
    CLOCK -.->|트리거| SUP
    CLOCK -.->|트리거| DEV
    CLOCK -.->|트리거| REV
    CLOCK -.->|트리거| CLI

    %% 에이전트 간 순환
    SUP ===|"태스크 배정<br/>우선순위 조정"| DEV
    DEV ===|"구현 완료<br/>리뷰 요청"| REV
    REV ===|"승인/반려<br/>품질 검증"| CLI
    CLI ===|"엔진 검증<br/>실행 테스트"| SUP

    %% 데이터 접근
    SUP <-.->|R/W| BOARD
    SUP <-.->|R/W| BACKLOG
    SUP <-.->|R| CONFIG

    DEV <-.->|R/W| BOARD
    DEV <-.->|R| BACKLOG
    DEV <-.->|R| CONFIG

    REV <-.->|R/W| BOARD
    REV <-.->|R| CONFIG

    CLI <-.->|R/W| BOARD
    CLI <-.->|R| CONFIG

    %% 모든 에이전트 공통
    SUP <-.->|로그 기록| LOGS
    DEV <-.->|로그 기록| LOGS
    REV <-.->|로그 기록| LOGS
    CLI <-.->|로그 기록| LOGS

    %% 외부 시스템 연동
    DEV <-.->|커밋/푸시| GIT
    REV <-.->|브랜치 생성| GIT
    CLI <-.->|엔진 상태 쿼리| MCP

    SUP <-.->|AI 요청| API
    DEV <-.->|코드 생성| API
    REV <-.->|리뷰 분석| API

    DEV <-.->|파일 수정| FILES
    CLI <-.->|빌드/테스트| FILES

    %% 스타일링
    classDef agent fill:#e1f5fe,stroke:#0277bd,stroke-width:3px,color:#000
    classDef data fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    classDef external fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef input fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000

    class SUP,DEV,REV,CLI agent
    class BOARD,CONFIG,BACKLOG,LOGS data
    class GIT,MCP,API,FILES external
    class USER,EMAIL,CLOCK input
```

## 3. 태스크 생명주기 플로우차트

```mermaid
flowchart TD
    %% 시작점
    START([⏰ 트리거 발생<br/>시간/사용자/이메일]) --> SUP_CHECK{🎯 Supervisor<br/>액션 결정}

    %% Supervisor 분기
    SUP_CHECK -->|asset_prep| SUP_ASSET[🎨 Asset 생성]
    SUP_CHECK -->|task_assign| SUP_ASSIGN[📋 태스크 배정]
    SUP_CHECK -->|priority_update| SUP_PRIORITY[⚡ 우선순위 조정]
    SUP_CHECK -->|email_check| SUP_EMAIL[📧 이메일 확인]

    SUP_ASSET --> BOARD_UPDATE1[(📋 BOARD 업데이트)]
    SUP_ASSIGN --> BOARD_UPDATE1
    SUP_PRIORITY --> BOARD_UPDATE1
    SUP_EMAIL --> BOARD_UPDATE1

    BOARD_UPDATE1 --> DEV_TRIGGER[🔔 Developer 트리거]

    %% Developer 처리
    DEV_TRIGGER --> DEV_CHECK{👨‍💻 Developer<br/>백로그 확인}
    DEV_CHECK -->|백로그 있음| DEV_IMPL[⚙️ 구현 작업]
    DEV_CHECK -->|백로그 없음| DEV_RESERVE[📚 예비 태스크 선택]
    DEV_CHECK -->|In Progress 있음| DEV_CONTINUE[🔄 기존 작업 계속]

    DEV_IMPL --> DEV_CODE[💻 코드 작성/수정]
    DEV_RESERVE --> DEV_CODE
    DEV_CONTINUE --> DEV_CODE

    DEV_CODE --> DEV_DONE{작업 완료?}
    DEV_DONE -->|Yes| DEV_COMMIT[💾 Git 커밋]
    DEV_DONE -->|No| DEV_CODE

    DEV_COMMIT --> BOARD_UPDATE2[(📋 BOARD 업데이트<br/>Done → Review)]

    BOARD_UPDATE2 --> REV_TRIGGER[🔔 Reviewer 트리거]

    %% Reviewer 처리
    REV_TRIGGER --> REV_CHECK{👀 Reviewer<br/>리뷰 대상 확인}
    REV_CHECK -->|리뷰 있음| REV_ANALYZE[🔍 코드 분석]
    REV_CHECK -->|리뷰 없음| REV_WAIT[⏸️ 대기]

    REV_ANALYZE --> REV_SCORE[📊 품질 점수 산정]
    REV_SCORE --> REV_DECISION{승인 여부}

    REV_DECISION -->|승인| REV_APPROVE[✅ 승인 처리]
    REV_DECISION -->|반려| REV_REJECT[❌ 반려 처리]

    REV_APPROVE --> BOARD_UPDATE3[(📋 BOARD 업데이트<br/>Review → Done)]
    REV_REJECT --> BOARD_UPDATE4[(📋 BOARD 업데이트<br/>Review → Backlog)]

    BOARD_UPDATE3 --> CLI_TRIGGER[🔔 Client 트리거]
    BOARD_UPDATE4 --> DEV_TRIGGER

    %% Client 처리
    CLI_TRIGGER --> CLI_CHECK{🎮 Client<br/>검증 대상 확인}
    CLI_CHECK -->|검증 있음| CLI_ENGINE[🔌 엔진 상태 확인]
    CLI_CHECK -->|검증 없음| CLI_WAIT[⏸️ 대기]

    CLI_ENGINE --> CLI_BUILD{빌드/실행 테스트}
    CLI_BUILD -->|성공| CLI_SUCCESS[✅ 최종 승인]
    CLI_BUILD -->|실패| CLI_FAIL[❌ 실패 보고]

    CLI_SUCCESS --> BOARD_FINAL[(📋 최종 완료 표시)]
    CLI_FAIL --> BOARD_UPDATE5[(📋 긴급 태스크 생성<br/>P0 우선순위)]

    BOARD_UPDATE5 --> SUP_TRIGGER[🔔 Supervisor 트리거]
    BOARD_FINAL --> STATS[📊 통계 업데이트]

    %% 순환
    SUP_TRIGGER --> SUP_CHECK
    REV_WAIT --> NEXT_CYCLE[⏱️ 다음 사이클 대기]
    CLI_WAIT --> NEXT_CYCLE
    STATS --> NEXT_CYCLE
    NEXT_CYCLE --> START

    %% 스타일링
    classDef supervisor fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef developer fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef reviewer fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef client fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef board fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px
    classDef decision fill:#ffebee,stroke:#d32f2f,stroke-width:2px

    class SUP_CHECK,SUP_ASSET,SUP_ASSIGN,SUP_PRIORITY,SUP_EMAIL,SUP_TRIGGER supervisor
    class DEV_CHECK,DEV_IMPL,DEV_RESERVE,DEV_CONTINUE,DEV_CODE,DEV_DONE,DEV_COMMIT,DEV_TRIGGER developer
    class REV_CHECK,REV_ANALYZE,REV_SCORE,REV_DECISION,REV_APPROVE,REV_REJECT,REV_TRIGGER,REV_WAIT reviewer
    class CLI_CHECK,CLI_ENGINE,CLI_BUILD,CLI_SUCCESS,CLI_FAIL,CLI_TRIGGER,CLI_WAIT client
    class BOARD_UPDATE1,BOARD_UPDATE2,BOARD_UPDATE3,BOARD_UPDATE4,BOARD_UPDATE5,BOARD_FINAL board
    class REV_DECISION,CLI_BUILD,DEV_DONE decision
```

## 4. 시스템 컴포넌트 상호작용 다이어그램

```mermaid
sequenceDiagram
    participant U as 👤 사용자
    participant S as 🎯 Supervisor
    participant D as 👨‍💻 Developer
    participant R as 👀 Reviewer
    participant C as 🎮 Client
    participant B as 📋 BOARD
    participant G as 🔄 Git

    Note over U,G: 새로운 기능 요청 시나리오

    U->>S: 기능 요청 (이메일/CLI)
    S->>B: BOARD 분석
    S->>B: 새 태스크 생성

    Note over S,B: 태스크 우선순위 배정
    S->>B: 우선순위 설정 (P1)
    S->>D: 개발 작업 알림

    D->>B: 백로그 확인
    D->>D: 구현 작업 수행
    D->>G: 코드 커밋
    D->>B: 상태 업데이트 (Done→Review)

    R->>B: 리뷰 대상 확인
    R->>G: 코드 분석
    R->>R: 품질 점수 산정

    alt 승인
        R->>B: 승인 처리 (Review→Done)
        R->>C: 검증 요청 알림

        C->>B: 검증 대상 확인
        C->>C: 엔진 상태 검증
        C->>C: 빌드/실행 테스트

        alt 테스트 성공
            C->>B: 최종 승인
            C->>U: 완료 알림
        else 테스트 실패
            C->>B: 긴급 태스크 생성 (P0)
            C->>S: 실패 알림
        end

    else 반려
        R->>B: 반려 처리 (Review→Backlog)
        R->>D: 재작업 요청
    end

    Note over S,C: 지속적인 모니터링 루프
    loop 정기 실행
        S->>B: BOARD 상태 체크
        D->>B: 백로그 확인
        R->>B: 리뷰 대기열 확인
        C->>B: 검증 대기열 확인
    end
```

## 5. 기술 스택 아키텍처

```mermaid
graph TB
    subgraph "🎯 에이전트 레이어"
        SUP[Supervisor<br/>Python + Claude API]
        DEV[Developer<br/>Python + Claude API]
        REV[Reviewer<br/>Python + Claude API]
        CLI[Client<br/>Python + MCP]
    end

    subgraph "🔄 오케스트레이션 레이어"
        SCHED[cron/스케줄러<br/>시간 트리거]
        COORD[Coordinator<br/>에이전트 조율]
        MONITOR[Monitor<br/>상태 감시]
    end

    subgraph "📊 데이터 레이어"
        MD[Markdown 파일<br/>BOARD/CONFIG]
        LOGS[로그 파일<br/>JSON/텍스트]
        CACHE[캐시<br/>임시 데이터]
    end

    subgraph "🌐 통합 레이어"
        GIT[Git<br/>버전 관리]
        MCP_SRV[MCP 서버<br/>Unity/Godot/Unreal]
        EMAIL[이메일<br/>Gmail API]
        API[Claude API<br/>Anthropic]
    end

    subgraph "🎮 프로젝트 레이어"
        UNITY[Unity 프로젝트<br/>C# Scripts]
        GODOT[Godot 프로젝트<br/>GDScript/C#]
        UNREAL[Unreal 프로젝트<br/>C++/Blueprint]
        WEB[웹 프로젝트<br/>TypeScript/React]
        PYTHON[Python 프로젝트<br/>모듈/패키지]
    end

    %% 연결
    SCHED --> SUP
    SCHED --> DEV
    SCHED --> REV
    SCHED --> CLI

    COORD <--> SUP
    COORD <--> DEV
    COORD <--> REV
    COORD <--> CLI

    SUP <--> MD
    DEV <--> MD
    REV <--> MD
    CLI <--> MD

    SUP --> LOGS
    DEV --> LOGS
    REV --> LOGS
    CLI --> LOGS

    MONITOR --> LOGS
    MONITOR --> MD

    DEV --> GIT
    REV --> GIT
    CLI --> MCP_SRV
    SUP --> EMAIL

    SUP --> API
    DEV --> API
    REV --> API

    MCP_SRV <--> UNITY
    MCP_SRV <--> GODOT
    MCP_SRV <--> UNREAL

    DEV <--> WEB
    DEV <--> PYTHON

    %% 스타일
    classDef agent fill:#e1f5fe,stroke:#0277bd
    classDef orchestration fill:#f3e5f5,stroke:#7b1fa2
    classDef data fill:#e8f5e8,stroke:#2e7d32
    classDef integration fill:#fff3e0,stroke:#f57c00
    classDef project fill:#ffebee,stroke:#c62828

    class SUP,DEV,REV,CLI agent
    class SCHED,COORD,MONITOR orchestration
    class MD,LOGS,CACHE data
    class GIT,MCP_SRV,EMAIL,API integration
    class UNITY,GODOT,UNREAL,WEB,PYTHON project
```

## 6. 배지 및 상태 표시

### 에이전트 상태 배지
```markdown
![Supervisor](https://img.shields.io/badge/Supervisor-🟢%20Active-brightgreen)
![Developer](https://img.shields.io/badge/Developer-🟢%20Active-brightgreen)
![Reviewer](https://img.shields.io/badge/Reviewer-🟡%20Waiting-yellow)
![Client](https://img.shields.io/badge/Client-🔴%20Error-red)
```

### 진행률 배지
```markdown
![Progress](https://img.shields.io/badge/Progress-75%25-blue)
![Tasks](https://img.shields.io/badge/Tasks-12%2F16-orange)
![Quality](https://img.shields.io/badge/Quality-A%2B-brightgreen)
```

### 지원 플랫폼 배지
```markdown
![Unity](https://img.shields.io/badge/Unity-2022.3+-000000?logo=unity)
![Godot](https://img.shields.io/badge/Godot-4.0+-478CBF?logo=godot-engine)
![Unreal](https://img.shields.io/badge/Unreal-5.0+-0E1128?logo=unrealengine)
```

## 7. 사용 예시

### README.md 헤더 예시
```markdown
<div align="center">

# 🎯 Multi-Agent Orchestration Framework

**자율 AI 에이전트로 구동되는 게임 개발 오케스트레이션**

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?logo=python)](https://python.org)
[![Claude](https://img.shields.io/badge/Claude-API-FF6B35?logo=anthropic)](https://claude.ai)

![Agents](https://img.shields.io/badge/Supervisor-🟢%20Active-brightgreen)
![Developer](https://img.shields.io/badge/Developer-🟢%20Active-brightgreen)
![Reviewer](https://img.shields.io/badge/Reviewer-🟢%20Active-brightgreen)
![Client](https://img.shields.io/badge/Client-🟡%20Waiting-yellow)

**지원 엔진**

![Unity](https://img.shields.io/badge/Unity-2022.3+-000000?logo=unity&logoColor=white)
![Godot](https://img.shields.io/badge/Godot-4.0+-478CBF?logo=godot-engine&logoColor=white)
![Unreal](https://img.shields.io/badge/Unreal-5.0+-0E1128?logo=unrealengine&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?logo=typescript&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)

---

*4개의 전문 AI 에이전트가 자율적으로 협업하여 프로젝트를 관리하고 개발합니다*

</div>
```

## 관련 파일
- `README.md` - 메인 프로젝트 문서
- `docs/architecture.md` - 상세 아키텍처 문서
- `docs/agent-specs.md` - 에이전트 역할 정의