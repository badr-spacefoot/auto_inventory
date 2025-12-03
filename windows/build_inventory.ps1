# =============================================================
#   BUILD INVENTORY  - Compiler le LAUNCHER en EXE
# =============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$SourceFile = "inventaire_windows_launcher.ps1"
$OutputFile = "inventaire_windows.exe"
$IconFile   = Join-Path $PSScriptRoot "icon.ico"   # optionnel

Write-Host "`n==============================" -ForegroundColor Cyan
Write-Host "  AutoInventory - Build LAUNCHER EXE" -ForegroundColor Cyan
Write-Host "==============================`n" -ForegroundColor Cyan

if (-not (Test-Path $SourceFile)) {
    Write-Host "[ERREUR] Le fichier source n'existe pas : $SourceFile" -ForegroundColor Red
    exit 1
}

Write-Host "Vérification du module 'ps2exe'..." -ForegroundColor White
$ps2exeModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq "ps2exe" }

if (-not $ps2exeModule) {
    Write-Host "[INFO] ps2exe non trouvé. Installation..." -ForegroundColor Yellow
    try {
        Install-Module ps2exe -Scope CurrentUser -Force -ErrorAction Stop
    } catch {
        Write-Host "[ERREUR] Impossible d'installer 'ps2exe'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
        exit 1
    }
}

Import-Module ps2exe -ErrorAction SilentlyContinue

Write-Host "Compilation en cours..." -ForegroundColor Yellow

if (Test-Path $IconFile) {
    Invoke-ps2exe -inputFile $SourceFile -outputFile $OutputFile -noConsole:$false -iconFile $IconFile
} else {
    Invoke-ps2exe -inputFile $SourceFile -outputFile $OutputFile -noConsole:$false
}

if (Test-Path $OutputFile) {
    Write-Host "`n[OK] Compilation réussie !" -ForegroundColor Green
    Write-Host "EXE généré : $OutputFile"
} else {
    Write-Host "`n[ERREUR] La compilation a échoué." -ForegroundColor Red
}
