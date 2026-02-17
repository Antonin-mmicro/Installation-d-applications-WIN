$biosManufacturer = (Get-CimInstance -ClassName Win32_BIOS).Manufacturer

if ($biosManufacturer -like "*Dell Inc*") {
    Write-Host "Le fabricant du BIOS est Dell Inc. Exécution du script d'installation de SupportAssist."
} else {
    Write-Warning "Le fabricant du BIOS n'est pas Dell Inc. Le script d'installation de SupportAssist ne sera pas exécuté."
}