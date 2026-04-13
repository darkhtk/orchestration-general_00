# SPEC-R-012: MCP 엔진 통합 (Client 검증 1 실동작)

**관련 태스크:** R-012
**작성일:** 2026-04-13

---

## 개요
Client의 검증 1(엔진 검증)에서 MCP(Model Context Protocol) 서버를 실제로 연동하여 에디터 상태를 쿼리하는 기능 구현.

## 상세 설명
현재 Client 프롬프트의 검증 1(엔진 검증)에서 MCP-Unity 등을 참조하지만, 실제 MCP 클라이언트 코드가 없어 에디터 상태를 직접 쿼리할 수 없다. MCP 서버(Unity용 MCP-Unity, Godot용 MCP-Godot 등)와 통신하여 씬 구조, 컴포넌트 상태, 프리팹 유효성, 빌드 설정 등을 프로그래매틱하게 검증하는 MCP 클라이언트 래퍼를 구현한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| MCP 서버 (Unity) | MCP-Unity | 별도 설치 필요 |
| MCP 서버 (Godot) | MCP-Godot (또는 커스텀) | 커뮤니티 프로젝트 |
| 통신 프로토콜 | stdio 또는 HTTP SSE | MCP 표준 |
| 쿼리 타임아웃 | 10초 | 에디터 응답 대기 |
| 폴백 | 코드 분석 기반 검증 | MCP 미설치 시 |

## 데이터 구조
```bash
# MCP 쿼리 래퍼 스크립트
mcp-query.sh --engine unity --query "list_scenes"
mcp-query.sh --engine unity --query "get_components GameObject:Player"
mcp-query.sh --engine unity --query "check_build_settings"

# 결과 (JSON)
{
  "status": "ok",
  "result": {
    "scenes": ["MainMenu", "Gameplay", "Settings"],
    "active_scene": "Gameplay"
  }
}
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| Client 프롬프트 (검증 1) | mcp-query.sh | 쉘 명령 실행 |
| mcp-query.sh | MCP 서버 (Unity/Godot) | stdio/SSE 프로토콜 |
| MCP 서버 | 게임 에디터 | 에디터 API |
| mcp-query.sh | REVIEW-XXX.md | 검증 결과를 리뷰에 포함 |
| project.config.md | mcp-query.sh | MCP 서버 설정 읽기 |

## UI 와이어프레임
N/A

## 호출 진입점
- **어디서:** Client 리뷰 루프의 검증 1 단계
- **어떻게:** `./mcp-query.sh --engine unity --query "QUERY_NAME"` (Client가 프롬프트 내에서 실행)

## 수용 기준
- [ ] `mcp-query.sh` 래퍼 스크립트 구현 (MCP 프로토콜 통신)
- [ ] Unity MCP 서버 연동: 씬 목록, 컴포넌트 조회, 빌드 설정 확인
- [ ] Godot MCP 서버 연동: 노드 트리, 스크립트 상태 조회 (가능 시)
- [ ] MCP 서버 미설치/미실행 시 graceful 폴백 (코드 분석 기반)
- [ ] 쿼리 타임아웃 처리 (10초 초과 시 skip + 로그)
- [ ] project.config.md에 MCP 설정 섹션 추가 (서버 경로, 활성화 여부)
- [ ] Client 프롬프트에 MCP 쿼리 사용 가이드 추가
