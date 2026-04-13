# SPEC-R-005: 에러 모니터 Godot/Unreal 로그 경로 개선

**관련 태스크:** R-005
**작성일:** 2026-04-13

---

## 개요
monitor.sh에서 Godot와 Unreal Engine의 로그 파일 경로를 OS별로 정확하게 자동 감지하도록 개선.

## 상세 설명
현재 monitor.sh는 Unity Editor.log 경로를 잘 감지하지만, Godot와 Unreal의 로그 경로는 OS별/버전별 차이가 크고 자동 감지가 불완전하다. 각 엔진의 공식 로그 위치를 OS별로 매핑하고, project.config.md의 `error_log_path` 설정을 폴백으로 사용하는 다단계 감지 로직을 구현한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| Godot 로그 (Windows) | `%APPDATA%/Godot/app_userdata/PROJECT/logs/godot.log` | 4.x 기준 |
| Godot 로그 (macOS) | `~/Library/Application Support/Godot/app_userdata/PROJECT/logs/` | |
| Godot 로그 (Linux) | `~/.local/share/godot/app_userdata/PROJECT/logs/` | |
| Unreal 로그 (Windows) | `PROJECT/Saved/Logs/PROJECT.log` | 프로젝트 내부 |
| Unreal 로그 (macOS) | `PROJECT/Saved/Logs/PROJECT.log` | 동일 구조 |
| Unreal 로그 (Linux) | `PROJECT/Saved/Logs/PROJECT.log` | 동일 구조 |
| 감지 우선순위 | project.config > 자동 감지 > 기본 경로 | 3단계 폴백 |

## 데이터 구조
```bash
# monitor.sh 내부 로그 경로 해석 로직
detect_log_path() {
    # 1순위: project.config.md의 error_log_path
    # 2순위: 엔진별 OS별 자동 감지
    # 3순위: 프로젝트 디렉토리 내 Saved/Logs/ 스캔
}
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| monitor.sh | project.config.md | error_log_path 읽기 |
| monitor.sh | OS 환경변수 | %APPDATA%, $HOME 등 경로 해석 |
| monitor.sh | project.godot / *.uproject | 프로젝트명 추출 |
| monitor.sh | MONITOR.md | 감지된 로그 경로 기록 |

## UI 와이어프레임
```
$ ./monitor.sh
[모니터] 엔진: Godot 4.3
[모니터] 로그 경로: /home/user/.local/share/godot/app_userdata/MyGame/logs/godot.log
[모니터] 감시 시작... (Ctrl+C로 종료)
---
14:30:15 [ERROR] res://scripts/player.gd:42 - Invalid get index 'health'
14:30:15 [WARNING] res://scenes/main.tscn - Orphan node detected
```

## 호출 진입점
- **어디서:** 터미널에서 직접 실행 또는 launch.sh 연동
- **어떻게:** `./monitor.sh` (기존과 동일, 내부 로직만 개선)

## 수용 기준
- [ ] Godot 4.x 로그 경로 Windows/macOS/Linux 자동 감지
- [ ] Unreal Engine 로그 경로 자동 감지 (프로젝트 내 Saved/Logs/)
- [ ] project.config.md의 `error_log_path`가 설정되어 있으면 최우선 사용
- [ ] Godot 에러 패턴 파싱 (GDScript 에러, 씬 로딩 실패 등)
- [ ] Unreal 에러 패턴 파싱 (Fatal Error, Assertion Failed, LogError 등)
- [ ] 로그 경로 자동 감지 실패 시 명확한 안내 메시지 출력
- [ ] 기존 Unity 감지 로직에 영향 없음 (하위 호환)
