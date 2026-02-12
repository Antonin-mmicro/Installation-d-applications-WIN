$url = "https://download.bleachbit.org/BleachBit-5.0.2-setup.exe"

$path = "$env:TEMP\BleachBitSetup.exe"
$finalpath = "C:\Program Files (x86)\BleachBit\bleachbit.exe"

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
    Write-Host "Setup déja présent, suppression du l'ancien setup..."
    Remove-Item $path
    Start-Sleep -Seconds 5
    if (Test-Path $path) {
        Write-Host "Impossbible de supprimer le setup, veuillez le faire à la main à $path"
    } else {
        Write-Host "Téléchargement du setup..."
        Invoke-WebRequest $url -OutFile $path
        Start-Sleep -Seconds 5
        if (Test-Path $path) {
            Write-Host "Setup télécharger avec succès !"
            Write-Host "Lancemenet de l'installation"
            Push-Location $env:TEMP
            .\BleachBitSetup.exe /S /allusers /NoDesktopShortCut
            Pop-Location
        }
    }
}
