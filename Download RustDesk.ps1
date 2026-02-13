$repoOwner = "rustdesk"
$repoName  = "rustdesk"
$assetPattern = "rustdesk-*-x86_64.msi"
$outputDir = "$env:USERPROFILE\Downloads"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}

if (Test-Path -Path "C:\Program Files\RustDesk") {
    Write-Output "RustDesk est déjà installé."
    exit 0
}

if (Test-Path -Path (Join-Path $outputDir $assetPattern)) {
    Write-Output "Le fichier correspondant à $assetPattern existe déjà dans $outputDir."
    Write-Host "Installation de RustDesk ..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$outputDir\$assetPattern`" /qn" -Wait
    if (Test-Path -Path "C:\Program Files\RustDesk") {
        Write-Output "Installation de RustDesk terminée avec succès."
        Write-Host "Suppression du fichier d'installation correspondant à $assetPattern ..."
        Remove-Item -Path (Join-Path $outputDir $assetPattern) -Force
        Start-Sleep -Seconds 2
        if (-not (Test-Path -Path (Join-Path $outputDir $assetPattern))) {
            Write-Output "Fichier d'installation correspondant à $assetPattern supprimé avec succès."
            exit 0
        } else {
            Write-Warning "Impossible de supprimer le fichier d'installation correspondant à $assetPattern. Veuillez le supprimer manuellement."
            exit 1
        }
    } else {
        Write-Error "L'installation de RustDesk a échoué."
        exit 1
    }
} else {
    $latestUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"

    $release = Invoke-RestMethod -Uri $latestUrl -Headers @{
        "User-Agent" = "PowerShell"
    }

    $asset = $release.assets | Where-Object { $_.name -like $assetPattern }

    if (-not $asset) {
        Write-Error "Impossible de trouver un MSI correspondant dans la dernière release."
        exit 1
    }

    $downloadUrl = $asset.browser_download_url
    $outputFile = Join-Path $outputDir $asset.name

    Write-Output "Dernière version trouvée : $($release.tag_name)"
    Write-Output "Téléchargement de $($asset.name)..."

    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -Headers @{
        "User-Agent" = "PowerShell"
    }
    if (Test-Path -Path $outputFile) {
        Write-Output "Téléchargement de $($asset.name) terminé avec succès."
        Write-Host "Installation de RustDesk ..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$outputFile`" /qn" -Wait
        if (Test-Path -Path "C:\Program Files\RustDesk") {
            Write-Output "Installation de RustDesk terminée avec succès."
            Write-Host "Suppression du fichier d'installation $($asset.name) ..."
            Remove-Item -Path $outputFile -Force
            Start-Sleep -Seconds 2
            if (-not (Test-Path -Path $outputFile)) {
                Write-Output "Fichier d'installation $($asset.name) supprimé avec succès."
                exit 0
            } else {
                Write-Warning "Impossible de supprimer le fichier d'installation $($asset.name). Veuillez le supprimer manuellement."
                exit 1
            }
        } else {
            Write-Error "L'installation de RustDesk a échoué."
            exit 1
        }
    } else {
        Write-Error "Le téléchargement de $($asset.name) a échoué."
        exit 1
    }
}