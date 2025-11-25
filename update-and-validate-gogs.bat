@echo off
REM GOG Database Auto-Update & Validation Script
REM Simply double-click this file to update the website

cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "update-and-validate-gogs.ps1"
pause
