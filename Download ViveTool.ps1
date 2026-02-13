$repo = "thebookisclosed/ViVe"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"
$destination = "$env:TEMP\ViveTool"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}

if (-not (Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination | Out-Null
} else {
    Write-Host "ViveTool est déjà installé dans : $destination"
    exit 0
}

Write-Host "Récupération de la dernière version de ViveTool..."

$release = Invoke-RestMethod -Uri $apiUrl -Headers @{
    "User-Agent" = "PowerShell"
}

$asset = $release.assets | Where-Object {
    $_.name -match "ViveTool.*\.zip"
} | Select-Object -First 1

if (-not $asset) {
    Write-Error "Impossible de trouver l'archive ViveTool."
    exit 1
}

$zipPath = "$env:TEMP\$($asset.name)"

Write-Host "Téléchargement de $($asset.name)..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

Write-Host "Extraction de ViveTool..."
Expand-Archive -Path $zipPath -DestinationPath $destination -Force

Write-Host "ViveTool installé dans : $destination"