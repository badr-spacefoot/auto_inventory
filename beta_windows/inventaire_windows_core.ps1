# =====================================================================
#   INVENTAIRE WINDOWS - Script principal (core)
#   Version : v1.5.1.beta - 2025-12-03
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------------
#  Base directory + logging
# ---------------------------------------------------------------------
function Get-BaseDirectory {
    if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
        return $PSScriptRoot
    }
    return (Get-Location).Path
}

$Global:INV_BaseDir     = Get-BaseDirectory
$Global:INV_LogFile     = Join-Path $INV_BaseDir "inventory_error.log"
$Global:INV_ConfigPath  = Join-Path $INV_BaseDir "config_inventory.json"
$Global:INV_Version     = "1.5.1.beta"

Add-Content -Path $INV_LogFile -Value ("`n===== NEW RUN {0} =====`n" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))

trap {
    $msg  = "`n===== FATAL ERROR =====`n"
    $msg += (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + "`n"
    $msg += ($_ | Out-String) + "`n"
    Add-Content -Path $INV_LogFile -Value $msg

    Write-Host ""
    Write-Host "Une erreur fatale est survenue. / A fatal error occurred." -ForegroundColor Red
    Write-Host "Details enregistres dans : $INV_LogFile" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}

# ---------------------------------------------------------------------
#  ASCII banner & UI helpers
# ---------------------------------------------------------------------
$Global:INV_AsciiBanner = @(
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
    try   { return $Host.UI.RawUI.WindowSize.Width }
    catch { return 80 }
}

function Center-Write {
    param(
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    if (-not $Text) { $Text = "" }
    $w = Get-WindowWidth
    if ($Text.Length -ge $w) {
        Write-Host $Text -ForegroundColor $Color
    } else {
        $pad = [math]::Floor(($w - $Text.Length) / 2)
        if ($pad -lt 0) { $pad = 0 }
        Write-Host ((" " * $pad) + $Text) -ForegroundColor $Color
    }
}

function Show-AppHeader {
    param(
        [string]$StepTitle,
        [string]$StepSubtitle
    )

    Clear-Host

    foreach ($line in $INV_AsciiBanner) {
        Center-Write $line ([ConsoleColor]::Red)
    }

    $w = Get-WindowWidth
    $versionText = "Version $($Global:INV_Version)"
    $padRight = [Math]::Max(0, $w - $versionText.Length)
    Write-Host ""
    Write-Host ((" " * $padRight) + $versionText) -ForegroundColor DarkGray

    Write-Host ""
    Center-Write "Inventaire aujourd'hui, securite demain." ([ConsoleColor]::Green)
    Center-Write "Inventory today, security tomorrow."      ([ConsoleColor]::Green)
    Write-Host ""

    if ($StepTitle)    { Center-Write $StepTitle    ([ConsoleColor]::White) }
    if ($StepSubtitle) { Center-Write $StepSubtitle ([ConsoleColor]::Gray) }
    Write-Host ""
}

function Show-BoxCentered {
    param(
        [string]$Title,
        [string[]]$Lines
    )

    $width = Get-WindowWidth
    if ($width -lt 40) { $width = 80 }

    $innerWidth = [Math]::Min(76, $width - 4)
    if ($innerWidth -lt 30) { $innerWidth = 30 }

    $top    = "╔" + ("═" * $innerWidth) + "╗"
    $bottom = "╚" + ("═" * $innerWidth) + "╝"

    $padLeft = [Math]::Floor(($width - $top.Length) / 2)
    if ($padLeft -lt 0) { $padLeft = 0 }
    $spacesLeft = " " * $padLeft

    Write-Host ($spacesLeft + $top) -ForegroundColor DarkRed

    if ($Title) {
        $t = $Title
        if ($t.Length -gt $innerWidth) { $t = $t.Substring(0, $innerWidth) }
        $pad = [Math]::Floor(($innerWidth - $t.Length) / 2)
        if ($pad -lt 0) { $pad = 0 }
        $line = "║" + (" " * $pad) + $t + (" " * ($innerWidth - $t.Length - $pad)) + "║"
        Write-Host ($spacesLeft + $line) -ForegroundColor White
        Write-Host ($spacesLeft + "║" + (" " * $innerWidth) + "║") -ForegroundColor DarkRed
    }

    foreach ($l in $Lines) {
        $text = $l
        if (-not $text) { $text = "" }
        if ($text.Length -gt $innerWidth) { $text = $text.Substring(0, $innerWidth) }
        $pad = [Math]::Floor(($innerWidth - $text.Length) / 2)
        if ($pad -lt 0) { $pad = 0 }
        $line = "║" + (" " * $pad) + $text + (" " * ($innerWidth - $text.Length - $pad)) + "║"
        Write-Host ($spacesLeft + $line) -ForegroundColor Gray
    }

    Write-Host ($spacesLeft + $bottom) -ForegroundColor DarkRed
    Write-Host ""
}

function Wait-EnterCentered {
    param(
        [string]$Message = "Appuyez sur ENTREE pour continuer / Press ENTER to continue"
    )
    Center-Write $Message ([ConsoleColor]::Gray)
    [Console]::ReadKey($true) | Out-Null
}

function Select-FromMenu {
    param(
        [string]$StepTitle,
        [string]$StepSubtitle,
        [string[]]$Options
    )

    $index = 0
    while ($true) {
        Show-AppHeader $StepTitle $StepSubtitle
        Write-Host ""

        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $index) {
                Write-Host ("> " + $Options[$i]) -ForegroundColor Black -BackgroundColor DarkRed
            } else {
                Write-Host ("  " + $Options[$i])
            }
        }

        Write-Host ""
        Center-Write "Utilisez HAUT/BAS puis ENTREE pour valider / Use UP/DOWN + ENTER to confirm" ([ConsoleColor]::Gray)

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow"   { if ($index -gt 0) { $index-- } else { $index = $Options.Count - 1 } }
            "DownArrow" { if ($index -lt $Options.Count - 1) { $index++ } else { $index = 0 } }
            "Enter"     { return $index }
        }
    }
}

# ---------------------------------------------------------------------
#  ÉTAPE 1/4 – INTRO
# ---------------------------------------------------------------------
Show-AppHeader "ETAPE 1/4 - INTRODUCTION / INTRO" "Inventaire des postes Spacefoot / Spacefoot device inventory"

$introLines = @(
    "[FR] Ce programme collecte automatiquement les informations TECHNIQUES",
    "     de votre ordinateur (modele, numero de serie, OS, CPU, RAM,",
    "     IP interne, MAC...). Aucune donnee personnelle n'est collectee.",
    "",
    "[EN] This program automatically collects TECHNICAL information",
    "     about your computer (model, serial number, OS, CPU, RAM,",
    "     internal IP, MAC...). No personal data is collected."
)

Show-BoxCentered -Title "" -Lines $introLines
Wait-EnterCentered

# ---------------------------------------------------------------------
#  ÉTAPE 2/4 – IDENTITÉ UTILISATEUR
# ---------------------------------------------------------------------
Show-AppHeader "ETAPE 2/4 - IDENTITE UTILISATEUR / USER IDENTITY" "Renseignez vos informations / Please enter your information"

Write-Host ""
$firstName = Read-Host "Votre prenom / Your first name"
$lastName  = Read-Host "Votre nom / Your last name"
Write-Host ""

if ($firstName) {
    $ti = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo
    $firstName = $ti.ToTitleCase($firstName.ToLower())
}
if ($lastName) {
    $lastName = $lastName.ToUpper()
}

# ---------------------------------------------------------------------
#  Chargement CONFIG (teams, sites, webhook)
# ---------------------------------------------------------------------
if (!(Test-Path $INV_ConfigPath)) {
    Show-AppHeader "ERREUR CONFIG / CONFIG ERROR" ""
    Show-BoxCentered -Title "CONFIG INTROUVABLE / CONFIG NOT FOUND" -Lines @(
        "Fichier 'config_inventory.json' introuvable.",
        "File 'config_inventory.json' not found.",
        "",
        "Placez ce fichier dans le meme dossier que l'application.",
        "Place this file in the same folder as the application."
    )
    Wait-EnterCentered "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}

try {
    $configJson = Get-Content -Path $INV_ConfigPath -Raw -Encoding UTF8
    $config     = $configJson | ConvertFrom-Json
}
catch {
    Show-AppHeader "ERREUR CONFIG / CONFIG ERROR" ""
    Show-BoxCentered -Title "CONFIG INVALIDE / INVALID CONFIG" -Lines @(
        "Impossible de lire ou parser config_inventory.json.",
        "Cannot read or parse config_inventory.json.",
        "",
        "Details dans le log : inventory_error.log"
    )
    Wait-EnterCentered "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}

$teams      = @($config.teams)
$sites      = @($config.sites)
$webhookUrl = $config.webhook

if (-not $webhookUrl) {
    Show-AppHeader "ERREUR CONFIG / CONFIG ERROR" ""
    Show-BoxCentered -Title "WEBHOOK MANQUANT / MISSING WEBHOOK" -Lines @(
        "Le champ 'webhook' est manquant dans config_inventory.json.",
        "Field 'webhook' is missing in config_inventory.json."
    )
    Wait-EnterCentered "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}
if (-not $teams -or $teams.Count -eq 0) {
    Show-AppHeader "ERREUR CONFIG / CONFIG ERROR" ""
    Show-BoxCentered -Title "AUCUNE TEAM / NO TEAM" -Lines @(
        "Aucune team definie dans config_inventory.json.",
        "No team defined in config_inventory.json."
    )
    Wait-EnterCentered "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}
if (-not $sites -or $sites.Count -eq 0) {
    Show-AppHeader "ERREUR CONFIG / CONFIG ERROR" ""
    Show-BoxCentered -Title "AUCUN SITE / NO SITE" -Lines @(
        "Aucun site defini dans config_inventory.json.",
        "No site defined in config_inventory.json."
    )
    Wait-EnterCentered "Appuyez sur ENTREE pour fermer / Press ENTER to close"
    exit 1
}

# ---------------------------------------------------------------------
#  ÉTAPE 3/4 – CHOIX TEAM
# ---------------------------------------------------------------------
$teamOptions = @()
for ($i = 0; $i -lt $teams.Count; $i++) {
    $teamOptions += ("[{0}] {1}" -f ($i + 1), $teams[$i])
}
$teamIndex = Select-FromMenu "ETAPE 3/4 - TEAM / SERVICE" "Selectionnez votre equipe / Select your team" $teamOptions
$teamLabel = $teams[$teamIndex]

# ---------------------------------------------------------------------
#  ÉTAPE 3b/4 – CHOIX SITE
# ---------------------------------------------------------------------
$siteOptions = @()
for ($i = 0; $i -lt $sites.Count; $i++) {
    $siteOptions += ("[{0}] {1}" -f ($i + 1), $sites[$i])
}
$siteIndex = Select-FromMenu "ETAPE 3b/4 - LIEU / SITE" "Selectionnez votre etablissement / Select your site" $siteOptions
$siteLabel = $sites[$siteIndex]

# ---------------------------------------------------------------------
#  ÉTAPE 4/4 – COLLECTE TECHNIQUE
# ---------------------------------------------------------------------
Show-AppHeader "ETAPE 4/4 - COLLECTE TECHNIQUE / TECHNICAL SCAN" "Collecte automatique des informations / Automatic system scan"
Center-Write "Veuillez patienter... / Please wait..." ([ConsoleColor]::Gray)
Write-Host ""

$PCName = $env:COMPUTERNAME
$User   = $env:USERNAME

$Sys  = Get-WmiObject Win32_ComputerSystem
$BIOS = Get-WmiObject Win32_BIOS
$OS   = Get-WmiObject Win32_OperatingSystem
$CPU  = Get-WmiObject Win32_Processor

$ramGB = [math]::Round($Sys.TotalPhysicalMemory / 1GB)

$IP = (Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -ne "127.0.0.1" } |
       Select-Object -First 1 -ExpandProperty IPAddress)

$MAC = (Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" } |
        Select-Object -First 1 -ExpandProperty MacAddress)

$data = [ordered]@{
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

$bodyJson = $data | ConvertTo-Json -Depth 5

# ---------------------------------------------------------------------
#  RECAP + CONFIRMATION
# ---------------------------------------------------------------------
Show-AppHeader "RECAPITULATIF / SUMMARY" "Verifiez les informations / Check the information"
foreach ($kv in $data.GetEnumerator()) {
    Write-Host ("{0,-14} : {1}" -f $kv.Key, $kv.Value)
}
Write-Host ""
Wait-EnterCentered "Si tout est correct, appuyez sur ENTREE pour envoyer / If everything is correct, press ENTER to send"

Show-AppHeader "CONFIRMATION" "Envoi des donnees / Sending data"
Center-Write "Confirmez-vous l'envoi de cet inventaire ? / Do you confirm sending this inventory?" ([ConsoleColor]::White)
Write-Host ""
Center-Write "[ENTREE] Oui / Yes    |    [ECHAP] Non / No" ([ConsoleColor]::Gray)

$confirm = $false
while ($true) {
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq "Enter")  { $confirm = $true;  break }
    if ($key.Key -eq "Escape") { $confirm = $false; break }
}

# ---------------------------------------------------------------------
#  ENVOI
# ---------------------------------------------------------------------
if ($confirm) {
    Show-AppHeader "ENVOI DES DONNEES / SENDING DATA" "Transmission vers Google Sheet / Sending to Google Sheet"

    try {
        $resp = Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json; charset=utf-8" -Body $bodyJson
        Center-Write "Inventaire envoye avec succes. Merci ! / Inventory sent successfully. Thank you!" ([ConsoleColor]::Green)
        if ($resp) {
            Center-Write ("Reponse: {0}" -f $resp) ([ConsoleColor]::DarkGray)
        }
    }
    catch {
        Center-Write "ERREUR : envoi impossible. / ERROR: unable to send." ([ConsoleColor]::Red)
        Center-Write $_.Exception.Message ([ConsoleColor]::DarkGray)
    }
} else {
    Center-Write "Envoi annule par l'utilisateur. / Submission cancelled by user." ([ConsoleColor]::Red)
}

Write-Host ""
Center-Write "Cette fenetre se fermera dans 10 secondes... / This window will close in 10 seconds..." ([ConsoleColor]::White)
Start-Sleep -Seconds 10
exit
