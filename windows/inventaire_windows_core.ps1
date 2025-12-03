# =====================================================================
#   INVENTAIRE WINDOWS - Script principal (core)
#   Version : v1.4.1 - 2025-12-03
#   Auteur  : Spacefoot / Badr
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------------
#  Sécurité : le core doit être lancé via le launcher
# ---------------------------------------------------------------------
if ($env:SPACEFOOT_INVENTAIRE -ne "1") {
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  EXECUTION NON AUTORISEE" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "Ce script doit etre lance via le launcher officiel." -ForegroundColor White
    Write-Host "Veuillez utiliser le fichier .bat fourni par l'equipe IT." -ForegroundColor White
    Start-Sleep -Seconds 8
    exit 1
}

# ---------------------------------------------------------------------
#  UI : couleurs + tentative plein écran
# ---------------------------------------------------------------------
$rawUI = $Host.UI.RawUI
$rawUI.BackgroundColor = 'Black'
$rawUI.ForegroundColor = 'White'
Clear-Host

try {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
'@ -ErrorAction SilentlyContinue

    $handle = (Get-Process -Id $pid).MainWindowHandle
    if ($handle -ne [IntPtr]::Zero) {
        # 3 = SW_MAXIMIZE
        [Win32]::ShowWindow($handle, 3) | Out-Null
    }
} catch {
    # Si ça échoue, ce n'est pas bloquant
}

Start-Sleep -Milliseconds 200
Clear-Host

# ---------------------------------------------------------------------
#  Version + ASCII banner
# ---------------------------------------------------------------------
$VERSION = "v1.4.1"

$AsciiBanner = @(
"                                                                                     ",
"                                                                                     ",
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
"     ##:  :##    ###.##    .####    .####.      ##      ######   ##   ###     ##    ",
"                                                                                     ",
"                                                                                     ",
"                                                                                     ",
"                                                                                     "
)

# ---------------------------------------------------------------------
#  Fonctions utilitaires UI
# ---------------------------------------------------------------------
function Get-WindowWidth {
    return $Host.UI.RawUI.WindowSize.Width
}

function Center-Write {
    param(
        [string]$Text,
        [ConsoleColor]$Foreground = [ConsoleColor]::White,
        [ConsoleColor]$Background = [ConsoleColor]::Black
    )
    $width = Get-WindowWidth
    if ($Text.Length -ge $width) {
        Write-Host $Text -ForegroundColor $Foreground -BackgroundColor $Background
    } else {
        $pad = [math]::Floor(($width - $Text.Length) / 2)
        Write-Host ((" " * $pad) + $Text) -ForegroundColor $Foreground -BackgroundColor $Background
    }
}

function Show-AppHeader {
    param(
        [string]$StepTitle,
        [string]$Subtitle
    )

    Clear-Host

    $width = Get-WindowWidth

    # 1) ASCII banner (centered)
    foreach ($line in $AsciiBanner) {
        Center-Write $line ([ConsoleColor]::Cyan)
    }

    # 2) Version bottom-right
    $versionText = "Version $VERSION"
    $padRight = [Math]::Max(0, $width - $versionText.Length)
    Write-Host ""
    Write-Host ((" " * $padRight) + $versionText) -ForegroundColor DarkGray
    Write-Host ""

    # 3) Step Title + Subtitle (centered)
    if ($StepTitle) {
        Center-Write $StepTitle ([ConsoleColor]::White)
    }
    if ($Subtitle) {
        Center-Write $Subtitle ([ConsoleColor]::Gray)
    }
    if ($StepTitle -or $Subtitle) {
        Write-Host ""
    }

    # 4) Tagline metasploit style (centered)
    $tagline = "To boldly map where no SKU has gone before."
    Center-Write $tagline ([ConsoleColor]::Green)
    Write-Host ""
}

function Show-BoxCentered {
    param(
        [string]$Title,
        [string[]]$Lines
    )

    $width = Get-WindowWidth
    $maxLen = $Title.Length
    foreach ($l in $Lines) {
        if ($l.Length -gt $maxLen) { $maxLen = $l.Length }
    }
    $innerWidth = [Math]::Min($maxLen + 4, $width - 10)
    $boxWidth   = $innerWidth + 2
    $leftMargin = [Math]::Floor(($width - $boxWidth) / 2)

    $top    = "╔" + ("═" * $innerWidth) + "╗"
    $bottom = "╚" + ("═" * $innerWidth) + "╝"

    Write-Host (" " * $leftMargin + $top) -ForegroundColor DarkRed

    # titre
    $titlePadded = " " + $Title
    if ($titlePadded.Length -gt $innerWidth) { $titlePadded = $titlePadded.Substring(0, $innerWidth) }
    $titlePadded = $titlePadded.PadRight($innerWidth)
    Write-Host (" " * $leftMargin + "║" + $titlePadded + "║") -ForegroundColor White

    # ligne vide
    Write-Host (" " * $leftMargin + "║" + (" " * $innerWidth) + "║")

    foreach ($line in $Lines) {
        $text = " " + $line
        if ($text.Length -gt $innerWidth) { $text = $text.Substring(0, $innerWidth) }
        $text = $text.PadRight($innerWidth)
        Write-Host (" " * $leftMargin + "║" + $text + "║") -ForegroundColor White
    }

    Write-Host (" " * $leftMargin + $bottom) -ForegroundColor DarkRed
}

function Show-MenuCentered {
    param(
        [string]$StepTitle,
        [string]$Subtitle,
        [string[]]$Options
    )

    $index = 0

    while ($true) {
        Show-AppHeader $StepTitle $Subtitle

        $screenWidth  = $Host.UI.RawUI.WindowSize.Width

        # Longueur max des options
        $maxLen = 0
        foreach ($o in $Options) {
            if ($o.Length -gt $maxLen) { $maxLen = $o.Length }
        }

        $innerWidth = [Math]::Min($maxLen + 6, $screenWidth - 10)   # inside box
        $boxWidth   = $innerWidth + 2                               # borders
        $leftMargin = [Math]::Floor(($screenWidth - $boxWidth) / 2)

        function _pad-inner([string]$text, [int]$w) {
            if ($null -eq $text) { $text = "" }
            if ($text.Length -gt $w) { $text = $text.Substring(0, $w) }
            $padLeft  = [Math]::Floor(($w - $text.Length) / 2)
            $padRight = $w - $padLeft - $text.Length
            return (" " * $padLeft) + $text + (" " * $padRight)
        }

        Write-Host ""
        Write-Host ""

        $topLine    = "╔" + ("═" * $innerWidth) + "╗"
        $bottomLine = "╚" + ("═" * $innerWidth) + "╝"

        Write-Host (" " * $leftMargin + $topLine) -ForegroundColor DarkRed
        # ligne vide avant options
        Write-Host (" " * $leftMargin + "║" + (" " * $innerWidth) + "║")

        for ($i = 0; $i -lt $Options.Length; $i++) {
            $opt = _pad-inner $Options[$i] $innerWidth

            if ($i -eq $index) {
                Write-Host (" " * $leftMargin + "║") -NoNewline
                Write-Host $opt -ForegroundColor Black -BackgroundColor DarkRed -NoNewline
                Write-Host "║"
            } else {
                Write-Host (" " * $leftMargin + "║" + $opt + "║")
            }
        }

        # ligne vide après options
        Write-Host (" " * $leftMargin + "║" + (" " * $innerWidth) + "║")
        Write-Host (" " * $leftMargin + $bottomLine) -ForegroundColor DarkRed

        Write-Host ""
        $hint = "Utilisez les fleches HAUT/BAS puis ENTREE pour valider"
        $hintPad = [Math]::Floor(($screenWidth - $hint.Length) / 2)
        Write-Host ((" " * $hintPad) + $hint)

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow"   { if ($index -gt 0) { $index-- } else { $index = $Options.Length - 1 } }
            "DownArrow" { if ($index -lt $Options.Length - 1) { $index++ } else { $index = 0 } }
            "Enter"     { return ,@($index, $Options[$index]) }
        }
    }
}

# =====================================================================
#   CHARGEMENT CONFIG (webhook + listes teams/sites)
# =====================================================================

$baseDir = $env:SPACEFOOT_CONFIGDIR
if ([string]::IsNullOrWhiteSpace($baseDir)) {
    $baseDir = (Get-Location).Path
}

$configPath = Join-Path $baseDir "config_inventory.json"

if (!(Test-Path $configPath)) {
    Show-AppHeader "ERREUR CONFIG" ""
    Show-BoxCentered -Title "ERREUR CONFIG" -Lines @(
        "Fichier 'config_inventory.json' introuvable.",
        "Ajoutez-le dans le meme dossier que le launcher."
    )
    Start-Sleep -Seconds 10
    exit 1
}

try {
    $configJson = Get-Content -Path $configPath -Raw -Encoding utf8
    $config = $configJson | ConvertFrom-Json
} catch {
    Show-AppHeader "ERREUR LECTURE CONFIG" ""
    Show-BoxCentered -Title "ERREUR LECTURE CONFIG" -Lines @(
        "Impossible de lire ou parser 'config_inventory.json'.",
        $_.Exception.Message
    )
    Start-Sleep -Seconds 10
    exit 1
}

$webhookUrl = $config.webhook
if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
    Show-AppHeader "ERREUR CONFIG" ""
    Show-BoxCentered -Title "ERREUR CONFIG" -Lines @(
        "La cle 'webhook' est absente ou vide dans config_inventory.json."
    )
    Start-Sleep -Seconds 10
    exit 1
}

if (-not $config.teams -or $config.teams.Count -eq 0) {
    Show-AppHeader "ERREUR CONFIG" ""
    Show-BoxCentered -Title "ERREUR CONFIG" -Lines @(
        "Aucune 'team' definie dans config_inventory.json.",
        "Ajoutez un tableau 'teams' dans le fichier."
    )
    Start-Sleep -Seconds 10
    exit 1
}

if (-not $config.sites -or $config.sites.Count -eq 0) {
    Show-AppHeader "ERREUR CONFIG" ""
    Show-BoxCentered -Title "ERREUR CONFIG" -Lines @(
        "Aucun 'site' defini dans config_inventory.json.",
        "Ajoutez un tableau 'sites' dans le fichier."
    )
    Start-Sleep -Seconds 10
    exit 1
}

$teams = @($config.teams)
$sites = @($config.sites)

# =====================================================================
#   ETAPE 1/4 - INTRO
# =====================================================================
Show-AppHeader "ÉTAPE 1/4 — INTRODUCTION" "Présentation de l'inventaire Spacefoot"

$introLines = @"
[FR] Ce programme collecte automatiquement les informations TECHNIQUES
     de votre ordinateur (modele, numero de serie, OS, CPU, RAM,
     IP interne, MAC...). Aucune donnee personnelle n'est collecte.

[EN] This program automatically collects TECHNICAL information about
     your device (model, serial number, OS, CPU, RAM, internal IP, MAC...).
     No personal data is collected.

En continuant, vous acceptez de participer a cet inventaire.
"@ -split "`n"

foreach ($l in $introLines) {
    Center-Write $l ([ConsoleColor]::White)
}
Write-Host ""
Center-Write "Appuyez sur ENTREE pour continuer..." ([ConsoleColor]::Gray)
[Console]::ReadKey($true) | Out-Null

# =====================================================================
#   ETAPE 1/4 - IDENTITE UTILISATEUR
# =====================================================================
Show-AppHeader "ÉTAPE 1/4 — IDENTITÉ UTILISATEUR" "Merci de renseigner vos informations"

Write-Host ""
$firstName = Read-Host "  Entrez votre prenom / Enter your first name"
$lastName  = Read-Host "  Entrez votre nom / Enter your last name"
Write-Host ""

if (-not [string]::IsNullOrWhiteSpace($firstName)) {
    $ti = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo
    $firstName = $ti.ToTitleCase($firstName.ToLower())
}
if (-not [string]::IsNullOrWhiteSpace($lastName)) {
    $lastName = $lastName.ToUpper()
}

# =====================================================================
#   ETAPE 2/4 - TEAM
# =====================================================================
$teamOptions = @()
for ($i = 0; $i -lt $teams.Count; $i++) {
    $teamOptions += ("[{0}] {1}" -f ($i + 1), $teams[$i])
}

$teamResult = Show-MenuCentered `
    -StepTitle "ÉTAPE 2/4 — TEAM / SERVICE" `
    -Subtitle  "Choisissez votre équipe au sein de Spacefoot" `
    -Options   $teamOptions

$teamIndex = $teamResult[0]
$teamLabel = $teams[$teamIndex]

# =====================================================================
#   ETAPE 3/4 - ETABLISSEMENT
# =====================================================================
$siteOptions = @()
for ($i = 0; $i -lt $sites.Count; $i++) {
    $siteOptions += ("[{0}] {1}" -f ($i + 1), $sites[$i])
}

$siteResult = Show-MenuCentered `
    -StepTitle "ÉTAPE 3/4 — LIEU / ÉTABLISSEMENT" `
    -Subtitle  "Sélectionnez le site où vous travaillez" `
    -Options   $siteOptions

$siteIndex = $siteResult[0]
$siteLabel = $sites[$siteIndex]

# =====================================================================
#   ETAPE 3/4 - COLLECTE TECHNIQUE
# =====================================================================
Show-AppHeader "ÉTAPE 3/4 — COLLECTE TECHNIQUE" "Récupération automatique des informations machine"
Center-Write "Veuillez patienter, collecte en cours..." ([ConsoleColor]::Gray)
Write-Host ""

$PCName = $env:COMPUTERNAME
$User   = $env:USERNAME

$Sys  = Get-WmiObject Win32_ComputerSystem
$BIOS = Get-WmiObject Win32_BIOS
$OS   = Get-WmiObject Win32_OperatingSystem
$CPU  = Get-WmiObject Win32_Processor
$RAM  = [math]::Round($Sys.TotalPhysicalMemory / 1GB)

$IP = (Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -ne "127.0.0.1" } |
       Select-Object -First 1 -ExpandProperty IPAddress)

$MAC = (Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" } |
        Select-Object -First 1 -ExpandProperty MacAddress)

# =====================================================================
#   PREPARATION JSON
# =====================================================================
$body = @{
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
    os           = ($OS.Caption + " " + $OS.Version)
    cpu          = $CPU.Name
    ram          = "$RAM GB"
    ip           = $IP
    mac          = $MAC
} | ConvertTo-Json -Depth 5

# =====================================================================
#   ETAPE 4/4 - RECAP (ECRAN 1)
# =====================================================================
Show-AppHeader "ÉTAPE 4/4 — RÉCAPITULATIF" "Vérifiez les informations avant envoi"

$recapLines = @(
    "Prenom        : $firstName",
    "Nom           : $lastName",
    "Team          : $teamLabel",
    "Etablissement : $siteLabel",
    "",
    "OS Type       : Windows",
    "Nom du PC     : $PCName",
    "Utilisateur   : $User",
    "Fabricant     : $($Sys.Manufacturer)",
    "Modele        : $($Sys.Model)",
    "No. de serie  : $($BIOS.SerialNumber)",
    "Systeme       : $($OS.Caption) $($OS.Version)",
    "CPU           : $($CPU.Name)",
    "RAM           : ${RAM} GB",
    "IP interne    : $IP",
    "Adresse MAC   : $MAC"
)

Show-BoxCentered -Title "RECAPITULATIF" -Lines $recapLines
Write-Host ""
Center-Write "Vérifiez bien les informations ci-dessus." ([ConsoleColor]::White)
Center-Write "Appuyez sur ENTREE pour passer à la confirmation..." ([ConsoleColor]::Gray)
[Console]::ReadKey($true) | Out-Null

# =====================================================================
#   ETAPE 4/4 - CONFIRMATION (ECRAN 2)
# =====================================================================
$confirmOptions = @("[ VALIDER ]", "[ ANNULER ]")

$confResult  = Show-MenuCentered `
    -StepTitle "ÉTAPE 4/4 — CONFIRMATION" `
    -Subtitle  "Validez ou annulez l’envoi de votre inventaire" `
    -Options   $confirmOptions

$finalChoice = $confResult[1]

# =====================================================================
#   ENVOI
# =====================================================================
Show-AppHeader "ENVOI DES DONNÉES" "Transmission vers l'inventaire central"

if ($finalChoice -eq "[ VALIDER ]") {
    try {
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
        Center-Write "[OK] Inventaire envoye avec succes. Merci !" ([ConsoleColor]::Green)
        if ($response) {
            Center-Write "Statut retour : $response" ([ConsoleColor]::DarkGray)
        }
    } catch {
        Center-Write "[ERREUR] Impossible d'envoyer l'inventaire." ([ConsoleColor]::Red)
        Center-Write $_.Exception.Message ([ConsoleColor]::DarkGray)
    }
} else {
    Center-Write "Envoi annule par l'utilisateur." ([ConsoleColor]::Red)
}

Write-Host ""
Center-Write "Cette fenetre se fermera dans 10 secondes..." ([ConsoleColor]::White)
Start-Sleep -Seconds 10
