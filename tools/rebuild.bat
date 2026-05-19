@echo off
REM ARKSA Server Maintainer — full clean rebuild.
REM
REM Steps:
REM   1. cargo clean -p arksa-gui --target x86_64-pc-windows-msvc
REM      (removes built artifacts for the msvc release target).
REM   2. Refresh source file modification times so cargo definitely sees
REM      them as "newer than artifacts" on the next build.
REM   3. Invoke tools\build-release.ps1 — full LTO + strip msvc build,
REM      stages bundle, packs zip, copies standalone exe to dist\.
REM
REM Use this when build.bat finishes suspiciously fast or after pulling
REM changes that touched dependencies / generated Slint code.

setlocal
cd /d "%~dp0\.."

echo === cargo clean -p arksa-gui --target x86_64-pc-windows-msvc ===
cargo clean -p arksa-gui --target x86_64-pc-windows-msvc
if errorlevel 1 goto :fail

echo === Refreshing source file modification times ===
powershell -NoProfile -Command "Get-ChildItem -Recurse crates -Include *.rs,*.slint,Cargo.toml | ForEach-Object { $_.LastWriteTime = Get-Date }"
if errorlevel 1 goto :fail

echo === Building release bundle ===
powershell -NoProfile -File "%~dp0build-release.ps1"
if errorlevel 1 goto :fail

echo.
echo Rebuild OK.
goto :end

:fail
echo.
echo Rebuild FAILED (exit %ERRORLEVEL%).

:end
pause
exit /b %ERRORLEVEL%
