@echo off
setlocal enabledelayedexpansion

set "TEMPLATE=%~dp0"
if "!TEMPLATE:~-1!"=="\" set "TEMPLATE=!TEMPLATE:~0,-1!"

if "%~1"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!TEMPLATE!\pick-folder.ps1"') do set "PROJECT=%%i"
) else (
    set "PROJECT=%~1"
)

if "!PROJECT!"=="CANCELLED" exit /b 0
if "!PROJECT!"=="" (
    echo No folder selected.
    pause
    exit /b 1
)

echo.
echo  ============================================
echo   Orchestration Monitor
echo  ============================================
echo.
echo  Project: !PROJECT!
echo.
echo  1^) Snapshot now
echo  2^) Watch live
echo.
set /p "CHOICE=  Choice (1/2): "

if "!CHOICE!"=="2" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!TEMPLATE!\monitor-orchestration.ps1" -Project "!PROJECT!" -Watch
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!TEMPLATE!\monitor-orchestration.ps1" -Project "!PROJECT!"
)

pause
exit /b 0
