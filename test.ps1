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
    Write-Host "La version installée ($installedVersion) est à jour par rapport à la version GitHub ($githubTag)."
    exit 0
} else {
    Write-Host "La version installée ($installedVersion) n'est pas à jour par rapport à la version GitHub ($githubTag)."
    exit 1
}