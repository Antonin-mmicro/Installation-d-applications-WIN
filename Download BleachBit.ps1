$url = "https://download.bleachbit.org/BleachBit-5.0.2-setup.exe"

$path = "$env:TEMP\BleachBitSetup.exe"
$finalpath = "C:\Program Files (x86)\BleachBit\bleachbit.exe"

#Verification des drpots d'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}

if (Test-Path $finalpath) {
    Write-Host "Application déjà installé"
    Write-Host "Script terminé"
    exit 0
} 

if (Test-Path $path) {
    Write-Host "Setup détecté, lancement..."
    Push-Location $env:TEMP
    .\BleachBitSetup.exe /S /allusers /NoDesktopShortCut
    Start-Sleep -Seconds 30
    if (Test-Path $finalpath) {
        Write-Host "Application installé"
        if (Test-Path $path) {
            Write-Host "Suppression du setup..."
            Remove-Item $path -Force
            if (-not (Test-Path $path)) {
                Write-Host "Setup supprimé"
            } else { 
                Write-Host "Impossible de supprimer le setup"
            }
        }
        Pop-Location
        Write-Host "Script terminé"        
    } else {
        Write-Host "Installation échouée"
        Pop-Location 
        Write-Host "Script terminé" 
    }
    
} else {
    Write-Host "Setup non détecté, lancement du download..."
    Invoke-WebRequest -Uri $url -OutFile $path
    Write-Host "Setup téléchargé, lancement du setup..."
    Set-Location $env:TEMP
    .\BleachBitSetup.exe /S /allusers /NoDesktopShortCut
    Start-Sleep -Seconds 30
    if (Test-Path $finalpath) {
        Write-Host "Application installé"
        Pop-Location
        Write-Host "Script terminé"  
    }
}