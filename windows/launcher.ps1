# =====================================================================
#  Spacefoot Auto Inventory - LAUNCHER (auto-update)
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$LAUNCHER_VERSION = "launcher v2.0.0"

function Get-BaseDirectory {
    if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
        return $PSScriptRoot
    }
    return (Get-Location).Path
}

$BaseDir   = Get-BaseDirectory
$Config    = Join-Path $BaseDir "config_inventory.json"
$CoreLocal = Join-Path $BaseDir "inventaire_windows_core.ps1"

# URL RAW du core sur GitHub
$coreUrl = "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1"

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Spacefoot Auto Inventory - Launcher"         -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Dossier : $BaseDir"
Write-Host "  Version : $LAUNCHER_VERSION"
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# 1) Check config
if (!(Test-Path $Config)) {
    Write-Host "[ERREUR] Fichier config_inventory.json introuvable." -ForegroundColor Red
    Write-Host "Placez-le dans : $BaseDir" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Appuyez sur ENTREE pour fermer"
    exit
}

# 2) Download core
Write-Host "Téléchargement de la dernière version du core..." -ForegroundColor White
Write-Host "URL : $coreUrl" -ForegroundColor DarkGray

try {
    Invoke-WebRequest -Uri $coreUrl -OutFile $CoreLocal -UseBasicParsing -ErrorAction Stop
    Write-Host "[OK] Core mis à jour." -ForegroundColor Green
} catch {
    Write-Host "[AVERTISSEMENT] Impossible de télécharger le core." -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor DarkGray

    if (!(Test-Path $CoreLocal)) {
        Write-Host "[ERREUR] Aucun core disponible localement." -ForegroundColor Red
        Write-Host ""
        Read-Host "Appuyez sur ENTREE pour fermer"
        exit
    }

    Write-Host "[INFO] Utilisation de la version locale." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Lancement du programme..." -ForegroundColor White
Write-Host ""

try {
    & "$CoreLocal"
} catch {
    Write-Host ""
    Write-Host "[ERREUR] Erreur lors de l'exécution du core." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Appuyez sur ENTREE pour fermer"
    exit
}

Write-Host ""
Write-Host "Fin du launcher." -ForegroundColor DarkGray
Read-Host "Appuyez sur ENTREE pour fermer"
