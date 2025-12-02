# =====================================================================
#   INVENTAIRE WINDOWS - Launcher Git
#   Rôle  : récupérer la dernière version du script core sur GitHub
#           et l'exécuter.
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# URL du script "core" hébergé sur GitHub (RAW)
$scriptUrl  = "https://raw.githubusercontent.com/badr-spacefoot/auto_inventory/main/windows/inventaire_windows_core.ps1"

# Chemin vers un éventuel core local de secours (dans le même dossier que le launcher)
$localCore  = Join-Path $PSScriptRoot "inventaire_windows_core.ps1"

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

    if (Test-Path $localCore) {
        Write-Host ""
        Write-Host "Utilisation de la version locale de secours : $localCore" -ForegroundColor Yellow
        & $localCore
    } else {
        Write-Host ""
        Write-Host "Aucune version locale de secours n'a été trouvée." -ForegroundColor Red
        Write-Host "Veuillez contacter l'équipe IT." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
}
