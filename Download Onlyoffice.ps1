$repoOwner = "ONLYOFFICE"
$repoName  = "DesktopEditors"
$assetName = "DesktopEditors_x64.msi"
$outputDir = "$env:USERPROFILE\Downloads"

if (Test-Path -Path "C:\Program Files\ONLYOFFICE\DesktopEditors") {
    Write-Output "ONLYOFFICE Desktop Editors est déjà installé."
    exit 0
}

if (Test-Path -Path (Join-Path $outputDir $assetName)) {
    Write-Output "Le fichier $assetName existe déjà dans $outputDir."
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