$downloadPage = "https://www.onlyoffice.com/download-desktop.aspx"

$tempMsi = "$env:TEMP\ONLYOFFICE-DesktopEditors-latest.msi"

$html = Invoke-WebRequest -Uri $downloadPage -UseBasicParsing

$link = ($html.Links | Where-Object href -match "\.msi" | Select-Object -First 1).href

if (-not $link) {
    Write-Error "Impossible de trouver un lien MSI dans la page."
    exit 1
}

if ($link -notmatch "^https?://") {
    $uri = [System.Uri]$html.BaseResponse.ResponseUri
    $link = "$($uri.Scheme)://$($uri.Host)$link"
}

Write-Host "Téléchargement du MSI depuis : $link"

Invoke-WebRequest -Uri $link -OutFile $tempMsi -UseBasicParsing

Write-Host "Téléchargement terminé : $tempMsi"
