[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
$assetName = "DesktopEditors_x64.msi"
$outputDir = "$env:TEMP"
$api = "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases"
$path = (Get-ChildItem -Path "C:\" -Recurse -Filter "DesktopEditors_x64.msi" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
$finalpath = "C:\Program Files\ONLYOFFICE\DesktopEditors\DesktopEditors.exe"
$outputFile = "$env:TEMP\DesktopEditors_x64.msi"

# $installer = New-Object -ComObject WindowsInstaller.Installer; $db = $installer.OpenDatabase("C:\Users\LabDattoWin11\Downloads\DesktopEditors_x64.msi", 0); $view = $db.OpenView("SELECT Value FROM Property WHERE Property='ProductVersion'"); $view.Execute(); $view.Fetch().StringData(1) -replace '\.\d+$'

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." 
    Write-Host "Script terminé" 
    exit 1 
}



#Derniere version
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest" -Headers @{
    "User-Agent" = "PowerShell"
}
$latestVersion = $release.tag_name.TrimStart("v")

$localSize = (Get-Item "$path").Length
$latestSize = ((Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest" -Headers @{"User-Agent"="PowerShell"}).assets | Where-Object { $_.name -eq "DesktopEditors_x64.msi" }).size

function DownloadSetup() {
    $release = Invoke-RestMethod "https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest" -Headers @{"User-Agent"="PowerShell"}
    $asset = $release.assets | Where-Object { $_.name -eq $assetName }
    $downloadUrl = $asset.browser_download_url
    Write-Host "Téléchargement de $assetName version $($release.tag_name)..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -Headers @{"User-Agent"="PowerShell"}
    $path = $outputFile
    Write-Host "Téléchargement terminé."
}

function InstallSetup {
    Start-Process msiexec.exe -ArgumentList "/i `"$path`" /qn /norestart" -PassThru | Wait-Process
}




if(Test-Path -Path $finalpath) {
    Write-Host "Application déjà installé, verification de la version..."
    $finalversion = (Get-Item 'C:\Program Files\ONLYOFFICE\DesktopEditors\DesktopEditors.exe').VersionInfo.ProductVersion -replace '\.\d+$'
    if($latestVersion -eq $finalversion) {
        Write-Host "Application déjà à jour, fermeture du script..."
        exit 0
    } else {
        Write-Host "Application non à jour, verification du setup..."
    }
}





if(Test-Path -Path $path) {
    Write-Host "Setup déja installé, verification de la version..."
    $installer = New-Object -ComObject WindowsInstaller.Installer; $db = $installer.OpenDatabase("$path", 0); $view = $db.OpenView("SELECT Value FROM Property WHERE Property='ProductVersion'"); $view.Execute(); $version = $view.Fetch().StringData(1) -replace '\.\d+$'
    if ($latestVersion -eq $version) {
        if ($latestSize -eq $localSize){
            Write-Host "✅| local : $version | online : $latestVersion |"
            Write-Host "Installation de l'application..."
            InstallSetup
        } else {
            Write-Host "Le fichier est corrompu; suppression et installation du nouveau..."
            Remove-Item $path
            DownloadSetup
        }
    } else {
        Write-Host "❌| local : $version | online : $latestVersion |"
        Start-Sleep(1)
        Write-Host "Le setup n'est pas à jour, suppression et téléchargement du nouveau..."
        Remove-Item $path
        DownloadSetup
    }
    exit 0
}

