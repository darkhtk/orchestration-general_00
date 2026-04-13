# SPEC-R-007: Python 프로젝트 자동 감지 (auto-setup.sh)

**관련 태스크:** R-007
**작성일:** 2026-04-13

---

## 개요
auto-setup.sh에 requirements.txt, pyproject.toml, setup.py 기반 Python 프로젝트 자동 감지 로직 추가.

## 상세 설명
Python 프로젝트(Django, Flask, FastAPI, CLI 도구, 데이터 과학 등)를 감지하여 project.config.md를 자동 생성한다. Python 프로젝트는 게임 엔진과 달리 웹 프레임워크, 패키지 매니저(pip/poetry/uv), 테스트 러너(pytest/unittest), 린터(ruff/flake8) 등을 감지 항목으로 포함한다.

## 수치/밸런스
| 항목 | 감지 파일 | 비고 |
|------|----------|------|
| Python 프로젝트 | `requirements.txt` / `pyproject.toml` / `setup.py` | 기본 감지 |
| Django | `manage.py` + `settings.py` | 웹 프레임워크 |
| Flask | `pyproject.toml` → `flask` dep | 또는 `app.py` |
| FastAPI | `pyproject.toml` → `fastapi` dep | API 프레임워크 |
| Poetry | `pyproject.toml` → `[tool.poetry]` | 패키지 매니저 |
| uv | `uv.lock` | 최신 패키지 매니저 |
| pytest | `pytest.ini` / `pyproject.toml [tool.pytest]` | 테스트 러너 |
| ruff | `ruff.toml` / `pyproject.toml [tool.ruff]` | 린터 |

## 데이터 구조
```bash
# auto-setup.sh 감지 결과 (Python 프로젝트용)
ENGINE="Python"
ENGINE_VERSION="Python 3.12"    # python --version
LANGUAGE="Python"
FRAMEWORK="FastAPI"             # 또는 Django, Flask, None
PKG_MANAGER="poetry"            # pip, poetry, uv
TEST_RUNNER="pytest"
SOURCE_DIR="src/" or "app/"
TEST_DIR="tests/"
```

## 연동 경로
| From | To | 방식 |
|------|----|------|
| auto-setup.sh | pyproject.toml | TOML 파싱 (grep/sed 기반) |
| auto-setup.sh | requirements.txt | 패키지 목록에서 프레임워크 감지 |
| auto-setup.sh | python --version | Python 버전 추출 |
| auto-setup.sh | project.config.md | 설정 생성 |

## UI 와이어프레임
```
$ ./auto-setup.sh /path/to/python-api

[감지] 프로젝트 유형: Python (FastAPI)
[감지] Python 버전: 3.12.1
[감지] 패키지 관리: poetry
[감지] 테스트: pytest
[감지] 린터: ruff
[감지] 소스: src/
[감지] 테스트: tests/

project.config.md 생성 완료.
```

## 호출 진입점
- **어디서:** orchestrate.bat → auto-setup.sh (기존 흐름)
- **어떻게:** auto-setup.sh 내부 감지 로직 확장 (elif 분기, 웹 감지 후)

## 수용 기준
- [ ] pyproject.toml 또는 requirements.txt 존재 시 Python 프로젝트로 감지
- [ ] Django/Flask/FastAPI 프레임워크 자동 판별
- [ ] Python 버전 자동 추출
- [ ] 소스코드/테스트 디렉토리 자동 매핑
- [ ] 테스트 명령어 자동 추출 (pytest, unittest)
- [ ] 생성된 project.config.md가 기존 포맷과 호환
- [ ] 웹/게임 엔진 감지와 충돌 없이 순차 판별 (게임 엔진 > 웹 > Python 우선순위)
