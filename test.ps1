$windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
$windowsInstaller.GetType().InvokeMember("OpenDatabase","InvokeMethod",$null,$windowsInstaller,@("C:\Users\LabDattoWin11\Downloads\DesktopEditors_x64.msi",0)) `
  .OpenView("SELECT Value FROM Property WHERE Property='ProductVersion'") `
  .Execute() | ForEach-Object { $_.Fetch().StringData(1) }
