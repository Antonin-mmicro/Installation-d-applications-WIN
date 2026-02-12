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

$ErrorActionPreference = "Stop"

# Force TLS 1.2+
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Tls12 -bor `
    [Net.SecurityProtocolType]::Tls13

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    if (-not $Silent) {
        switch ($Level) {
            "ERROR" { Write-Host $line -ForegroundColor Red }
            "WARN"  { Write-Host $line -ForegroundColor Yellow }
            default { Write-Host $line -ForegroundColor Cyan }
        }
    }
}

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
            Write-Log "Retry $i/$Retries dans $delay sec..." "WARN"
            Start-Sleep -Seconds $delay
        }
    }
}

try {

    if (!(Test-Path $OutputDir)) {
        Write-Log "Création du dossier $OutputDir"
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    $outputFile = Join-Path $OutputDir $AssetName

    if ((Test-Path $outputFile) -and -not $Force) {
        Write-Log "Le fichier existe déjà. Utilise -Force pour écraser." "WARN"
        exit 0
    }

    $headers = @{
        "User-Agent" = "PowerShell-Script"
        "Accept"     = "application/vnd.github+json"
    }

    $releasesUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases"

    Write-Log "Récupération des releases..."

    $releasesJson = Invoke-WithRetry {
        Invoke-RestMethod -Uri $releasesUrl -Headers $headers
    } -Retries $MaxRetries

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
    Write-Log "Téléchargement en cours..."

    Invoke-WithRetry {
        Invoke-WebRequest `
            -Uri $downloadUrl `
            -OutFile $outputFile `
            -Headers $headers
    } -Retries $MaxRetries

    Write-Log "Téléchargement terminé : $outputFile"

    $fileHash = Get-FileHash -Path $outputFile -Algorithm SHA256
    Write-Log "SHA256 : $($fileHash.Hash)"

    $signature = Get-AuthenticodeSignature $outputFile
    Write-Log "Signature : $($signature.Status)"

    if ($InstallAfterDownload) {

        Write-Log "Installation silencieuse..."

        $msiArgs = "/i `"$outputFile`" /qn /norestart"

        $process = Start-Process "msiexec.exe" `
            -ArgumentList $msiArgs `
            -Wait `
            -PassThru

        if ($process.ExitCode -ne 0) {
            throw "Erreur installation. Code: $($process.ExitCode)"
        }

        Write-Log "Installation réussie ✔"
    }

    Write-Log "Script terminé ✔"
}
catch {
    Write-Log $_.Exception.Message "ERROR"
    exit 1
}
