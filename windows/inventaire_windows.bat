@echo off
chcp 65001 >nul
powershell -ExecutionPolicy Bypass -File "%~dp0inventaire_windows_core.ps1"
