@echo off
title Portable AI USB - Local Model Setup
cls

echo.
echo Running Local Model Setup...
echo.

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0Setup_Local_Models.ps1"

echo.
pause
