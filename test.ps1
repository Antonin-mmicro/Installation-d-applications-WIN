$release = Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest"

$msiAsset = $release.assets |
    Where-Object { $_.name -like "*.msi" } |
    Select-Object -First 1

if ($msiAsset) {
    Write-Host "Version :" $release.tag_name
    $url = $msiAsset.browser_download_url
    Write-Host "MSI :" $url
}
else {
    Write-Host "Aucun MSI trouvé."
}