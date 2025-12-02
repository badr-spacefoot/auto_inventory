# =====================================================================
#   INVENTAIRE WINDOWS - Script principal (core)
#   Version : v1.0
#   Auteur  : Spacefoot / Badr
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =====================================================================
#   CHARGEMENT CONFIG (webhook dans config_inventory.json)
# =====================================================================
$configPath = Join-Path $PSScriptRoot "config_inventory.json"

if (!(Test-Path $configPath)) {
    Write-Host "ERROR: Missing configuration file 'config_inventory.json'." -ForegroundColor Red
    Write-Host "Please add it next to this script." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    exit 1
}

try {
    $configJson = Get-Content $configPath -Raw
    $config = $configJson | ConvertFrom-Json
    $webhookUrl = $config.webhook
} catch {
    Write-Host "ERROR: Unable to read or parse 'config_inventory.json'." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Start-Sleep -Seconds 10
    exit 1
}

if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
    Write-Host "ERROR: 'webhook' is missing or empty in config_inventory.json." -ForegroundColor Red
    Start-Sleep -Seconds 10
    exit 1
}

# =====================================================================
#   FONCTION MENU BIOS-LIKE (fleches + Entrée)
#   Possibilite d'afficher un header custom via -PreRender
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
            Write-Host "===================================================="
            Write-Host "  $Title"
            Write-Host "===================================================="
            Write-Host ""
        }

        Write-Host " Utilisez les fleches HAUT/BAS puis ENTREE pour valider"
        Write-Host ""

        for ($i = 0; $i -lt $Options.Length; $i++) {
            if ($i -eq $index) {
                Write-Host ("> " + $Options[$i]) -ForegroundColor Yellow
            } else {
                Write-Host ("  " + $Options[$i])
            }
        }

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow"   { if ($index -gt 0) { $index-- } else { $index = $Options.Length - 1 } }
            "DownArrow" { if ($index -lt $Options.Length - 1) { $index++ } else { $index = 0 } }
            "Enter"     { return $Options[$index] }
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

Clear-Host
Write-Host $infoMessage -ForegroundColor Cyan
Start-Sleep -Seconds 2

# =====================================================================
#   IDENTITE UTILISATEUR
# =====================================================================
$firstName = Read-Host "Entrez votre prenom / Enter your first name"
$lastName  = Read-Host "Entrez votre nom / Enter your last name"

# Normalisation prenom/nom
if (-not [string]::IsNullOrWhiteSpace($firstName)) {
    $ti = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo
    $firstName = $ti.ToTitleCase($firstName.ToLower())
}
if (-not [string]::IsNullOrWhiteSpace($lastName)) {
    $lastName = $lastName.ToUpper()
}

# =====================================================================
#   TEAM (menu fleches)
# =====================================================================
$teamOptions = @(
    "1 - B2C",
    "2 - DG",
    "3 - MP",
    "4 - Pub",
    "5 - Cata",
    "6 - Design",
    "7 - Compta",
    "8 - RH"
)

$teamChoice = Show-Menu -Title "Selectionnez votre Team / Select your team" -Options $teamOptions

$teamLabel = switch -Regex ($teamChoice) {
    "^1" { "B2C" }
    "^2" { "DG" }
    "^3" { "MP" }
    "^4" { "Pub" }
    "^5" { "Cata" }
    "^6" { "Design" }
    "^7" { "Compta" }
    "^8" { "RH" }
    default { "" }
}

# =====================================================================
#   ETABLISSEMENT (menu fleches)
# =====================================================================
$siteOptions = @(
    "1 - Siege social :  Levallois-Perret",
    "2 - R&D / Design : Charleville-Mezieres",
    "3 - Entrepot logistique : Montlouis-sur-Loire",
    "4 - Boutique : Boulevard-du-Golf (BDG)",
    "5 - Boutique : Endurance-Store (ES)",
    "6 - Boutique : Foot-Store (FS)",
    "7 - Boutique : Paris-Ventoux-Cycles (PVC)",
    "8 - Boutique : Sport-et-Loisirs (SEL)"
)

$siteChoice = Show-Menu -Title "Selectionnez votre etablissement / Select your site" -Options $siteOptions

$siteLabel = switch -Regex ($siteChoice) {
    "^1" { "Siège social :  Levallois-Perret" }
    "^2" { "R&D / Design : Charleville-Mézières" }
    "^3" { "Entrepôt logistique : Montlouis-sur-Loire" }
    "^4" { "Boutique : Boulevard-du-Golf (BDG)" }
    "^5" { "Boutique : Endurance-Store (ES)" }
    "^6" { "Boutique : Foot-Store (FS)" }
    "^7" { "Boutique : Paris-Ventoux-Cycles (PVC)" }
    "^8" { "Boutique : Sport-et-Loisirs (SEL)" }
    default { "" }
}

# =====================================================================
#   COLLECTE INFOS MACHINE
# =====================================================================
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
#   RECAP + CONFIRMATION (menu fleches)
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
    Write-Host $recap -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Confirmez-vous l'envoi de ces informations ?" -ForegroundColor Cyan
    Write-Host ""
}

$finalChoice = Show-Menu -Title "" -Options $confirmOptions -PreRender $preRenderConfirm

if ($finalChoice -eq "[ VALIDER ]") {
    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
        Write-Host ""
        Write-Host "[OK] Inventaire envoye avec succes. Merci !" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "[ERREUR] Impossible d'envoyer l'inventaire." -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
} else {
    Write-Host ""
    Write-Host "Envoi annule par l'utilisateur." -ForegroundColor Red
}

Write-Host ""
Write-Host "Cette fenetre se fermera dans 10 secondes..."
Start-Sleep -Seconds 10
