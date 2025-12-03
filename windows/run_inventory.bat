@echo off
:: ============================================================
::  Spacefoot Auto Inventory - Windows Launcher (BAT)
::  Lance le script PowerShell en UTF-8 sans clignoter
:: ============================================================

:: Se déplacer dans le dossier du .bat
cd /d "%~dp0"

:: Exécuter PowerShell en UTF-8 + bypass policy
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass ^
    -Command "chcp 65001 > $null; [Console]::OutputEncoding=[System.Text.Encoding]::UTF8; & '%~dp0inventaire_windows_launcher.ps1'"

pause
