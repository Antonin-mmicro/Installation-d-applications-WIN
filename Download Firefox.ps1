$path = "$env:TEMP\Firefox_x64.exe"
$finalpath = "C:\Program Files\Mozilla Firefox"
$url = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=fr"
$latest = (Invoke-RestMethod "https://product-details.mozilla.org/1.0/firefox_versions.json").LATEST_FIREFOX_VERSION

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}

if (Test-Path -Path $finalpath) {
    $actual = (Get-Item "C:\Program Files\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
    if ($actual -eq $latest) {
        Write-Host "Mozilla Firefox est déjà installé et à jour."
        exit 0
    } else {
        Write-Host "Mozilla Firefox est installé mais pas à jour. Version actuelle : $actual, version la plus récente : $latest."
        Write-Host "Mise à jour de Mozilla Firefox..."
        #pass
    }
}

if (Test-Path -Path $path) {
    $acualsetup = (Get-Item $path).VersionInfo.ProductVersion
    if ($acualsetup -eq $latest) {
        Write-Host "Le fichier d'installation de Mozilla Firefox est déjà téléchargé et à jour."
        Write-Host "Installation de Mozilla Firefox..."
        Start-Process -FilePath $path -ArgumentList "/silent" -Wait
        Start-Sleep -Seconds 5
        if (Test-Path -Path $finalpath) {
            Write-Host "Installation de Mozilla Firefox terminée avec succès."
            Write-Host "Suppression du fichier d'installation..."
            Remove-Item -Path $path -Force
            Start-Sleep -Seconds 2
            if (-not (Test-Path -Path $path)) {
                Write-Host "Fichier d'installation supprimé avec succès."
                exit 0
            } else {
                Write-Warning "Impossible de supprimer le fichier d'installation. Veuillez le supprimer manuellement."
                exit 1
            }
        } else {
            Write-Error "L'installation de Mozilla Firefox a échoué."
            exit 1
        }
    } else {
        Write-Host "Le fichier d'installation de Mozilla Firefox est déjà téléchargé mais pas à jour. Version actuelle : $acualsetup, version la plus récente : $latest."
        Write-Host "Téléchargement de la dernière version de Mozilla Firefox..."
        Remove-Item -Path $path -Force
        Invoke-WebRequest -Uri $url -OutFile $path
        Start-Sleep -Seconds 5
    }
} else {
    Write-Host "Téléchargement de Mozilla Firefox..."
    Invoke-WebRequest -Uri $url -OutFile $path
    Start-Sleep -Seconds 5
    if (Test-Path -Path $path) {
        Write-Host "Téléchargement de Mozilla Firefox terminé avec succès."
        Write-Host "Installation de Mozilla Firefox..."
        Start-Process -FilePath $path -ArgumentList "/silent" -Wait
        Start-Sleep -Seconds 5
        if (Test-Path -Path $finalpath) {
            Write-Host "Installation de Mozilla Firefox terminée avec succès."
            Write-Host "Suppression du fichier d'installation..."
            Remove-Item -Path $path -Force
            Start-Sleep -Seconds 2
            if (-not (Test-Path -Path $path)) {
                Write-Host "Fichier d'installation supprimé avec succès."
                exit 0
            } else {
                Write-Warning "Impossible de supprimer le fichier d'installation. Veuillez le supprimer manuellement."
                exit 1
            }
        } else {
            Write-Error "L'installation de Mozilla Firefox a échoué."
            exit 1
        }
    } else {
        Write-Error "Le téléchargement de Mozilla Firefox a échoué."
        exit 1
    }
}