@echo off
setlocal enabledelayedexpansion

title Claude Orchestration

REM -- Template = this bat's directory --
set "TEMPLATE=%~dp0"
if "!TEMPLATE:~-1!"=="\" set "TEMPLATE=!TEMPLATE:~0,-1!"

echo.
echo  ============================================
echo   Claude Orchestration
echo  ============================================
echo.

REM ===========================================
REM  Dependency Check
REM ===========================================

set "ERRORS=0"
set "GITBASH="
set "HAS_WT=0"

REM -- [1] Git for Windows --
echo  [Check] Git for Windows...
if exist "C:\Program Files\Git\bin\bash.exe" (
    set "GITBASH=C:\Program Files\Git\bin\bash.exe"
) else if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    set "GITBASH=C:\Program Files (x86)\Git\bin\bash.exe"
)

if "!GITBASH!"=="" (
    echo          [MISSING] https://git-scm.com/download/win
    set /a ERRORS+=1
) else (
    echo          [OK]
)

REM -- [2] Claude CLI --
echo  [Check] Claude CLI...
where claude >nul 2>nul
if errorlevel 1 (
    echo          [MISSING] npm install -g @anthropic-ai/claude-code
    echo          Requires Node.js 18+: https://nodejs.org
    set /a ERRORS+=1
) else (
    echo          [OK]
)

REM -- [3] Template files --
echo  [Check] Template files...
if not exist "!TEMPLATE!\framework" (
    echo          [MISSING] framework/ not found in !TEMPLATE!
    set /a ERRORS+=1
) else (
    echo          [OK]
)

REM -- [4] Windows Terminal (optional) --
echo  [Check] Windows Terminal...
where wt.exe >nul 2>nul
if errorlevel 1 (
    echo          [SKIP] Not found - will use separate windows
    echo          Recommended: https://aka.ms/terminal
) else (
    set "HAS_WT=1"
    echo          [OK]
)

if !ERRORS! GTR 0 (
    echo:
    echo  !ERRORS! missing dependency[ies]. Install them and retry.
    pause
    exit /b 1
)

echo.
echo  All checks passed.
echo.

REM ===========================================
REM  Project Selection
REM ===========================================

if not "%~1"=="" (
    set "PROJECT=%~1"
    goto :project_selected
)

echo  Select your game project folder...
echo.

for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!TEMPLATE!\pick-folder.ps1"') do set "PROJECT=%%i"

:project_selected

if "!PROJECT!"=="CANCELLED" (
    echo  Cancelled.
    timeout /t 2 >nul
    exit /b 0
)
if "!PROJECT!"=="" (
    echo  No folder selected.
    pause
    exit /b 1
)

echo  Project:  !PROJECT!
echo.

REM ===========================================
REM  Existing orchestration check
REM ===========================================

if exist "!PROJECT!\orchestration\project.config.md" (
    echo  ----------------------------------------
    echo   Existing orchestration detected
    echo  ----------------------------------------
    echo:

    REM  Extract info from config
    for /f "tokens=2 delims=:" %%v in ('findstr /c:"** " "!PROJECT!\orchestration\project.config.md" 2^>nul ^| findstr /c:"모드"') do set "PREV_MODE=%%v"
    for /f "tokens=2 delims=:" %%v in ('findstr /c:"** " "!PROJECT!\orchestration\project.config.md" 2^>nul ^| findstr /c:"방향"') do set "PREV_DIR=%%v"

    echo   Mode:!PREV_MODE!
    echo   Direction:!PREV_DIR!
    echo:
    echo   1^) Resume    - launch agents only
    echo   2^) Reconfigure - re-run setup
    echo   3^) Cancel
    echo:
    set /p "ORCH_CHOICE=  Choice (1-3): "

    if "!ORCH_CHOICE!"=="1" goto :launch_agents
    if "!ORCH_CHOICE!"=="3" (
        echo  Cancelled.
        pause
        exit /b 0
    )
)

REM ===========================================
REM  [1/3] Auto Setup
REM ===========================================

echo  [1/3] Setting up orchestration...
echo.
"!GITBASH!" "!TEMPLATE!\auto-setup.sh" "!PROJECT!"

if errorlevel 1 (
    echo:
    echo  [ERROR] Setup failed.
    pause
    exit /b 1
)

if not exist "!PROJECT!\orchestration\.run_DEVELOPER.sh" (
    echo:
    echo  [ERROR] Runner scripts not created.
    pause
    exit /b 1
)

REM ===========================================
REM  [2/3] Extract features + Seed backlog
REM ===========================================

echo.
echo  ----------------------------------------
echo   Auto-generate tasks from project code?
echo   1^) Extract features + Generate tasks
echo   2^) Skip - add tasks manually later
echo  ----------------------------------------
echo.
set /p "SEED=  Choice (1/2): "
if "!SEED!"=="1" (
    echo:
    echo  [2/3a] Extracting feature list from code...
    echo:
    "!GITBASH!" "!TEMPLATE!\extract-features.sh" "!PROJECT!"
    echo:
    echo  [2/3b] Generating tasks from features...
    echo:
    "!GITBASH!" "!TEMPLATE!\seed-backlog.sh" "!PROJECT!"
    if errorlevel 1 (
        echo:
        echo  [WARN] Seed failed - you can add tasks manually later.
        echo:
    )
)

REM ===========================================
REM  Config review
REM ===========================================

echo.
echo  ----------------------------------------
echo   Review config if needed:
echo   !PROJECT!\orchestration\project.config.md
echo  ----------------------------------------
echo.
set /p "LAUNCH=  Launch agents? (Y/n): "
if /i "!LAUNCH!"=="n" (
    echo:
    echo  Done. Run orchestrate.bat again to launch.
    pause
    exit /b 0
)

:launch_agents

REM ===========================================
REM  Launch agents
REM ===========================================

REM -- Detect which runners exist (matches agent mode) --
set "AGENT_COUNT=0"

echo.
echo  [3/3] Launching agents...
echo.

for %%A in (SUPERVISOR DEVELOPER CLIENT COORDINATOR) do (
    if exist "!PROJECT!\orchestration\.run_%%A.sh" (
        if "!HAS_WT!"=="1" (
            wt -w 0 new-tab --title "%%A" -d "!PROJECT!" "!GITBASH!" orchestration/.run_%%A.sh
        ) else (
            start "%%A" "!GITBASH!" "!PROJECT!\orchestration\.run_%%A.sh"
        )
        set /a AGENT_COUNT+=1
        timeout /t 3 /nobreak >nul
    )
)

echo.
echo  ============================================
echo   !AGENT_COUNT! agents launched!
echo  ============================================
echo.
echo   Stop all: Add FREEZE to BOARD.md
echo   Stop one: Ctrl+C in that tab
echo.
pause
exit /b 0
