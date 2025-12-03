@echo off
chcp 65001 >nul

echo.
echo ==============================================
echo   Spacefoot Auto Inventory - Windows Launcher
echo ==============================================
echo.

REM Détection du répertoire du script
set "SCRIPT_DIR=%~dp0"

REM Lancer le launcher PowerShell en UTF-8
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%inventaire_windows_launcher.ps1"

echo.
echo ------------------------------------------------
echo   Programme terminé. Appuyez sur une touche...
echo ------------------------------------------------
pause >nul
