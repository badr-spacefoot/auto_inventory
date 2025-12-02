# =====================================================================
#   INVENTAIRE WINDOWS - Script principal (core)
#   Version : v1.2.1 - 2025-12-02
#   Auteur  : Spacefoot / Badr
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------------
#  Sécurité : le core doit être lancé via le launcher
#  (le launcher définit SPACEFOOT_INVENTAIRE=1 avant Invoke-Expression)
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

# Palette globale style "BIOS"
$rawUI = $Host.UI.RawUI
$rawUI.BackgroundColor = 'Black'
$rawUI.ForegroundColor = 'White'
Clear-Host

# Affichage de la version du core
$VERSION = "v1.2.1 - 2025-12-02"
Write-Host "Loaded INVENTORY CORE version: $VERSION" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Milliseconds 700

# =====================================================================
#   CHARGEMENT CONFIG (webhook + listes teams/sites)
# =====================================================================
$configPath = Join-Path $PSScriptRoot "config_inventory.json"

if (!(Test-Path $configPath)) {
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  ERREUR CONFIG" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "Fichier 'config_inventory.json' introuvable." -ForegroundColor White
    Write-Host "Ajoutez-le dans le meme dossier que ce script." -ForegroundColor White
    Start-Sleep -Seconds 10
    exit 1
}

try {
    $configJson = Get-Content $configPath -Raw
    $config = $configJson | ConvertFrom-Json
} catch {
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  ERREUR LECTURE CONFIG" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "Impossible de lire ou parser 'config_inventory.json'." -ForegroundColor White
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Start-Sleep -Seconds 10
    exit 1
}

$webhookUrl = $config.webhook
if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  ERREUR CONFIG" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "La cle 'webhook' est absente ou vide dans config_inventory.json." -ForegroundColor White
    Start-Sleep -Seconds 10
    exit 1
}

# Listes dynamiques OBLIGATOIRES (uniquement depuis config_inventory.json)
if (-not $config.teams -or $config.teams.Count -eq 0) {
    Write-Host "ERREUR: aucune 'team' definie dans config_inventory.json." -ForegroundColor Red
    Write-Host "Ajoutez un tableau 'teams' dans le fichier de config." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    exit 1
}

if (-not $config.sites -or $config.sites.Count -eq 0) {
    Write-Host "ERREUR: aucun 'site' defini dans config_inventory.json." -ForegroundColor Red
    Write-Host "Ajoutez un tableau 'sites' dans le fichier de config." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    exit 1
}

$teams = @($config.teams)
$sites = @($config.sites)

# =====================================================================
#   FONCTION MENU BIOS-LIKE (fleches + Entrée)
#   Retourne : [ indexSelectionne , texteSelectionne ]
# =====================================================================
function Show-Menu {
    param(
        [string]$Title,
        [string[]]$Options,
        [scriptblock]$PreRender = $null
    )

    $index = 0

    while ($true) {
        Clear-Host

        if ($PreRender) {
            & $PreRender
        } else {
            Write-Host "====================================================" -ForegroundColor Red
            Write-Host ("  " + $Title) -ForegroundColor White
            Write-Host "====================================================" -ForegroundColor Red
            Write-Host ""
        }

        Write-Host " Utilisez les fleches HAUT/BAS puis ENTREE pour valider" -ForegroundColor White
        Write-Host ""

        for ($i = 0; $i -lt $Options.Length; $i++) {
            if ($i -eq $index) {
                Write-Host (" > " + $Options[$i]) -ForegroundColor White -BackgroundColor DarkRed
                $rawUI.BackgroundColor = 'Black'
            } else {
                Write-Host ("   " + $Options[$i]) -ForegroundColor White
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

# =====================================================================
#   MESSAGE D’INTRO
# =====================================================================
$infoMessage = @"
====================================================
        INVENTAIRE DES POSTES INFORMATIQUES
====================================================

[FR]
Ce programme collecte automatiquement les informations
TECHNIQUES de votre ordinateur (modele, numero de serie,
OS, CPU, RAM, IP interne, MAC...). Aucune donnee personnelle
n'est collecte. Duree : ~10 secondes.

[EN]
This program automatically collects TECHNICAL information
about your device (model, serial number, OS, CPU, RAM,
internal IP, MAC...). No personal data is collected.
Duration: ~10 seconds.

En continuant, vous acceptez de participer a cet inventaire.
====================================================
"@

Write-Host "====================================================" -ForegroundColor Red
Write-Host "   INVENTAIRE INFORMATIQUE - SPACEFOOT" -ForegroundColor White
Write-Host "====================================================" -ForegroundColor Red
Write-Host ""
Write-Host $infoMessage -ForegroundColor White
Start-Sleep -Seconds 2

# =====================================================================
#   IDENTITE UTILISATEUR
# =====================================================================
Write-Host "----------------- IDENTITE UTILISATEUR -----------------" -ForegroundColor Red
$firstName = Read-Host "Entrez votre prenom / Enter your first name"
$lastName  = Read-Host "Entrez votre nom / Enter your last name"
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

$teamResult = Show-Menu -Title "Selectionnez votre Team / Select your team" -Options $teamOptions
$teamIndex  = $teamResult[0]
$teamLabel  = $teams[$teamIndex]

# =====================================================================
#   ETABLISSEMENT (menu basé sur $sites)
# =====================================================================
$siteOptions = @()
for ($i = 0; $i -lt $sites.Count; $i++) {
    $siteOptions += ("{0} - {1}" -f ($i + 1), $sites[$i])
}

$siteResult = Show-Menu -Title "Selectionnez votre etablissement / Select your site" -Options $siteOptions
$siteIndex  = $siteResult[0]
$siteLabel  = $sites[$siteIndex]

# =====================================================================
#   COLLECTE INFOS MACHINE
# =====================================================================
Write-Host ""
Write-Host "----------------- COLLECTE DES INFORMATIONS TECHNIQUES -----------------" -ForegroundColor Red

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
$recap = @"
=============== RECAPITULATIF ===============

Prenom          : $firstName
Nom             : $lastName
Team            : $teamLabel
Etablissement   : $siteLabel

OS Type         : Windows
Nom du PC       : $PCName
Utilisateur OS  : $User
Fabricant       : $($Sys.Manufacturer)
Modele          : $($Sys.Model)
Numero de serie : $($BIOS.SerialNumber)
Systeme         : $($OS.Caption) $($OS.Version)
CPU             : $($CPU.Name)
RAM             : ${RAM} GB
IP interne      : $IP
Adresse MAC     : $MAC

=============================================
"@

$confirmOptions = @("[ VALIDER ]", "[ ANNULER ]")

$preRenderConfirm = {
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "   CONFIRMATION AVANT ENVOI" -ForegroundColor White
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $recap -ForegroundColor White
    Write-Host ""
    Write-Host "Confirmez-vous l'envoi de ces informations ?" -ForegroundColor White
    Write-Host ""
}

$confResult  = Show-Menu -Title "" -Options $confirmOptions -PreRender $preRenderConfirm
$finalChoice = $confResult[1]

if ($finalChoice -eq "[ VALIDER ]") {
    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
        Write-Host ""
        Write-Host "[OK] Inventaire envoye avec succes. Merci !" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "[ERREUR] Impossible d'envoyer l'inventaire." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
    }
} else {
    Write-Host ""
    Write-Host "Envoi annule par l'utilisateur." -ForegroundColor Red
}

Write-Host ""
Write-Host "Cette fenetre se fermera dans 10 secondes..." -ForegroundColor White
Start-Sleep -Seconds 15
