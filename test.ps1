$selectedRelease = (Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases").tag_name

$selectedRelease = $releasesJson |
        Where-Object { 
            $_.assets | Where-Object { $_.name -eq $assetName } 
        } |
        Sort-Object {[datetime]$_.published_at} -Descending |
        Select-Object -First 1

Write-Host "$selectedRelease"