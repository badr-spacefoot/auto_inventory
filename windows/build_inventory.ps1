# =============================================================
#   BUILD INVENTORY  - Compiler le script en EXE
# =============================================================

# Paramètres
$SourceFile = "inventaire_windows_core.ps1"
$OutputFile = "inventaire_windows.exe"

Write-Host "`n==============================" -ForegroundColor Cyan
Write-Host "  AutoInventory - Build EXE" -ForegroundColor Cyan
Write-Host "==============================`n" -ForegroundColor Cyan

# Vérification du fichier source
if (-not (Test-Path $SourceFile)) {
    Write-Host "[ERREUR] Le fichier source n'existe pas : $SourceFile" -ForegroundColor Red
    exit 1
}

# Chemin du compilateur PS2EXE
$PS2EXE = "$PSScriptRoot\ps2exe\ps2exe.ps1"

if (-not (Test-Path $PS2EXE)) {
    Write-Host "[INFO] ps2exe non trouvé. Installation..." -ForegroundColor Yellow
    Install-Module ps2exe -Force -Scope CurrentUser
}

# Compilation
Write-Host "Compilation en cours..." -ForegroundColor Yellow

Invoke-ps2exe $SourceFile $OutputFile -noConsole -icon "$PSScriptRoot\icon.ico"

if (Test-Path $OutputFile) {
    Write-Host "`n[OK] Compilation réussie !" -ForegroundColor Green
    Write-Host "EXE généré : $OutputFile"
} else {
    Write-Host "`n[ERREUR] La compilation a échoué." -ForegroundColor Red
}
