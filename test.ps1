$assetName = "DesktopEditors"

$releasesJson = Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases"

$selectedRelease = $releasesJson |
    Where-Object {
        $_.assets.name -contains $assetName
    } |
    Sort-Object published_at -Descending |
    Select-Object -First 1

Write-Host $selectedRelease.tag_name