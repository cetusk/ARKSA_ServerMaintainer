@echo off
REM ARKSA Server Maintainer launcher (distribution build).
REM
REM By default the tool stores its data (profiles, bundled steamcmd,
REM logs) in the same folder as this script. To put it somewhere else
REM uncomment the SET line below and adjust the path.
REM
REM   set "ARKSA_DIR=D:\ARK\ARKSA_Tools"

if "%ARKSA_DIR%"=="" set "ARKSA_DIR=%~dp0"
start "" "%~dp0arksa-gui.exe"
