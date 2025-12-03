# =====================================================================
#  Spacefoot Auto Inventory - Launcher (UTF-8 safe auto-update)
# =====================================================================

chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$LAUNCHER_VERSION = "launcher v3.0.1"

function Get-BaseDirectory {
    if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
        return $PSScriptRoot
    }
    return (Get-Location).Path
}

# --- On force le working directory sur le dossier du launcher ---
$BaseDir = Get-BaseDirectory
Set-Location -Path $BaseDir

$Config    = Join-Path $BaseDir "config_inventory.json"
$CoreLocal = Join-Path $BaseDir "inventaire_windows_core.ps1"

$coreUrl   = "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1"

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Spacefoot Auto Inventory - Launcher"         -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Base dir : $BaseDir"                         -ForegroundColor Yellow
Write-Host "  Version  : $LAUNCHER_VERSION"                -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# --- Checks de base ---
if (!(Test-Path $Config)) {
    Write-Host "[ERREUR] Fichier config_inventory.json introuvable." -ForegroundColor Red
    Write-Host "Placez-le dans : $BaseDir" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}

# --- Téléchargement du core depuis GitHub ---
Write-Host "Telechargement de la derniere version du core..." -ForegroundColor White
Write-Host "URL : $coreUrl" -ForegroundColor DarkGray
Write-Host ""

$downloadOk = $false
$coreContent = $null

try {
    # Force TLS 1.2 au cas où la machine est un peu vieille
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.SecurityProtocolType]::Tls12 -bor `
        [Net.SecurityProtocolType]::Tls11 -bor `
        [Net.SecurityProtocolType]::Tls

    $response = Invoke-WebRequest -Uri $coreUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    $coreContent = $response.Content

    # On sauvegarde aussi en local
    $coreContent | Out-File -FilePath $CoreLocal -Encoding UTF8
    Write-Host "[OK] Core telecharge et enregistre localement." -ForegroundColor Green
    $downloadOk = $true
}
catch {
    Write-Host "[AVERTISSEMENT] Impossible de telecharger le core depuis GitHub." -ForegroundColor Yellow
    Write-Host "Message : $($_.Exception.Message)" -ForegroundColor DarkGray
}

# --- Si telechargement KO, on tente le core local ---
if (-not $downloadOk) {
    if (Test-Path $CoreLocal) {
        Write-Host "[INFO] Utilisation du core local existant." -ForegroundColor Yellow
        try {
            # Force la lecture UTF-8 meme si le fichier n'a pas de BOM
            $coreContent = Get-Content -Path $CoreLocal -Encoding UTF8 -Raw
        }
        catch {
            Write-Host "[ERREUR] Impossible de lire le core local en UTF-8." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor DarkGray
            Write-Host ""
            Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
            exit 1
        }
    }
    else {
        Write-Host "[ERREUR] Aucun core disponible (telechargement et local KO)." -ForegroundColor Red
        Write-Host ""
        Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
        exit 1
    }
}
elseif (-not $coreContent) {
    # Cas tres improbable : telechargement OK mais contenu vide
    Write-Host "[AVERTISSEMENT] Core vide recu depuis GitHub, tentative avec le fichier local." -ForegroundColor Yellow
    if (Test-Path $CoreLocal) {
        $coreContent = Get-Content -Path $CoreLocal -Encoding UTF8 -Raw
    }
    else {
        Write-Host "[ERREUR] Aucun core disponible." -ForegroundColor Red
        Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
        exit 1
    }
}

# --- Execution du core en UTF-8 ---
Write-Host ""
Write-Host "Lancement du core (UTF-8 force)..." -ForegroundColor White
Write-Host ""

try {
    $scriptBlock = [ScriptBlock]::Create($coreContent)
    & $scriptBlock
}
catch {
    Write-Host ""
    Write-Host "[ERREUR] Le core a rencontre un probleme lors de l'execution." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}

Write-Host ""
Write-Host "Fin du launcher." -ForegroundColor DarkGray
Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
exit 0
