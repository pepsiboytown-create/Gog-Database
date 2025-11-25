@echo off
REM GOG Database Auto-Update - Double-click this file to update
REM This batch file runs the PowerShell update script

echo.
echo Launching GOG Database Auto-Update...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-gogs.ps1"

pause
