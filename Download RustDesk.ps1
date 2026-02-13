$repoOwner = "rustdesk"
$repoName  = "rustdesk"
$assetName = "rustdesk-1.4.5-x86_64.msi"
$outputDir = "$env:USERPROFILE\Downloads"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}

$releasesUrl  = "https://api.github.com/repos/$repoOwner/$repoName/releases"
$releasesJson = Invoke-RestMethod -Uri $releasesUrl -Headers @{
    "User-Agent" = "PowerShell"
}

$selectedRelease = $releasesJson |
    Where-Object { 
        $_.assets | Where-Object { $_.name -eq $assetName } 
    } |
    Sort-Object {[datetime]$_.published_at} -Descending |
    Select-Object -First 1

If (-not $selectedRelease) {
    Write-Error "Impossible de trouver une release avec $assetName"
    exit 1
}

$asset = $selectedRelease.assets | Where-Object { $_.name -eq $assetName }
$downloadUrl = $asset.browser_download_url

Write-Output "Release trouvée : $($selectedRelease.tag_name)"
Write-Output "Téléchargement de $assetName ..."

$outputFile = Join-Path $outputDir $assetName
Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -Headers @{
    "User-Agent" = "PowerShell"
}