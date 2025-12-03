@echo off
SET SPACEFOOT_INVENTAIRE=1
SET SPACEFOOT_CONFIGDIR=%~dp0

powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Normal -File "%~dp0inventaire_windows_core.ps1"

exit
