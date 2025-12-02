@echo off
REM ============================================================
REM  Inventaire Windows - Launcher batch (DEBUG FRIENDLY)
REM ============================================================

chcp 65001 >nul

REM On garde la fenetre ouverte avec -NoExit pour voir les erreurs
powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0inventaire_windows_launcher.ps1"

echo.
echo (Appuyez sur une touche pour fermer cette fenetre)
pause >nul
