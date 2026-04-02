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

REM -- Feature request --
echo.
echo  Project: !PROJECT!
echo.

:input_loop
set "REQUEST="
set /p "REQUEST=  What feature to add? : "
if "!REQUEST!"=="" goto input_loop

echo.
"!GITBASH!" "!TEMPLATE!\add-feature.sh" "!PROJECT!" "!REQUEST!"

echo.
set /p "MORE=  Add another feature? (Y/n): "
if /i not "!MORE!"=="n" goto input_loop

pause
exit /b 0
