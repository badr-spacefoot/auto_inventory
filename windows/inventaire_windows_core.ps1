# =====================================================================
#   INVENTAIRE WINDOWS - CORE (UTF-8 BOM)
#   Version : v1.5.0
# =====================================================================

chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

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

$INV_BaseDir = Get-BaseDirectory
$INV_LogFile = Join-Path $INV_BaseDir "inventory_error.log"
$VERSION = "v1.5.0"

trap {
    $msg = "`n===== FATAL ERROR =====`n"
    $msg += (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + "`n"
    $msg += ($_ | Out-String) + "`n"
    Add-Content -Path $INV_LogFile -Value $msg

    Write-Host ""
    Write-Host "Une erreur fatale est survenue." -ForegroundColor Red
    Write-Host "Détails dans : $INV_LogFile" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Appuyez sur ENTRÉE pour fermer"
    exit 1
}

# ================================
#  ASCII Banner officiel Spacefoot
# ================================

$AsciiBanner = @(
"                                                                                     ",
"       :##:                                             ######   ###   ##  ##:  :## ",
"        ##                 ##                           ######   ###   ##  ##    ## ",
"       ####                ##                             ##     ###:  ##  :##  ##: ",
"       ####    ##    ##  #######    .####.                ##     ####  ##  :##  ##: ",
"      :#  #:   ##    ##  #######   .######.               ##     ##:#: ##   ## .##  ",
"       #::#    ##    ##    ##      ###  ###               ##     ## ## ##   ##::##  ",
"      ##  ##   ##    ##    ##      ##.  .##               ##     ## ## ##   ##::##  ",
"      ######   ##    ##    ##      ##    ##               ##     ## :#:##   :####:  ",
"     .######.  ##    ##    ##      ##.  .##               ##     ##  ####   .####.  ",
"     :##  ##:  ##:  ###    ##.     ###  ###     ##        ##     ##  :###    ####   ",
"     ###  ###   #######    #####   .######.     ##      ######   ##   ###    ####   ",
"     ##:  :##    ###.##    .####    .####.      ##      ######   ##   ###     ##    "
)

function Get-WindowWidth {
    try { return $Host.UI.RawUI.WindowSize.Width } catch { return 80 }
}

function Center-Write {
    param([string]$Text,[ConsoleColor]$Foreground = 'White')
    $w = Get-WindowWidth
    $pad = [math]::Floor(($w - $Text.Length) / 2)
    if ($pad -lt 0) { $pad = 0 }
    Write-Host (" " * $pad + $Text) -ForegroundColor $Foreground
}

function Show-AppHeader {
    param([string]$StepTitle,[string]$Subtitle)

    Clear-Host
    foreach ($line in $AsciiBanner) { Center-Write $line Cyan }

    $versionText = "Version $VERSION"
    $w = Get-WindowWidth
    $right = $w - $versionText.Length - 2
    Write-Host ""
    Write-Host (" " * $right + $versionText) -ForegroundColor DarkGray

    Write-Host ""
    Center-Write "Inventaire aujourd'hui, sécurité demain." Green
    Center-Write "Inventory today, security tomorrow." Green
    Write-Host ""

    if ($StepTitle) { Center-Write $StepTitle White }
    if ($Subtitle)  { Center-Write $Subtitle Gray }
    Write-Host ""
}

# ================================
#  Chargement de la configuration
# ================================

$configPath = Join-Path $INV_BaseDir "config_inventory.json"

if (!(Test-Path $configPath)) {
    Show-AppHeader "ERREUR CONFIG" ""
    Center-Write "Fichier config_inventory.json introuvable."
    Read-Host
    exit
}

$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

$webhookUrl = $config.webhook
$teams      = @($config.teams)
$sites      = @($config.sites)

# ===============================
#  Introduction
# ===============================

Show-AppHeader "ÉTAPE 1/4 - INTRODUCTION / INTRO" "Inventaire des postes Spacefoot"

$intro = @(
"[FR] Ce programme collecte automatiquement les informations TECHNIQUES",
"     de votre ordinateur (modèle, numéro de série, OS, CPU, RAM,",
"     IP interne, MAC...). Aucune donnée personnelle n'est collectée.",
"",
"[EN] This program automatically collects TECHNICAL information",
"     about your computer (model, serial number, OS, CPU, RAM,",
"     internal IP, MAC...). No personal data is collected.",
""
)
foreach ($l in $intro) { Center-Write $l }

Center-Write "Appuyez sur ENTRÉE pour continuer / Press ENTER to continue" Gray
[Console]::ReadKey($true) | Out-Null

# ===============================
#  Identité utilisateur
# ===============================

Show-AppHeader "ÉTAPE 1/4 - IDENTITÉ UTILISATEUR" "Renseignez vos informations"

$firstName = Read-Host "Votre prénom / Your first name"
$lastName  = Read-Host "Votre nom / Your last name"

$ti = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo
$firstName = $ti.ToTitleCase($firstName.ToLower())
$lastName  = $lastName.ToUpper()

# ===============================
#  Sélection Team
# ===============================

function Select-FromMenu {
    param([string]$title,[string[]]$options)

    $idx = 0
    while ($true) {
        Show-AppHeader $title ""
        for ($i=0; $i -lt $options.Count; $i++) {
            if ($i -eq $idx) {
                Write-Host "> $($options[$i])" -ForegroundColor Black -BackgroundColor DarkRed
            } else {
                Write-Host "  $($options[$i])"
            }
        }
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            "UpArrow"   { if ($idx -gt 0) { $idx-- } else { $idx = $options.Count -1 } }
            "DownArrow" { if ($idx -lt $options.Count -1) { $idx++ } else { $idx = 0 } }
            "Enter"     { return $idx }
        }
    }
}

$teamIdx = Select-FromMenu "ÉTAPE 2/4 - TEAM / SERVICE" $teams
$teamLabel = $teams[$teamIdx]

# ===============================
#  Sélection Site
# ===============================

$siteIdx = Select-FromMenu "ÉTAPE 3/4 - LIEU / SITE" $sites
$siteLabel = $sites[$siteIdx]

# ===============================
#  Collecte technique
# ===============================

Show-AppHeader "ÉTAPE 3/4 - COLLECTE TECHNIQUE" "Veuillez patienter..."

$Sys  = Get-WmiObject Win32_ComputerSystem
$BIOS = Get-WmiObject Win32_BIOS
$OS   = Get-WmiObject Win32_OperatingSystem
$CPU  = Get-WmiObject Win32_Processor

$ramGB = [math]::Round($Sys.TotalPhysicalMemory /1GB)

$IP = (Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -ne "127.0.0.1" } |
       Select-Object -First 1 -ExpandProperty IPAddress)

$MAC = (Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" } |
        Select-Object -First 1 -ExpandProperty MacAddress)

$PCName = $env:COMPUTERNAME
$User   = $env:USERNAME

$data = @{
    firstName    = $firstName
    lastName     = $lastName
    team         = $teamLabel
    site         = $siteLabel
    osType       = "Windows"
    pcName       = $PCName
    user         = $User
    manufacturer = $Sys.Manufacturer
    model        = $Sys.Model
    serial       = $BIOS.SerialNumber
    os           = $OS.Caption + " " + $OS.Version
    cpu          = $CPU.Name
    ram          = "$ramGB GB"
    ip           = $IP
    mac          = $MAC
}

$body = $data | ConvertTo-Json -Depth 5

# ===============================
#  Récapitulatif
# ===============================

Show-AppHeader "ÉTAPE 4/4 - RÉCAPITULATIF / SUMMARY" "Vérifiez les informations"

foreach ($kv in $data.GetEnumerator()) {
    Write-Host ("{0,-12} : {1}" -f $kv.Key, $kv.Value)
}

Write-Host ""
Center-Write "Appuyez sur ENTRÉE pour confirmer l’envoi" Gray
[Console]::ReadKey($true) | Out-Null

# ===============================
#  Envoi Google Apps Script
# ===============================

Show-AppHeader "ENVOI DES DONNÉES / SENDING DATA" "Veuillez patienter..."

try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json; charset=utf-8" -Body $body
    Center-Write "Inventaire envoyé avec succès !" Green
} catch {
    Center-Write "ERREUR : impossible d’envoyer les données." Red
    Center-Write $_.Exception.Message DarkGray
}

Write-Host ""
Center-Write "Cette fenêtre se fermera dans 10 secondes..." Gray
Start-Sleep 10
exit
