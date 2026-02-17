$msiPath = "C:\Users\LabDattoWin11\Downloads\DesktopEditors_x64.msi"

# Crée l’objet Windows Installer
$installer = New-Object -ComObject WindowsInstaller.Installer

# Ouvre la base MSI en lecture seule (0)
$database = $installer.GetType().InvokeMember(
    "OpenDatabase",
    "InvokeMethod",
    $null,
    $installer,
    @($msiPath, 0)
)

# Prépare la requête SQL pour récupérer ProductVersion
$view = $database.GetType().InvokeMember(
    "OpenView",
    "InvokeMethod",
    $null,
    $database,
    @("SELECT Value FROM Property WHERE Property='ProductVersion'")
)

# Exécute la requête
$view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)

# Récupère le résultat
$record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
$version = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)

$version
