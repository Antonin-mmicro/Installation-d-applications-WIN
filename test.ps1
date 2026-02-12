param(
    [string]$RepoOwner = "ONLYOFFICE",
    [string]$RepoName  = "DesktopEditors",
    [string]$AssetName = "DesktopEditors_x64.msi",
    [string]$OutputDir = "$env:USERPROFILE\Downloads"
)

$ErrorActionPreference = "Stop"

# TLS 1.2 uniquement (compatible PS 5.1)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log {
    param([string]$Message)
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - $Message"
}

try {

    if (!(Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    $headers = @{
        "User-Agent" = "PowerShell"
    }

    $releasesUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases"

    Write-Log "Récupération des releases..."

    $releases = Invoke-RestMethod -Uri $releasesUrl -Headers $headers

    $release = $releases |
        Where-Object { $_.assets.name -contains $AssetName } |
        Sort-Object {[datetime]$_.published_at} -Descending |
        Select-Object -First 1

    if (-not $release) {
        throw "Aucune release trouvée avec $AssetName"
    }

    $asset = $release.assets | Where-Object { $_.name -eq $AssetName }
    $downloadUrl = $asset.browser_download_url

    $outputFile = Join-Path $OutputDir $AssetName

    Write-Log "Téléchargement..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -Headers $headers

    Write-Log "Terminé : $outputFile"
}
catch {
    Write-Host "ERREUR : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
