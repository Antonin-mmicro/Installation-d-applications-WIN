$url = "https://downloads.dell.com/serviceability/catalog/SupportAssistinstaller.exe"
$savePath = "$env:TEMP\SupportAssistinstaller.exe"

function Install-SupportAssist {
    Write-Host "Installation de SupportAssist ..."
    Invoke-WebRequest -Uri $url -OutFile $savePath
    Start-Process -FilePath "$savePath" -ArgumentList "/silent" -Wait
    if (Test-Path -Path "C:\Program Files\Dell\SupportAssist") {
        Write-Output "Installation de SupportAssist terminée avec succès."
        Write-Host "Suppression du fichier d'installation SupportAssistinstaller.exe ..."
        Remove-Item -Path $savePath -Force
        if (-not (Test-Path -Path $savePath)) {
            Write-Output "Fichier d'installation SupportAssistinstaller.exe supprimé avec succès."
            exit 0
        } else {
            Write-Warning "Impossible de supprimer le fichier d'installation SupportAssistinstaller.exe. Veuillez le supprimer manuellement."
            exit 1
        }
    } else {
        Write-Error "L'installation de SupportAssist a échoué."
        exit 1
    }
}

if (Test-Path -Path "C:\Program Files\Dell\SupportAssist") {
    Write-Output "SupportAssist est déjà installé."
    exit 0
} else {
    Install-SupportAssist
}