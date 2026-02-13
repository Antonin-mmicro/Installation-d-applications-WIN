$repoOwner = "rustdesk"
$repoName  = "rustdesk"
$assetPattern = "rustdesk-*-x86_64.msi"
$outputDir = "$env:USERPROFILE\Downloads"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}

# 🔹 URL pour la dernière release
$latestUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"

$release = Invoke-RestMethod -Uri $latestUrl -Headers @{
    "User-Agent" = "PowerShell"
}

# 🔹 Cherche le bon MSI (x86_64)
$asset = $release.assets | Where-Object { $_.name -like $assetPattern }

if (-not $asset) {
    Write-Error "Impossible de trouver un MSI correspondant dans la dernière release."
    exit 1
}

$downloadUrl = $asset.browser_download_url
$outputFile = Join-Path $outputDir $asset.name

Write-Output "Dernière version trouvée : $($release.tag_name)"
Write-Output "Téléchargement de $($asset.name)..."

Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -Headers @{
    "User-Agent" = "PowerShell"
}