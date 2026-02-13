$repoOwner = "ONLYOFFICE"
$repoName  = "DesktopEditors"
$assetName = "DesktopEditors_x64.msi"
$outputDir = "$env:USERPROFILE\Downloads"

if (Test-Path -Path (Join-Path $outputDir $assetName)) {
    Write-Output "Le fichier $assetName existe déjà dans $outputDir."
    exit 0
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

Write-Output "Fichier téléchargé dans : $outputFile"

Write-Host "Installation de $assetName ..." 
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$outputFile`" /qn" -Wait 
Write-Output "$assetName installé avec succès !"
