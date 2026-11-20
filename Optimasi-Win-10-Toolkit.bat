@echo off
setlocal EnableExtensions
title Optimasi Windows 10 Toolkit

set "TOOLKIT_ROOT=%~dp0"
set "PS_SCRIPT=%TOOLKIT_ROOT%scripts\Optimasi-Windows-10-Toolkit.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Script PowerShell tidak ditemukan:
    echo "%PS_SCRIPT%"
    echo.
    pause
    exit /b 2
)

:: Request elevation automatically when not running as Administrator.
fltmc >nul 2>&1
if errorlevel 1 (
    echo Meminta hak Administrator melalui UAC...
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    if errorlevel 1 (
        echo [ERROR] Permintaan UAC gagal atau dibatalkan.
        pause
        exit /b 5
    )
    exit /b 0
)

echo ==================================================
echo       OPTIMASI WINDOWS 10 TOOLKIT
echo ==================================================
echo.

:: Launch the toolkit in Windows PowerShell 5.1.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "TOOLKIT_EXIT_CODE=%ERRORLEVEL%"

if not "%TOOLKIT_EXIT_CODE%"=="0" (
    echo.
    echo [ERROR] Toolkit selesai dengan exit code %TOOLKIT_EXIT_CODE%.
    pause
)

exit /b %TOOLKIT_EXIT_CODE%
