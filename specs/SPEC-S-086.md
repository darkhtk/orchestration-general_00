# SPEC-S-086: Python 프로젝트 자동 감지 기능 구현

> **태스크 ID:** S-086
> **우선순위:** P2
> **관련 BACKLOG_RESERVE:** R-007
> **작성일:** 2026-04-16

## 목표

auto-setup.sh에 Python 프로젝트 자동 감지 및 설정 생성 로직을 추가한다.

## 요구사항

### 1. Python 프로젝트 감지 기준

다음 파일 중 하나 이상이 존재하면 Python 프로젝트로 감지:
- `requirements.txt`
- `pyproject.toml`
- `setup.py`
- `Pipfile`
- `poetry.lock`
- `.python-version`

### 2. 프로젝트 유형별 세부 감지

#### 2.1 Django 프로젝트
- `manage.py` 파일 존재
- `settings.py` 또는 `settings/` 디렉토리 존재
- 감지 시 project_type: "python-django"

#### 2.2 Flask 프로젝트
- `app.py` 또는 `main.py` 존재
- requirements.txt에 "flask" 포함
- 감지 시 project_type: "python-flask"

#### 2.3 FastAPI 프로젝트
- requirements.txt에 "fastapi" 포함
- main.py 또는 app.py 존재
- 감지 시 project_type: "python-fastapi"

#### 2.4 일반 Python 프로젝트
- 위 조건에 해당하지 않는 경우
- 감지 시 project_type: "python-general"

### 3. 생성할 설정 파일

#### 3.1 project.config.md
```markdown
# Python 프로젝트 설정

## 프로젝트 정보
- **유형:** {detected_type}
- **Python 버전:** {detected_version}
- **메인 모듈:** {detected_main_file}

## 개발 환경
- **패키지 매니저:** {detected_package_manager}
- **가상 환경:** {detected_venv_path}

## 테스트 설정
- **테스트 프레임워크:** {detected_test_framework}
- **테스트 경로:** tests/
- **커버리지 목표:** 80%

## 코딩 스타일
- **Formatter:** black
- **Linter:** flake8 or ruff
- **Type Checker:** mypy

## 빌드/배포
- **엔트리 포인트:** {main_file}
- **종속성 파일:** {requirements_file}
```

#### 3.2 .gitignore 업데이트
Python 관련 항목 추가:
```
__pycache__/
*.py[cod]
*$py.class
.venv/
venv/
.env
.pytest_cache/
.coverage
dist/
build/
*.egg-info/
```

### 4. auto-setup.sh 수정 사항

#### 4.1 detect_project_type() 함수 확장
```bash
detect_python_project() {
    # requirements.txt 체크
    if [[ -f "requirements.txt" ]]; then
        if grep -q "django" requirements.txt; then
            echo "python-django"
        elif grep -q "flask" requirements.txt; then
            echo "python-flask"
        elif grep -q "fastapi" requirements.txt; then
            echo "python-fastapi"
        else
            echo "python-general"
        fi
        return 0
    fi

    # pyproject.toml 체크
    if [[ -f "pyproject.toml" ]]; then
        if grep -q "django" pyproject.toml; then
            echo "python-django"
        elif grep -q "flask" pyproject.toml; then
            echo "python-flask"
        elif grep -q "fastapi" pyproject.toml; then
            echo "python-fastapi"
        else
            echo "python-general"
        fi
        return 0
    fi

    # manage.py 체크 (Django 특화)
    if [[ -f "manage.py" ]]; then
        echo "python-django"
        return 0
    fi

    # 기타 Python 파일들
    if [[ -f "setup.py" || -f "Pipfile" || -f "poetry.lock" || -f ".python-version" ]]; then
        echo "python-general"
        return 0
    fi

    return 1
}
```

#### 4.2 Python 버전 감지
```bash
detect_python_version() {
    if [[ -f ".python-version" ]]; then
        cat .python-version
    elif [[ -f "pyproject.toml" ]] && grep -q "python" pyproject.toml; then
        grep "python" pyproject.toml | head -1 | sed 's/.*python.*=.*"\([0-9.]*\)".*/\1/'
    else
        python3 --version 2>/dev/null | awk '{print $2}' || echo "3.9+"
    fi
}
```

#### 4.3 패키지 매니저 감지
```bash
detect_package_manager() {
    if [[ -f "poetry.lock" ]]; then
        echo "poetry"
    elif [[ -f "Pipfile" ]]; then
        echo "pipenv"
    elif [[ -f "requirements.txt" ]]; then
        echo "pip"
    else
        echo "pip"
    fi
}
```

## 구현 파일
- `scripts/auto-setup.sh` 수정
- `sample-config/python-django.config.md` 생성
- `sample-config/python-flask.config.md` 생성
- `sample-config/python-fastapi.config.md` 생성
- `sample-config/python-general.config.md` 생성

## 테스트 시나리오

1. **Django 프로젝트 테스트**
   - manage.py가 있는 디렉토리에서 실행
   - python-django 타입으로 감지되는지 확인

2. **Flask 프로젝트 테스트**
   - requirements.txt에 flask가 포함된 프로젝트
   - python-flask 타입으로 감지되는지 확인

3. **FastAPI 프로젝트 테스트**
   - requirements.txt에 fastapi가 포함된 프로젝트
   - python-fastapi 타입으로 감지되는지 확인

4. **일반 Python 프로젝트 테스트**
   - setup.py만 있는 프로젝트
   - python-general 타입으로 감지되는지 확인

## 완료 기준
- [ ] Python 프로젝트 타입 자동 감지 구현
- [ ] 각 타입별 project.config.md 템플릿 생성
- [ ] .gitignore 자동 업데이트
- [ ] 4가지 테스트 시나리오 모두 통과
- [ ] 기존 웹 프로젝트 감지 기능에 영향 없음