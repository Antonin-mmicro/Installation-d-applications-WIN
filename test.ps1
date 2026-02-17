$msi = "C:\Users\LabDattoWin11\Downloads\DesktopEditors_x64.msi"
(Get-WmiObject -Class Win32_Product -Filter "Name='Desktop Editors'" | Select-Object -ExpandProperty Version)