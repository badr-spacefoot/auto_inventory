# =====================================================================
#   INVENTAIRE WINDOWS - Launcher Git (FORCE ONLINE)
#   Rôle  : récupérer TOUJOURS la dernière version du script core
#           sur GitHub et l'exécuter. Aucun fallback local.
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# URL du script "core" hébergé sur GitHub (RAW)
$timestamp = [DateTime]::UtcNow.Ticks
$scriptUrl  = "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1?nocache=$timestamp"


Write-Host "===================================================="
Write-Host "  Inventaire Windows - Launcher (Git)" -ForegroundColor Cyan
Write-Host "===================================================="
Write-Host ""
Write-Host "Récupération de la dernière version du script..." -ForegroundColor Yellow

try {
    # Récupérer le contenu du script core depuis GitHub
    $response = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop
    $scriptContent = $response.Content

    if ([string]::IsNullOrWhiteSpace($scriptContent)) {
        throw "Le script distant est vide ou n'a pas pu être lu."
    }

    Write-Host "Script récupéré depuis GitHub. Exécution..." -ForegroundColor Green

    # Exécuter le script directement en mémoire
    Invoke-Expression $scriptContent
}
catch {
    Write-Host ""
    Write-Host "⚠ Impossible de récupérer le script sur GitHub." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Veuillez réessayer plus tard ou contacter l'équipe IT." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}
