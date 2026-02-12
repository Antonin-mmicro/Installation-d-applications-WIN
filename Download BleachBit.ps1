$url = "https://download.bleachbit.org/BleachBit-5.0.2-setup.exe"

$path = "$env:TEMP\BleachBitSetup.exe"
$finalpath = "C:\Program Files (x86)\BleachBit\bleachbit.exe"

if (Test-Path $finalpath) {
    Write-Host "Application déjà installé"
    Write-Host "Script terminé"
    exit 0
} else {
    continue
}
if (Test-Path $path) {
    Write-Host "Setup détecté, lancement..."
    Set-Location $env:TEMP
    .\BleachBitSetup.exe /S /allusers /NoDesktopShortCut
    Start-Sleep -Seconds 10
    if (Test-Path $finalpath) {
        Write-Host "Application installé"
        Write-Host "Script terminé"        
    }
} else {
    Write-Host "Setup non détecté, lancement du download..."
    Invoke-WebRequest -Uri $url -OutFile $path
    Write-Host "Setup téléchargé, lancement du setup..."
    Start-Sleep -Seconds 10
    Set-Location $env:TEMP
    .\BleachBitSetup.exe /S /allusers /NoDesktopShortCut
    if (Test-Path $finalpath) {
        Write-Host "Application installé"
        Write-Host "Script terminé"  
    }
}