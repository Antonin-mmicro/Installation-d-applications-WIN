$path = "$env:USERPROFILE\Downloads"
$url64 = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2200120169/AcroRdrDCx642200120169_MUI.exe"
$url32 = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2200120169/AcroRdrDC2200120169_MUI.exe"

if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    Write-Output "Système 64 bits"
} elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
    Write-Output "Système 32 bits"
} else {
    Write-Output "Architecture inconnue : $env:PROCESSOR_ARCHITECTURE"
}