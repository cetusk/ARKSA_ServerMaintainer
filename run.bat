@echo off
:: Double-clickable launcher for ARKSA_ServerMaintainer.
::
:: Forwards to run.ps1, which holds the per-user `ARKSA_DIR` setting.
:: Bypasses the PowerShell execution policy so a fresh Windows install
:: doesn't need `Set-ExecutionPolicy` to run a local script.
::
:: First-time setup: copy run.example.ps1 to run.ps1 and edit ARKSA_DIR.

setlocal
set "SCRIPT_DIR=%~dp0"

if not exist "%SCRIPT_DIR%run.ps1" (
    echo [run.bat] run.ps1 not found.
    echo Copy run.example.ps1 to run.ps1 and edit the ARKSA_DIR line, then re-run.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%run.ps1" %*
endlocal
