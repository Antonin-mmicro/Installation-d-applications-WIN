$msiPath = "$env:USERPROFILE\Downloads\DesktopEditors_x64.msi"
$installer = New-Object -ComObject WindowsInstaller.Installer
$database = $installer.GetType().InvokeMember(
    "OpenDatabase",
    "InvokeMethod",
    $null,
    $installer,
    @($msiPath, 0)
)
$view = $database.GetType().InvokeMember(
    "OpenView",
    "InvokeMethod",
    $null,
    $database,
    @("SELECT Value FROM Property WHERE Property='ProductVersion'")
)
$view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)
$record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
$version = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)
$version