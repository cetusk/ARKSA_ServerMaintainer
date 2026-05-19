@echo off
REM ARKSA Server Maintainer -- incremental release build.
REM
REM Steps:
REM   1. Refresh source file modification times. Edits done through the
REM      WSL / Docker sandbox don't always propagate mtime to Windows,
REM      so cargo's incremental build can wrongly decide nothing changed
REM      (the smoking gun is "Finished `release` in <1s" after a change).
REM   2. Invoke tools\build-release.ps1 -- builds msvc + crt-static release,
REM      stages bundle, packs zip, copies standalone exe to dist\.
REM
REM For a full clean rebuild use rebuild.bat instead.

setlocal
cd /d "%~dp0\.."

echo === Refreshing source file modification times ===
powershell -NoProfile -Command "Get-ChildItem -Recurse crates -Include *.rs,*.slint,Cargo.toml | ForEach-Object { $_.LastWriteTime = Get-Date }"
if errorlevel 1 goto :fail

echo === Building release bundle ===
powershell -NoProfile -File "%~dp0build-release.ps1"
if errorlevel 1 goto :fail

echo.
echo Build OK.
goto :end

:fail
echo.
echo Build FAILED (exit %ERRORLEVEL%).

:end
pause
exit /b %ERRORLEVEL%
