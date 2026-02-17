$biosManufacturer = (Get-CimInstance -ClassName Win32_BIOS).Manufacturer

Write-Output $biosManufacturer