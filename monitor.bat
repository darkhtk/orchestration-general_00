@echo off
setlocal enabledelayedexpansion

set "TEMPLATE=%~dp0"
if "!TEMPLATE:~-1!"=="\" set "TEMPLATE=!TEMPLATE:~0,-1!"

set "GITBASH="
if exist "C:\Program Files\Git\bin\bash.exe" (
    set "GITBASH=C:\Program Files\Git\bin\bash.exe"
) else if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    set "GITBASH=C:\Program Files (x86)\Git\bin\bash.exe"
)

if "!GITBASH!"=="" (
    echo [ERROR] Git Bash not found. Install Git for Windows.
    pause
    exit /b 1
)

REM -- Project folder --
if "%~1"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!TEMPLATE!\pick-folder.ps1"') do set "PROJECT=%%i"
) else (
    set "PROJECT=%~1"
)

if "!PROJECT!"=="CANCELLED" ( exit /b 0 )
if "!PROJECT!"=="" ( echo No folder. & pause & exit /b 1 )

echo.
echo  ============================================
echo   Runtime Monitor
echo  ============================================
echo.
echo  Project: !PROJECT!
echo.
echo  1) Analyze now   (1-time scan)
echo  2) Watch live     (real-time monitor)
echo.
set /p "CHOICE=  Choice (1/2): "

if "!CHOICE!"=="1" (
    "!GITBASH!" "!TEMPLATE!\monitor.sh" "!PROJECT!" --analyze
) else (
    "!GITBASH!" "!TEMPLATE!\monitor.sh" "!PROJECT!"
)

pause
exit /b 0
