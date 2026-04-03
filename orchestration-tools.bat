@echo off
setlocal enabledelayedexpansion

set "TEMPLATE=%~dp0"
if "!TEMPLATE:~-1!"=="\" set "TEMPLATE=!TEMPLATE:~0,-1!"

echo.
echo  ============================================
echo   Claude Orchestration Tools
echo  ============================================
echo.
echo  Recommended path:
echo  1. Setup or resume orchestration
echo  2. Monitor progress
echo  3. Use manage/test controls only when needed
echo.
echo  1^) Setup / Resume orchestration
echo  2^) Monitor orchestration state
echo  3^) Manage FREEZE / drain state
echo  4^) Prepare a test window
echo  5^) Monitor runtime errors
echo  6^) Add a feature from text
echo  7^) Exit
echo.
set /p "CHOICE=  Choice (1-7): "

if "!CHOICE!"=="1" (
    call "!TEMPLATE!\orchestrate.bat"
    goto :eof
)
if "!CHOICE!"=="2" (
    call "!TEMPLATE!\monitor-orchestration.bat"
    goto :eof
)
if "!CHOICE!"=="3" (
    call "!TEMPLATE!\manage-orchestration.bat"
    goto :eof
)
if "!CHOICE!"=="4" (
    call "!TEMPLATE!\test-orchestration.bat"
    goto :eof
)
if "!CHOICE!"=="5" (
    call "!TEMPLATE!\monitor.bat"
    goto :eof
)
if "!CHOICE!"=="6" (
    call "!TEMPLATE!\add-feature.bat"
    goto :eof
)

exit /b 0
