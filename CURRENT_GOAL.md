# Current Goal

## Current Focus / 현재 목표

지금 이 루프의 초점은 **A↔B 상호 개발 파이프라인 안에서 A 가 B 의 자동화 에이전트로부터 "A 가 진짜 필요로 하는 개선"을 받아낼 수 있게 만드는 것**이다. 이전 라이브 사이클에서 B 의 에이전트들이 A 의 tech stack 을 오해해 JavaScript/Python 코드를 A 저장소에 쌓는 문제가 발생했다. 현재 이 브리프 3종(이 파일 포함)이 작성된 직후이므로, 다음 BA(B→A) 캐너리 슬롯에서는 B 가 A 를 bash/batch/PowerShell 프레임워크로 정확히 인식하고 거기에 맞는 개선을 커밋하는지 확인하는 것이 최우선이다.

## Completion Criteria / 완료 기준

이 목표는 다음 조건 중 최소 **둘 이상** 충족 시 완료로 본다:

- **Done means #1:** 다음 BA 슬롯에서 생성된 커밋 5개 중 JavaScript/TypeScript/Python 새 파일이 0개
- **Done means #2:** 다음 BA 슬롯의 커밋 중 최소 1개가 기존 `.sh`/`.bat`/`.ps1` 파일을 의미있게 수정 (dead code 제거, 버그 픽스, 기능 추가 모두 해당)
- **Done means #3:** BOARD.md 상의 In Review 태스크에 대해 Client 가 APPROVE 또는 NEEDS_WORK verdict 를 tech-stack 근거로 내림 (즉 "JS 로 구현되었으니 맞지 않다" 같은 구체적 판단이 리뷰 파일에 등장)

## Checkpoint

완료 여부는 다음 BA 슬롯 종료 후 `git log kg-A-initial..slot/*-pm` 결과와 `orchestration/reviews/REVIEW-*.md` 내용을 함께 보고 판정한다. 판정 결과는 `docs/PROJECT_BRIEF_VALIDATION.md` (다음 사이클에서 작성) 에 기록해 다음 개선 루프의 기준점으로 사용한다.
