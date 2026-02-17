$installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* ,
                               HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* `
                               -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -eq "Dell SupportAssist" }

if ($installed) {
    Write-Output "Dell SupportAssist est installé."
    exit 0
}
else {
    Write-Output "Dell SupportAssist n'est pas installé."
    exit 1
}