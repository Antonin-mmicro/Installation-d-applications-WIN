$repoOwner = "ONLYOFFICE"
$repoName  = "DesktopEditors"
$assetName = "DesktopEditors_x64.msi"
$outputDir = "$env:USERPROFILE\Downloads"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}

if (Test-Path -Path "C:\Program Files\ONLYOFFICE\DesktopEditors\DesktopEditors.exe") {
    $release = Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest"

    $msiAsset = $release.assets |
        Where-Object { $_.name -like "*x64*.msi" } |
        Select-Object -First 1

    if ($msiAsset) {
        $version = $release.tag_name
        $url = $msiAsset.browser_download_url
    }

    $installedVersion = (Get-Item "C:\Program Files\ONLYOFFICE\DesktopEditors\DesktopEditors.exe").VersionInfo.ProductVersion
    $githubTag = "$version"



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
        Write-Host "Onlyoffice est déjà installé et à jour."
        exit 0
    } else {
        Write-Host "Onlyoffice est installé mais pas à jour. Version actuelle : $installedVersion, version la plus récente : $githubTag."
        Write-Host "Mise à jour de Onlyoffice..."
        #pass
    }
}

if (Test-Path -Path (Join-Path $outputDir $assetName)) {
    Write-Output "Le fichier $assetName existe déjà dans $outputDir."
    $msiPath = "$env:USERPROFILE\Downloads\DesktopEditors_x64.msi"
    $installer = New-Object -ComObject WindowsInstaller.Installer
    $database = $installer.GetType().InvokeMember(
        "OpenDatabase",
        "InvokeMethod",
        $null,
        $installer,
        @($msiPath, 0)
    )
    $view = $database.GetType().InvokeMember(
        "OpenView",
        "InvokeMethod",
        $null,
        $database,
        @("SELECT Value FROM Property WHERE Property='ProductVersion'")
    )
    $view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)
    $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
    $versionsetup = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)

    $release = Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest"

    $msiAsset = $release.assets |
        Where-Object { $_.name -like "*x64*.msi" } |
        Select-Object -First 1

    if ($msiAsset) {
        $version = $release.tag_name
        $url = $msiAsset.browser_download_url
    }

    $githubTag = "$version"

    $githubVersionClean = $githubTag.TrimStart("v")

    $versionsetup = [version]$versionsetup
    $github = [version]$githubVersionClean

    if ($versionsetup.Major -eq $github.Major -and
        $versionsetup.Minor -eq $github.Minor -and
        $versionsetup.Build -eq $github.Build) 
    {
        Write-Host "Le fichier d'installation $assetName est déjà téléchargé et à jour."
        Write-Host "Installation de $assetName ..."
        Write-Host $versionsetup
        Write-Host "Installation de $assetName ..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$outputDir\$assetName`" /qn" -Wait
        Start-Sleep -Seconds 5
        if (Test-Path -Path "C:\Program Files\ONLYOFFICE\DesktopEditors") {
            Write-Output "Installation de $assetName terminée avec succès."
            Write-Host "Suppression du fichier d'installation $assetName ..."
            Remove-Item -Path (Join-Path $outputDir $assetName) -Force
            Start-Sleep -Seconds 2
            if (-not (Test-Path -Path (Join-Path $outputDir $assetName))) {
                Write-Output "Fichier d'installation $assetName supprimé avec succès."
                exit 0
            } else {
                Write-Warning "Impossible de supprimer le fichier d'installation $assetName. Veuillez le supprimer manuellement."
                exit 1
            }
        } else {
            Write-Error "L'installation de $assetName a échoué."
            exit 1
        }
    } else {
        Write-Host "Le fichier d'installation $assetName est déjà téléchargé mais pas à jour. Version actuelle : $versionsetup, version la plus récente : $githubTag."
        Write-Host "Mise à jour du fichier d'installation $assetName ..."
        $record = $null
        $view   = $null
        $database = $null
        $installer = $null
        Remove-Item -Path (Join-Path $outputDir $assetName) -Force
        Start-Sleep -Seconds 2
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
        Start-Sleep -Seconds 5
        if (Test-Path -Path $outputFile) {
            Write-Output "Téléchargement de $assetName terminé avec succès."
            Write-Host "Installation de $assetName ..."
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$outputFile`" /qn" -Wait
            Start-Sleep -Seconds 5
            if (Test-Path -Path "C:\Program Files\ONLYOFFICE\DesktopEditors") {
                Write-Output "Installation de $assetName terminée avec succès."
                Write-Host "Suppression du fichier d'installation $assetName ..."
                Remove-Item -Path (Join-Path $outputDir $assetName) -Force
                Start-Sleep -Seconds 2
                if (-not (Test-Path -Path (Join-Path $outputDir $assetName))) {
                    Write-Output "Fichier d'installation $assetName supprimé avec succès."
                    exit 0
                } else {
                    Write-Warning "Impossible de supprimer le fichier d'installation $assetName. Veuillez le supprimer manuellement."
                    exit 1
                }
            } else {
                Write-Error "L'installation de $assetName a échoué."
                exit 1
            }
        } else {
            Write-Error "Le téléchargement de $assetName a échoué."
            exit 1
        }
    }
} else {
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
    Start-Sleep -Seconds 5
    if (Test-Path -Path $outputFile) {
        Write-Output "Téléchargement de $assetName terminé avec succès."
        Write-Host "Installation de $assetName ..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$outputFile`" /qn" -Wait
        Start-Sleep -Seconds 5
        if (Test-Path -Path "C:\Program Files\ONLYOFFICE\DesktopEditors") {
            Write-Output "Installation de $assetName terminée avec succès."
            Write-Host "Suppression du fichier d'installation $assetName ..."
            Remove-Item -Path (Join-Path $outputDir $assetName) -Force
            Start-Sleep -Seconds 2
            if (-not (Test-Path -Path (Join-Path $outputDir $assetName))) {
                Write-Output "Fichier d'installation $assetName supprimé avec succès."
                exit 0
            } else {
                Write-Warning "Impossible de supprimer le fichier d'installation $assetName. Veuillez le supprimer manuellement."
                exit 1
            }
        } else {
            Write-Error "L'installation de $assetName a échoué."
            exit 1
        }
    } else {
        Write-Error "Le téléchargement de $assetName a échoué."
        exit 1
    }
}