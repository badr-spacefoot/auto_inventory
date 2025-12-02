# =====================================================================
#   INVENTAIRE WINDOWS - Launcher Git (FORCE ONLINE)
#   Rôle : récupérer TOUJOURS la dernière version du script core
#          sur GitHub et l'exécuter. Aucun fallback local.
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Construction de l'URL RAW avec anti-cache (?nocache=<timestamp>)
$timestamp = [DateTime]::UtcNow.Ticks
$baseUrl   = "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1"
$scriptUrl = "$baseUrl?nocache=$timestamp"

Write-Host "===================================================="
Write-Host "  Inventaire Windows - Launcher (Git)" -ForegroundColor Cyan
Write-Host "===================================================="
Write-Host ""
Write-Host "Fetching latest core script from GitHub..." -ForegroundColor Yellow
Write-Host "URL: $baseUrl" -ForegroundColor DarkGray
Write-Host ""

try {
    # Récupérer le contenu du script core depuis GitHub (toujours en ligne)
    $response = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop
    $scriptContent = $response.Content

    if ([string]::IsNullOrWhiteSpace($scriptContent)) {
        throw "Le script distant est vide ou n'a pas pu etre lu."
    }

    # Calcul du hash SHA-256 pour vérification
    $sha256 = New-Object System.Security.Cryptography.SHA256Managed
    $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($scriptContent))
    $hashString = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "")

    Write-Host "Successfully fetched latest core from GitHub." -ForegroundColor Green
    Write-Host "Core SHA-256 : $hashString" -ForegroundColor Magenta
    Write-Host ""

    # Marqueur pour empêcher l'exécution directe du core
    $env:SPACEFOOT_INVENTAIRE = "1"

    # Exécution du script core en mémoire
    Invoke-Expression $scriptContent

    # Nettoyage du marqueur
    $env:SPACEFOOT_INVENTAIRE = $null
}
catch {
    Write-Host ""
    Write-Host "⚠ ERROR: Unable to fetch core script from GitHub." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Please try again later or contact the IT team." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}
