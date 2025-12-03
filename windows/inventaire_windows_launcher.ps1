# =====================================================================
#  INVENTAIRE WINDOWS - LAUNCHER (auto-update core depuis GitHub)
#  Ce script est fait pour être compilé en EXE et distribué aux collègues
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$LAUNCHER_VERSION = "launcher v1.0.0"

function Get-BaseDirectory {
    if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
        return $PSScriptRoot
    }
    try {
        $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $dir     = [System.IO.Path]::GetDirectoryName($exePath)
        if (Test-Path $dir) { return $dir }
    } catch { }
    return (Get-Location).Path
}

$BaseDir   = Get-BaseDirectory
$Config    = Join-Path $BaseDir "config_inventory.json"
$CoreLocal = Join-Path $BaseDir "inventaire_windows_core.ps1"

# URL RAW du core sur GitHub (à adapter si ton repo change)
$coreUrl = "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1"

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Spacefoot Auto Inventory - Launcher"         -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Base dir   : $BaseDir"
Write-Host "  Version    : $LAUNCHER_VERSION"
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# 1) Vérifier la présence de la config locale
if (!(Test-Path $Config)) {
    Write-Host "[ERREUR] Fichier config_inventory.json introuvable." -ForegroundColor Red
    Write-Host "Placez 'config_inventory.json' dans le même dossier que ce programme." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}

# 2) Récupérer la dernière version du core depuis GitHub
Write-Host "Téléchargement du core depuis GitHub..." -ForegroundColor White
Write-Host "URL : $coreUrl" -ForegroundColor DarkGray
Write-Host ""

$downloadOk = $false

try {
    Invoke-WebRequest -Uri $coreUrl -OutFile $CoreLocal -UseBasicParsing -ErrorAction Stop
    Write-Host "[OK] Core mis à jour : $CoreLocal" -ForegroundColor Green
    $downloadOk = $true
} catch {
    Write-Host "[AVERTISSEMENT] Impossible de télécharger la dernière version du core." -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Write-Host ""

    if (Test-Path $CoreLocal) {
        Write-Host "[INFO] Utilisation de la version locale du core déjà présente :" -ForegroundColor Yellow
        Write-Host "       $CoreLocal" -ForegroundColor Yellow
        $downloadOk = $true
    } else {
        Write-Host "[ERREUR] Aucun core disponible. Impossible de continuer." -ForegroundColor Red
        Write-Host ""
        Write-Host "Test réseau : ouvrez cette URL dans un navigateur :" -ForegroundColor White
        Write-Host "  $coreUrl" -ForegroundColor DarkGray
        Write-Host ""
        Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
        exit 1
    }
}

# 3) Lancer le core (qui utilise la config locale)
Write-Host ""
Write-Host "Lancement du core..." -ForegroundColor White
Write-Host ""

try {
    & "$CoreLocal"
} catch {
    Write-Host ""
    Write-Host "[ERREUR] Le core a rencontré un problème." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}

# Normalement, le core gère déjà sa propre pause et fermeture.
# Si jamais il revient ici, on termine proprement :
Write-Host ""
Write-Host "Fin du launcher." -ForegroundColor DarkGray
Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
exit 0
