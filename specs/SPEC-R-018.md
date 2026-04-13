# SPEC-R-018: 에이전트 루프 완료 알림

**관련 태스크:** R-018
**작성일:** 2026-04-13

---

## 개요
에이전트 루프 완료/에러 발생 시 데스크톱 알림(토스트) 또는 사운드를 재생하는 알림 시스템.

## 상세 설명
에이전트가 백그라운드에서 실행 중일 때 중요 이벤트(태스크 완료, 리뷰 결과, 에러 발생, FREEZE 감지)를 사용자에게 데스크톱 알림으로 전달한다. Windows 토스트 알림, macOS 알림 센터, Linux notify-send를 OS별로 활용하고, 선택적으로 사운드 알림도 지원한다.

## 수치/밸런스
| 항목 | 값 | 비고 |
|------|---|------|
| 알림 트리거 | 태스크 완료, APPROVE, NEEDS_WORK, CRITICAL 에러, FREEZE | 이벤트별 |
| 알림 방식 (Windows) | PowerShell BurntToast 또는 [Windows.UI.Notifications] | 토스트 알림 |
| 알림 방식 (macOS) | `osascript -e 'display notification'` | 알림 센터 |
| 알림 방식 (Linux) | `notify-send` | libnotify |
| 사운드 알림 | 선택적 (config에서 on/off) | 시스템 사운드 활용 |
| 알림 빈도 제한 | 최소 30초 간격 | 알림 홍수 방지 |
| 설정 위치 | project.config.md `notifications` 섹션 | 활성/비활성, 이벤트 필터 |

## 데이터 구조
```bash
# notify.sh 인터페이스
notify.sh --title "태스크 완료" --message "TASK-037: 인벤토리 정렬 → Done" --level info
notify.sh --title "리뷰 결과" --message "TASK-037: APPROVE" --level success
notify.sh --title "에러 감지" --message "CRITICAL: NullReferenceException" --level error
notify.sh --title "FREEZE" --message "오케스트레이션 정지됨" --level warning
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| 에이전트 runner (.run_*.sh) | notify.sh | 이벤트 발생 시 호출 |
| watchdog.sh (R-002) | notify.sh | 크래시/FREEZE 시 호출 |
| notify.sh | OS 알림 시스템 | OS별 분기 |
| project.config.md | notify.sh | 알림 설정 읽기 |

## UI 와이어프레임
```
┌──────────────────────────────────┐
│ 🔔 Orchestration                 │
│ ──────────────────────────────── │
│ ✅ TASK-037 완료: 인벤토리 정렬  │
│ APPROVE by Client (4/4 통과)     │
│                        [닫기]    │
└──────────────────────────────────┘
(Windows 토스트 알림 예시)
```

## 호출 진입점
- **어디서:** 에이전트 실행 스크립트 내부 이벤트 감지 시점
- **어떻게:** `source notify.sh && send_notification "title" "message" "level"`

## 수용 기준
- [ ] `notify.sh` 스크립트 구현 (OS 자동 감지 + 분기)
- [ ] Windows 토스트 알림 (PowerShell)
- [ ] macOS 알림 센터 (`osascript`)
- [ ] Linux notify-send
- [ ] 알림 레벨별 아이콘/색상 구분 (info/success/warning/error)
- [ ] 30초 최소 간격 제한 (알림 홍수 방지)
- [ ] project.config.md에서 알림 on/off 및 이벤트 필터 설정 가능
- [ ] 알림 의존성 미설치 시 graceful skip (silent)
