<#
    build_inventory.ps1
    Script de compilation automatique :
    - Vérifie / installe ps2exe
    - Compile inventaire_windows_core.ps1 en inventaire_windows.exe
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param(
    [string]$Input  = "inventaire_windows_core.ps1",
    [string]$Output = "inventaire_windows.exe",
    [string]$Icon   = ""   # ex: "inventory.ico" si tu as une icône
)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Spacefoot Auto Inventory - Build Script"    -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que le script source existe
if (!(Test-Path $Input)) {
    Write-Host "ERREUR : fichier source introuvable :" -ForegroundColor Red
    Write-Host "  $Input" -ForegroundColor Red
    Write-Host ""
    Write-Host "Place build_inventory.ps1 dans le même dossier que inventaire_windows_core.ps1" -ForegroundColor Yellow
    Read-Host "Appuyez sur ENTREE pour quitter / Press ENTER to exit"
    exit 1
}

# Vérifier / installer le module ps2exe
Write-Host "Vérification du module 'ps2exe'..." -ForegroundColor White

$ps2exeModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq "ps2exe" }

if (-not $ps2exeModule) {
    Write-Host "Module 'ps2exe' non trouvé. Installation en cours..." -ForegroundColor Yellow
    try {
        Install-Module ps2exe -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "Module 'ps2exe' installé avec succès." -ForegroundColor Green
    } catch {
        Write-Host "ERREUR : impossible d'installer 'ps2exe'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
        Read-Host "Appuyez sur ENTREE pour quitter / Press ENTER to exit"
        exit 1
    }
} else {
    Write-Host "Module 'ps2exe' trouvé." -ForegroundColor Green
}

Import-Module ps2exe -ErrorAction SilentlyContinue

# Construction des paramètres pour Invoke-ps2exe
Write-Host ""
Write-Host "Compilation en cours..." -ForegroundColor White
Write-Host "  Source : $Input" -ForegroundColor DarkGray
Write-Host "  Cible  : $Output" -ForegroundColor DarkGray
if ($Icon -and (Test-Path $Icon)) {
    Write-Host "  Icône  : $Icon" -ForegroundColor DarkGray
}

$invokeParams = @{
    InputFile  = $Input
    OutputFile = $Output
    Title      = "Spacefoot Auto Inventory"
    NoConsole  = $false      # On garde la console pour ton UI ASCII
}

if ($Icon -and (Test-Path $Icon)) {
    $invokeParams.IconFile = $Icon
}

try {
    Invoke-ps2exe @invokeParams
    Write-Host ""
    Write-Host "Compilation terminée avec succès ✅" -ForegroundColor Green
    Write-Host "Fichier généré : $Output" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "ERREUR pendant la compilation ❌" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Read-Host "Appuyez sur ENTREE pour quitter / Press ENTER to exit"
    exit 1
}

Write-Host ""
Write-Host "Rappel : placez 'config_inventory.json' dans le même dossier que :" -ForegroundColor White
Write-Host "  $Output" -ForegroundColor White
Write-Host ""
Read-Host "Build terminé. Appuyez sur ENTREE pour fermer / Press ENTER to close"
exit 0
