$installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* ,
                               HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* `
                               -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -like "*SupportAssist*" }

if ($installed) {
    Write-Output "SupportAssist est installé."
    exit 0
}
else {
    Write-Output "SupportAssist n'est pas installé."
    exit 1
}