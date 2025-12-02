@echo off
REM ============================================================
REM  Inventaire Windows - Launcher batch
REM  Lance le script PowerShell qui récupère le core depuis Git
REM ============================================================

REM Forcer l'encodage UTF-8 dans la console
chcp 65001 >nul

REM Lancer le launcher PowerShell situé dans le même dossier
powershell -ExecutionPolicy Bypass -File "%~dp0inventaire_windows_launcher.ps1"

REM (Optionnel) Si tu veux garder la fenêtre ouverte en cas d'erreur, décommente la ligne ci-dessous :
REM pause
