$release = Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest"

$msiAsset = $release.assets |
    Where-Object { $_.name -like "*x64*.msi" } |
    Select-Object -First 1

if ($msiAsset) {
    Write-Host "Version :" $release.tag_name
    Write-Host "Téléchargement :" $msiAsset.browser_download_url
}

$installedVersion = "9.2.1.43"
$githubTag = "v9.2.1"

# Enlever le "v"
$githubVersionClean = $githubTag.TrimStart("v")

# Convertir en type Version
$installed = [version]$installedVersion
$github = [version]$githubVersionClean

# Comparer uniquement Major.Minor.Build
if ($installed.Major -eq $github.Major -and
    $installed.Minor -eq $github.Minor -and
    $installed.Build -eq $github.Build)
    {

    Write-Host "Même version fonctionnelle"
    Write-Host "Version installée : $installedVersion"
    Write-Host "Version GitHub : $githubTag"
    Write-Host "Version Major.Minor.Build : " $installed.Major"."$installed.Minor"."$installed.Build
    Write-Host "Version GitHub Major.Minor.Build : " $github.Major"."$github.Minor"."$github.Build
}
else {
    Write-Host "Versions différentes"
}