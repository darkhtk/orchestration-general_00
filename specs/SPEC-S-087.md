# SPEC-S-087: MCP 엔진 통합 클라이언트 코드 구현

> **태스크 ID:** S-087
> **우선순위:** P1
> **관련 BACKLOG_RESERVE:** R-012
> **작성일:** 2026-04-16

## 목표

CLIENT 에이전트의 검증 1(엔진 검증)에서 MCP-Unity 등 MCP 클라이언트를 실제로 연동하여 에디터 상태를 쿼리하는 기능을 구현한다.

## 배경

현재 CLIENT 에이전트는 검증 1에서 "엔진 연결 상태 확인"을 로그로만 출력하고 있다. 실제 MCP 클라이언트와 연동하여 Unity/Godot/Unreal 에디터의 실시간 상태를 쿼리하고 결과를 BOARD에 반영해야 한다.

## 요구사항

### 1. MCP 클라이언트 연동 아키텍처

#### 1.1 지원할 MCP 클라이언트
- **MCP-Unity**: Unity Editor 상태 조회
- **MCP-Godot**: Godot Editor 상태 조회
- **MCP-Unreal**: Unreal Editor 상태 조회

#### 1.2 연동 방식
- HTTP API 기반 통신 (각 MCP 클라이언트가 HTTP 서버로 동작)
- JSON 형태의 요청/응답
- 타임아웃: 5초
- 실패 시 재시도: 최대 2회

### 2. 엔진별 상태 쿼리 스펙

#### 2.1 Unity MCP 연동
**요청:**
```json
GET /unity/status
```

**응답:**
```json
{
  "status": "connected|disconnected",
  "version": "2023.3.0f1",
  "project_path": "/path/to/project",
  "scene_name": "MainScene",
  "compilation_errors": 0,
  "last_build": "2026-04-16T10:30:00Z"
}
```

#### 2.2 Godot MCP 연동
**요청:**
```json
GET /godot/status
```

**응답:**
```json
{
  "status": "connected|disconnected",
  "version": "4.2.1",
  "project_path": "/path/to/project.godot",
  "current_scene": "Main.tscn",
  "editor_errors": 0,
  "last_export": "2026-04-16T10:25:00Z"
}
```

#### 2.3 Unreal MCP 연동
**요청:**
```json
GET /unreal/status
```

**응답:**
```json
{
  "status": "connected|disconnected",
  "version": "5.3.0",
  "project_name": "MyProject",
  "current_level": "ThirdPersonMap",
  "compile_errors": 0,
  "last_cook": "2026-04-16T10:20:00Z"
}
```

### 3. CLIENT 에이전트 수정사항

#### 3.1 새로운 함수 추가
```bash
# scripts/client.sh에 추가할 함수들

check_mcp_unity() {
    local port=${MCP_UNITY_PORT:-8080}
    local response=$(curl -s --max-time 5 "http://localhost:$port/unity/status" 2>/dev/null)
    if [[ $? -eq 0 && -n "$response" ]]; then
        echo "$response" | jq -r '.status'
    else
        echo "disconnected"
    fi
}

check_mcp_godot() {
    local port=${MCP_GODOT_PORT:-8081}
    local response=$(curl -s --max-time 5 "http://localhost:$port/godot/status" 2>/dev/null)
    if [[ $? -eq 0 && -n "$response" ]]; then
        echo "$response" | jq -r '.status'
    else
        echo "disconnected"
    fi
}

check_mcp_unreal() {
    local port=${MCP_UNREAL_PORT:-8082}
    local response=$(curl -s --max-time 5 "http://localhost:$port/unreal/status" 2>/dev/null)
    if [[ $? -eq 0 && -n "$response" ]]; then
        echo "$response" | jq -r '.status'
    else
        echo "disconnected"
    fi
}

verify_engine_connection() {
    local project_type=$(grep "project_type" project.config.md | cut -d: -f2 | xargs)
    local engine_status="disconnected"

    case "$project_type" in
        "unity")
            engine_status=$(check_mcp_unity)
            ;;
        "godot")
            engine_status=$(check_mcp_godot)
            ;;
        "unreal")
            engine_status=$(check_mcp_unreal)
            ;;
        *)
            log_client "INFO: 엔진 타입 '$project_type'은 MCP 연동을 지원하지 않습니다."
            return 0
            ;;
    esac

    if [[ "$engine_status" == "connected" ]]; then
        log_client "✅ 엔진 연결 상태: 정상 ($project_type)"
        return 0
    else
        log_client "❌ 엔진 연결 실패: $project_type MCP 클라이언트에 연결할 수 없습니다."
        return 1
    fi
}
```

#### 3.2 검증 1 스텝 수정
기존 `verification_step_1()` 함수에서:
```bash
verification_step_1() {
    log_client "=== 검증 1: 엔진 연결 상태 확인 ==="

    if verify_engine_connection; then
        log_client "엔진 연결 검증 완료"
    else
        log_client "엔진 연결 실패 - MCP 클라이언트 상태를 확인하세요"
        create_engine_connection_task
        return 1
    fi
}

create_engine_connection_task() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local task_content="ENGINE_CONNECTION_FAILED: MCP 클라이언트 연결 실패 감지 ($timestamp)"

    # BOARD.md에 P0 태스크 추가
    add_task_to_board "P0" "$task_content" "엔진 MCP 연결 실패"
}
```

### 4. 환경 설정

#### 4.1 .env 파일에 추가
```bash
# MCP 클라이언트 포트 설정
MCP_UNITY_PORT=8080
MCP_GODOT_PORT=8081
MCP_UNREAL_PORT=8082

# MCP 연결 타임아웃 (초)
MCP_TIMEOUT=5

# MCP 재시도 횟수
MCP_RETRY_COUNT=2
```

#### 4.2 의존성 추가
- `jq`: JSON 파싱용 (대부분 시스템에 설치됨)
- `curl`: HTTP 요청용 (대부분 시스템에 설치됨)

### 5. 에러 핸들링

#### 5.1 연결 실패 시나리오
1. MCP 클라이언트가 실행되지 않음
2. 네트워크 연결 실패
3. 포트 충돌
4. JSON 응답 파싱 실패

#### 5.2 에러 로깅 형식
```
[CLIENT] ERROR: Unity MCP 연결 실패 (localhost:8080) - Connection refused
[CLIENT] ERROR: Godot MCP 응답 파싱 실패 - Invalid JSON format
[CLIENT] WARN: Unreal MCP 타임아웃 (5초) - 재시도 중 (1/2)
```

### 6. 테스트 시나리오

#### 6.1 Unity 프로젝트 테스트
1. Unity Editor와 MCP-Unity 플러그인 실행
2. CLIENT 에이전트 실행
3. 검증 1에서 "connected" 상태 확인

#### 6.2 연결 실패 테스트
1. MCP 클라이언트 종료 상태에서 CLIENT 실행
2. "disconnected" 상태 확인 및 P0 태스크 생성 확인

#### 6.3 포트 변경 테스트
1. .env에서 포트 변경
2. MCP 클라이언트도 동일한 포트로 실행
3. 정상 연결 확인

## 구현 파일
- `scripts/client.sh` 수정
- `scripts/.env.example` 업데이트
- `docs/MCP_INTEGRATION.md` 생성 (사용법 문서)

## 완료 기준
- [ ] Unity/Godot/Unreal MCP 연동 함수 구현
- [ ] 검증 1에서 실제 엔진 상태 확인
- [ ] 연결 실패 시 P0 태스크 자동 생성
- [ ] 3가지 엔진 타입 모두 테스트 완료
- [ ] 에러 핸들링 및 로깅 구현
- [ ] 환경 설정 문서화