$path = "$env:TEMP"
$finalpath = "C:\Program Files\Mozilla Firefox"
$url = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=fr"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}

if (Test-Path -Path $finalpath) {
    Write-Output "Mozilla Firefox est déjà installé."
    exit 0
}

if (Test-Path -Path $path)

