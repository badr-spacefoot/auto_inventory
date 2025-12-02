# =====================================================================
#   INVENTAIRE WINDOWS - Launcher Git (FORCE ONLINE + CONFIGDIR)
#   Version : simple (sans nocache)
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# URL RAW GitHub (ne pas modifier)
$scriptUrl = "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1"

Write-Host "===================================================="
Write-Host "  Inventaire Windows - Launcher (Git)" -ForegroundColor Cyan
Write-Host "===================================================="
Write-Host ""
Write-Host "Fetching latest core script from GitHub..." -ForegroundColor Yellow
Write-Host "URL: $scriptUrl" -ForegroundColor DarkGray
Write-Host ""

# Vérifier que l'URL est bien correcte pour .NET
if (-not [Uri]::IsWellFormedUriString($scriptUrl, [UriKind]::Absolute)) {
    Write-Host "❌ ERREUR: L'URL n'est pas valide pour .NET" -ForegroundColor Red
    Start-Sleep -Seconds 10
    exit 1
}

try {
    $response = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop
    $scriptContent = $response.Content

    if ([string]::IsNullOrWhiteSpace($scriptContent)) {
        throw "Le script distant est vide ou n'a pas pu etre lu."
    }

    # Hash pour debug
    $sha256 = New-Object System.Security.Cryptography.SHA256Managed
    $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($scriptContent))
    $hashString = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "")

    Write-Host "Successfully fetched latest core from GitHub." -ForegroundColor Green
    Write-Host "Core SHA-256 : $hashString" -ForegroundColor Magenta
    Write-Host ""

    # Marqueurs pour le core
    $env:SPACEFOOT_INVENTAIRE = "1"
    $env:SPACEFOOT_CONFIGDIR  = $PSScriptRoot   # dossier où se trouve le launcher + config_inventory.json

    Invoke-Expression $scriptContent

    # Nettoyage
    $env:SPACEFOOT_INVENTAIRE = $null
    $env:SPACEFOOT_CONFIGDIR  = $null
}
catch {
    Write-Host ""
    Write-Host "❌ ERROR: Problem while downloading or executing the core script." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "If the problem persists, open this URL in your browser on this PC :" -ForegroundColor Yellow
    Write-Host "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1" -ForegroundColor White
    Start-Sleep -Seconds 15
}
