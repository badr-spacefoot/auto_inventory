# =====================================================================
#   INVENTAIRE WINDOWS - Script principal (core)
#   Version : v1.3.0 - 2025-12-02
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
#  UI : couleurs + plein écran
# ---------------------------------------------------------------------
$rawUI = $Host.UI.RawUI
$rawUI.BackgroundColor = 'Black'
$rawUI.ForegroundColor = 'White'
Clear-Host

# Maximise la fenêtre PowerShell (Win32 API)
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

function Draw-TitleBar {
    param(
        [string]$Title
    )
    $width = Get-WindowWidth
    Write-Host ("=" * $width) -ForegroundColor DarkRed
    Center-Write $Title ([ConsoleColor]::White)
    Write-Host ("=" * $width) -ForegroundColor DarkRed
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
    $boxWidth = [Math]::Min($maxLen + 4, $width - 4)

    $top    = "╔" + ("═" * ($boxWidth - 2)) + "╗"
    $bottom = "╚" + ("═" * ($boxWidth - 2)) + "╝"

    Center-Write $top ([ConsoleColor]::DarkRed)

    # Titre
    $titleLine = " " + $Title + " "
    if ($titleLine.Length -gt ($boxWidth - 2)) {
        $titleLine = $titleLine.Substring(0, $boxWidth - 2)
    }
    $titlePadded = $titleLine.PadRight($boxWidth - 2)
    Center-Write ("║" + $titlePadded + "║") ([ConsoleColor]::White)

    # Ligne vide
    Center-Write ("║" + (" " * ($boxWidth - 2)) + "║") ([ConsoleColor]::White)

    foreach ($line in $Lines) {
        $text = " " + $line
        if ($text.Length -gt ($boxWidth - 2)) {
            $text = $text.Substring(0, $boxWidth - 2)
        }
        $textPadded = $text.PadRight($boxWidth - 2)
        Center-Write ("║" + $textPadded + "║") ([ConsoleColor]::White)
    }

    Center-Write $bottom ([ConsoleColor]::DarkRed)
}

function Show-MenuCentered {
    param(
        [string]$Title,
        [string]$Subtitle,
        [string[]]$Options
    )

    $index = 0
    while ($true) {
        Clear-Host
        Draw-TitleBar $Title
        if ($Subtitle) {
            Center-Write $Subtitle ([ConsoleColor]::Gray)
            Write-Host ""
        }

        Center-Write "Utilisez les fleches HAUT/BAS puis ENTREE pour valider" ([ConsoleColor]::White)
        Write-Host ""

        for ($i = 0; $i -lt $Options.Length; $i++) {
            $label = $Options[$i]
            if ($i -eq $index) {
                Center-Write (" > " + $label + " < ") ([ConsoleColor]::Black) ([ConsoleColor]::DarkRed)
            } else {
                Center-Write ("   " + $label + "   ") ([ConsoleColor]::White)
            }
        }

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow"   { if ($index -gt 0) { $index-- } else { $index = $Options.Length - 1 } }
            "DownArrow" { if ($index -lt $Options.Length - 1) { $index++ } else { $index = 0 } }
            "Enter"     { return ,@($index, $Options[$index]) }
        }
    }
}

# ---------------------------------------------------------------------
#  Affichage version
# ---------------------------------------------------------------------
$VERSION = "v1.3.0 - 2025-12-02"
Draw-TitleBar "INVENTAIRE INFORMATIQUE - SPACEFOOT (CORE $VERSION)"
Center-Write ""
Start-Sleep -Milliseconds 700

# =====================================================================
#   CHARGEMENT CONFIG (webhook + listes teams/sites)
# =====================================================================

$baseDir = $env:SPACEFOOT_CONFIGDIR
if ([string]::IsNullOrWhiteSpace($baseDir)) {
    $baseDir = (Get-Location).Path
}

$configPath = Join-Path $baseDir "config_inventory.json"

if (!(Test-Path $configPath)) {
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
    Show-BoxCentered -Title "ERREUR LECTURE CONFIG" -Lines @(
        "Impossible de lire ou parser 'config_inventory.json'.",
        $_.Exception.Message
    )
    Start-Sleep -Seconds 10
    exit 1
}

$webhookUrl = $config.webhook
if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
    Show-BoxCentered -Title "ERREUR CONFIG" -Lines @(
        "La cle 'webhook' est absente ou vide dans config_inventory.json."
    )
    Start-Sleep -Seconds 10
    exit 1
}

if (-not $config.teams -or $config.teams.Count -eq 0) {
    Show-BoxCentered -Title "ERREUR CONFIG" -Lines @(
        "Aucune 'team' definie dans config_inventory.json.",
        "Ajoutez un tableau 'teams' dans le fichier."
    )
    Start-Sleep -Seconds 10
    exit 1
}

if (-not $config.sites -or $config.sites.Count -eq 0) {
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
#   MESSAGE D’INTRO
# =====================================================================
Clear-Host
Draw-TitleBar "INVENTAIRE DES POSTES INFORMATIQUES"

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
#   IDENTITE UTILISATEUR
# =====================================================================
Clear-Host
Draw-TitleBar "IDENTITE UTILISATEUR"

Center-Write ""
Center-Write "Merci de renseigner vos informations d'identite :" ([ConsoleColor]::White)
Center-Write ""

$width = Get-WindowWidth

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
#   TEAM (menu basé sur $teams)
# =====================================================================
$teamOptions = @()
for ($i = 0; $i -lt $teams.Count; $i++) {
    $teamOptions += ("{0} - {1}" -f ($i + 1), $teams[$i])
}

$teamResult = Show-MenuCentered -Title "SELECTION TEAM" -Subtitle "Selectionnez votre Team / Select your team" -Options $teamOptions
$teamIndex  = $teamResult[0]
$teamLabel  = $teams[$teamIndex]

# =====================================================================
#   ETABLISSEMENT (menu basé sur $sites)
# =====================================================================
$siteOptions = @()
for ($i = 0; $i -lt $sites.Count; $i++) {
    $siteOptions += ("{0} - {1}" -f ($i + 1), $sites[$i])
}

$siteResult = Show-MenuCentered -Title "SELECTION ETABLISSEMENT" -Subtitle "Selectionnez votre etablissement / Select your site" -Options $siteOptions
$siteIndex  = $siteResult[0]
$siteLabel  = $sites[$siteIndex]

# =====================================================================
#   COLLECTE INFOS MACHINE
# =====================================================================
Clear-Host
Draw-TitleBar "COLLECTE DES INFORMATIONS TECHNIQUES"

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
#   JSON A ENVOYER
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
#   RECAP + CONFIRMATION
# =====================================================================
Clear-Host
Draw-TitleBar "CONFIRMATION AVANT ENVOI"

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
Center-Write "Confirmez-vous l'envoi de ces informations ?" ([ConsoleColor]::White)
Center-Write ""

$confirmOptions = @("[ VALIDER ]", "[ ANNULER ]")
$confResult  = Show-MenuCentered -Title "CONFIRMATION" -Subtitle "Choisissez une option" -Options $confirmOptions
$finalChoice = $confResult[1]

# =====================================================================
#   ENVOI
# =====================================================================
Clear-Host
Draw-TitleBar "ENVOI DES DONNEES"

if ($finalChoice -eq "[ VALIDER ]") {
    try {
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
        Center-Write "[OK] Inventaire envoye avec succes. Merci !" ([ConsoleColor]::Green)
        if ($response) {
            Center-Write "Statut retour : $response" ([ConsoleColor]::Gray)
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
