@echo off
chcp 65001 >nul
setlocal
"%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" "%~dp0configure_operator_password.py"
pause
