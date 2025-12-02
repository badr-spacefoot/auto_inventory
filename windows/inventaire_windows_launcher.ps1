# =====================================================================
#   INVENTAIRE WINDOWS - Launcher Git (debug simple)
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Forcer TLS 1.2 (souvent nécessaire sur les vieux Windows)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# URL RAW EXACTE (A NE PAS MODIFIER)
$scriptUrl = "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1"

Write-Host "===================================================="
Write-Host "  Inventaire Windows - Launcher (Git DEBUG)" -ForegroundColor Cyan
Write-Host "===================================================="
Write-Host ""
Write-Host "URL utilisee :" -ForegroundColor Yellow
Write-Host "[$scriptUrl]" -ForegroundColor White
Write-Host ""

# Vérifier que l'URL est bien valide pour .NET
if (-not [Uri]::IsWellFormedUriString($scriptUrl, [UriKind]::Absolute)) {
    Write-Host "❌ ERREUR: L'URL N'EST PAS CONSIDEREE COMME VALIDE PAR .NET" -ForegroundColor Red
    Start-Sleep -Seconds 10
    exit 1
} else {
    Write-Host "✅ URL valide pour .NET, tentative de téléchargement..." -ForegroundColor Green
    Write-Host ""
}

try {
    $response = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop
    $scriptContent = $response.Content

    if ([string]::IsNullOrWhiteSpace($scriptContent)) {
        throw "Le script distant est vide ou n'a pas pu etre lu."
    }

    # Petit hash pour debug
    $sha256 = New-Object System.Security.Cryptography.SHA256Managed
    $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($scriptContent))
    $hashString = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "")

    Write-Host "✅ Script recupere depuis GitHub." -ForegroundColor Green
    Write-Host "Core SHA-256 : $hashString" -ForegroundColor Magenta
    Write-Host ""

    # Marqueur pour le core
    $env:SPACEFOOT_INVENTAIRE = "1"
    Invoke-Expression $scriptContent
    $env:SPACEFOOT_INVENTAIRE = $null
}
catch {
    Write-Host ""
    Write-Host "❌ ERROR: Unable to fetch core script from GitHub." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Test reseau : ouvrez cette URL dans un navigateur sur ce PC :" -ForegroundColor Yellow
    Write-Host "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1" -ForegroundColor White
    Start-Sleep -Seconds 15
}
