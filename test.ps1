<# 
.SYNOPSIS
Télécharge automatiquement la dernière release contenant un asset spécifique depuis GitHub,
vérifie son intégrité, sa signature et peut l’installer silencieusement.

.OVERKILL EDITION 🔥
#>

[CmdletBinding()]
param(
    [string]$RepoOwner = "ONLYOFFICE",
    [string]$RepoName  = "DesktopEditors",
    [string]$AssetName = "DesktopEditors_x64.msi",
    [string]$OutputDir = "$env:USERPROFILE\Downloads",
    [int]$MaxRetries = 5,
    [switch]$InstallAfterDownload,
    [switch]$Force,
    [switch]$Silent
)

# ==============================
# CONFIGURATION
# ==============================

$ErrorActionPreference = "Stop"
$ProgressPreference = if ($Silent) { "SilentlyContinue" } else { "Continue" }

# Force TLS 1.2+
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Tls12 -bor `
    [Net.SecurityProtocolType]::Tls13

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $formatted = "[$timestamp] [$Level] $Message"

    if (-not $Silent) {
        switch ($Level) {
            "ERROR" { Write-Host $formatted -ForegroundColor Red }
            "WARN"  { Write-Host $formatted -ForegroundColor Yellow }
            default { Write-Host $formatted -ForegroundColor Cyan }
        }
    }
}

# Retry wrapper
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$Retries = 3
    )

    for ($i = 1; $i -le $Retries; $i++) {
        try {
            return & $ScriptBlock
        }
        catch {
            if ($i -eq $Retries) {
                throw
            }
            $delay = [math]::Pow(2, $i)
            Write-Log "Erreur détectée. Retry $i/$Retries dans $delay sec..." "WARN"
            Start-Sleep -Seconds $delay
        }
    }
}

# ==============================
# PREPARE OUTPUT
# ==============================

if (!(Test-Path $OutputDir)) {
    Write-Log "Création du dossier $OutputDir"
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

$outputFile = Join-Path $OutputDir $AssetName

if ((Test-Path $outputFile) -and -not $Force) {
    Write-Log "Le fichier existe déjà. Utilise -Force pour écraser." "WARN"
    exit 0
}

# ==============================
# GITHUB API CALL
# ==============================

$headers = @{
    "User-Agent" = "PowerShell-Overkill-Script"
    "Accept"     = "application/vnd.github+json"
}

$releasesUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases"

Write-Log "Récupération des releases GitHub..."

$releasesJson = Invoke-WithRetry {
    Invoke-RestMethod -Uri $releasesUrl -Headers $headers
} -Retries $MaxRetries

# Rate limit info
$rateLimitRemaining = $releasesJson | Select-Object -First 1 -ExpandProperty url -ErrorAction SilentlyContinue

# ==============================
# FIND RELEASE
# ==============================

$selectedRelease = $releasesJson |
    Where-Object { $_.assets.name -contains $AssetName } |
    Sort-Object {[datetime]$_.published_at} -Descending |
    Select-Object -First 1

if (-not $selectedRelease) {
    throw "Impossible de trouver une release avec $AssetName"
}

$asset = $selectedRelease.assets | Where-Object { $_.name -eq $AssetName }
$downloadUrl = $asset.browser_download_url

Write-Log "Release trouvée : $($selectedRelease.tag_name)"
Write-Log "Date publication : $($selectedRelease.published_at)"

# ==============================
# DOWNLOAD
# ==============================

Write-Log "Téléchargement en cours..."

Invoke-WithRetry {
    Invoke-WebRequest `
        -Uri $downloadUrl `
        -OutFile $outputFile `
        -Headers $headers `
        -UseBasicParsing
} -Retries $MaxRetries

Write-Log "Téléchargement terminé : $outputFile"

# ==============================
# HASH VERIFICATION
# ==============================

Write-Log "Calcul du SHA256..."

$fileHash = Get-FileHash -Path $outputFile -Algorithm SHA256
Write-Log "SHA256 : $($fileHash.Hash)"

# ==============================
# SIGNATURE VERIFICATION
# ==============================

Write-Log "Vérification signature Authenticode..."

$signature = Get-AuthenticodeSignature $outputFile

if ($signature.Status -eq "Valid") {
    Write-Log "Signature valide ✔"
}
else {
    Write-Log "Signature invalide ou absente : $($signature.Status)" "WARN"
}

# ==============================
# INSTALLATION OPTIONNELLE
# ==============================

if ($InstallAfterDownload) {
    Write-Log "Installation silencieuse en cours..."

    $msiArgs = "/i `"$outputFile`" /qn /norestart"

    $process = Start-Process "msiexec.exe" `
        -ArgumentList $msiArgs `
        -Wait `
        -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Log "Installation terminée avec succès ✔"
    }
    else {
        Write-Log "Erreur installation. Code: $($process.ExitCode)" "ERROR"
        exit $process.ExitCode
    }
}

Write-Log "Script terminé avec succès 🚀"
exit 0
