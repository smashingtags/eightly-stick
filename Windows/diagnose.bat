@echo off
title Eight.ly Forge - Diagnose
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0diagnose.ps1"
echo.
pause
