$release = Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest"

$msiAsset = $release.assets |
    Where-Object { $_.name -like "*.msi" } |
    Select-Object -First 1

if ($msiAsset) {
    Write-Host "Version :" $release.tag_name
    Write-Host "MSI :" $msiAsset.browser_download_url
}
else {
    Write-Host "Aucun MSI trouvé."
}