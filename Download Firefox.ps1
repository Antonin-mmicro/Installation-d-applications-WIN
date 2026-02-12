
$varDebug=$false #set this to 'true' to add additional information to stdout
$script:varCounter=0
$script:arrFirefox=@{}
$varCurrentUser=(New-Object -ComObject Microsoft.DiskQuota).TranslateLogonNameToSID((gwmi win32_computerSystem).userName)

#software management
if ($env:usrAction.length -lt 2 -or !$env:usrAction) {
    $env:usrAction="Install"
}

#debug..............................................................................................................................
function writeDebug ($message) {
    if ($varDebug) {
        write-host "DBG: $message"
    }
}

#create a set of firefox installation parameters of best fit for this specific system...............................................
function createRecord {
    $script:arrFirefox[$script:arrFirefox.count++]=@{
                 '#'=$script:arrFirefox.count++
            Language=$varNativeLang
                Arch=$varNativeArch
              Chosen=$true
        '---       '=$null
    }
}

#file analysis......................................................................................................................
function getPEArch ($path) {    #getPEArch build 7 :: https://superuser.com/a/1907045/298179
    writeDebug "gPEA 7 start"
    writeDebug "Path is [$path]"
    if (!([System.IO.Path]::IsPathRooted("$path"))) {
        $path="$pwd\$path"
        writeDebug "Path changed to [$path]"
    }

    $ltoh16 = if ([BitConverter]::IsLittleEndian) { 0..1 } else { 1..0 }
    $ltoh32 = if ([BitConverter]::IsLittleEndian) { 0..3 } else { 3..0 }

    $rd = [IO.FileStream]::new($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read)
    $buf = [byte[]]::new(4)
    $null = $rd.Read($buf, 0, 4)

    if ([BitConverter]::ToUInt16($buf[$ltoh16], 0) -eq 0x5a4d) {
        $null = $rd.Seek(0x3C, [IO.SeekOrigin]::Begin)
        $null = $rd.Read($buf, 0, 4)
        $pe_offset = [BitConverter]::ToUInt32($buf[$ltoh32], 0)
        # refill buffer from the new location, then fall through
        $null = $rd.Seek($pe_offset, [IO.SeekOrigin]::Begin)
        $null = $rd.Read($buf, 0, 4)
    }

    if ([BitConverter]::ToUInt32($buf[$ltoh32], 0) -eq 0x00004550) {
        $null = $rd.Read($buf, 0, 2)
        $platform_id = [BitConverter]::ToUInt16($buf[$ltoh16], 0)
        writeDebug "PEID is [$platform_id]"
        
        switch ([int] $platform_id) {
            0x014c {
                return "x86"
            } 0x8664 {
                return "x64"
            } 0xaa64 {
                return "Arm64"
            } default {
                write-host "! ERROR: Unable to determine platform type ($_)."
                exit 1
            }
        }
    } else {
        write-host "! ERROR: Unable to identify PE platform signature."
        exit 1
    }
    $rd.Dispose()
}

function getFFinfo ($varSID, $varReg) { #because we can have multiple firefoxen, unlike chrome
    $varFirefox=[ordered]@{
        #metadata which require no additional logic to calculate
              '#'=$script:varCounter
          Version=((gp "registry::$varReg").displayVersion)
         Language=((gp "registry::$varReg").displayName).split(' ')[-1] -replace '\)'
         Location=((gp "registry::$varReg").displayIcon -split ',')[0]

        #these next two will be hidden from view
        Uninstall=((gp "registry::$varReg").uninstallString)
           Chosen=$false
    }

    $varFirefox.Arch=getPEArch $varFirefox.Location
    if ($varFirefox.Arch -ne $varNativeArch) {
        $varFirefox.Native=$false
    } else {
        $varFirefox.Native=$true
    }

    if ($varSID) {
        $varFirefox.User=(New-Object System.Security.Principal.SecurityIdentifier($varSID)).Translate([System.Security.Principal.NTAccount]).value
    } else {
        $varFirefox.User="[System]"
    }

    #channel
    switch -regex ((gp "registry::$varReg").displayName) {
        'ESR' {
            $varFirefox.Channel="ESR"
        } 'Beta' {
            $varFirefox.Channel="Beta"
        } 'Developer' {
            $varFirefox.Channel="Developer"
        } 'Nightly' {
            $varFirefox.Channel="Nightly"
        } default {
            $varFirefox.Channel="Stable"
        }
    }

    #breaker :: the last one will be omitted from `Display installation information`
    $varFirefox.'---       '=$null

    #commit
    writeDebug "Committed FF :: [CH $($varFirefox.channel)/US $($varFirefox.user)/AR $($varFirefox.arch)/NV $($varFirefox.native)/LC $($varFirefox.location)/LA $($varFirefox.language)/V $($varFirefox.version)/# $($varFirefox.'#')/UN $($varFirefox.uninstall)]"
    $script:arrFirefox[$script:varCounter]=$varFirefox
    $script:varCounter++
}

#uninstallation.....................................................................................................................
function uninstallFF ($varLevel, $varUninstCmd, $varLocation) {
    writeDebug "uFF :: $varLevel] [$varUninstCMD] [$varLocation]"
    #set flags
    $script:varUninstalled=$true

    switch ($varLevel) {
        'System' {
            #uninstall using helper.exe :: do not kill resident copies
            start-process $varUninstCmd -ArgumentList "/S" -wait
            start-sleep -seconds 5
            write-host ": Uninstalled System-level Firefox installation"    
        } default {
            #kill ff process since we want users to switch to system-level
            get-process -name firefox -ea 0 | ? {$_.Path -match [regex]::Escape($varLocation)} | % {
                write-host ": Killed user-level Firefox.exe @ $varLocation"
                stop-process -Id $_.Id -Force -ea 0
                start-sleep -Seconds 5
            }

            #uninstall via scheduled task
            write-host "- User-level Firefox installation for user [$varLevel] will be removed upon user's next logon"
            $varTask=New-ScheduledTask -Action $(New-ScheduledTaskAction -Execute $varUninstCmd -Argument "/S") -trigger $(New-ScheduledTaskTrigger -AtLogOn -user "$varLevel") -Description "Uninstallation of Firefox at user-level for user $varLevel."
            Register-ScheduledTask -TaskName "FirefoxUserUninst-$(($varLevel -split '\\')[1])[$script:varCounter]" -InputObject $varTask -User "$varLevel" -ea 0 | Out-Null
            $script:varCounter++
        }
    }
}

#file download & verification.......................................................................................................
if (([IntPtr]::size) -eq 4) {
    [xml]$varPlatXML= get-content "$env:ProgramFiles\CentraStage\CagService.exe.config" -ea 0
} else {
    [xml]$varPlatXML= get-content "${env:ProgramFiles(x86)}\CentraStage\CagService.exe.config" -ea 0
}
try {
    $script:varProxyLoc= ($varPlatXML.configuration.applicationSettings."CentraStage.Cag.Core.AppSettings".setting | ? {$_.Name -eq 'ProxyIp'}).value
    $script:varProxyPort=($varPlatXML.configuration.applicationSettings."CentraStage.Cag.Core.AppSettings".setting | ? {$_.Name -eq 'ProxyPort'}).value
    if ($($varPlatXML.configuration.applicationSettings."CentraStage.Cag.Core.AppSettings".setting | ? {$_.Name -eq 'ProxyType'}).value -gt 0) {
        if ($script:varProxyLoc -and $script:varProxyPort) {
            $useProxy=$true
        }
    }
} catch {
    $host.ui.WriteErrorLine("! NOTICE: Device appears to be configured to use a proxy server, but settings could not be read.")
}

function downloadFile { #downloadFile, build 32/seagull :: copyright datto, inc.

    param (
        [parameter(mandatory=$false)]$url,
        [parameter(mandatory=$false)]$whitelist,
        [parameter(mandatory=$false)]$filename,
        [parameter(mandatory=$false,ValueFromPipeline=$true)]$pipe
    )

    function setUserAgent {
        $script:WebClient = New-Object System.Net.WebClient
    	$script:webClient.UseDefaultCredentials = $true
        $script:webClient.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
        $script:webClient.Headers.Add([System.Net.HttpRequestHeader]::UserAgent, 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET CLR 1.0.3705;)');
    }

    if (!$url) {$url=$pipe}
    if (!$whitelist) {$whitelist="the required web addresses."}
	if (!$filename) {$filename=$url.split('/')[-1]}
	
    try { #enable TLS 1.2
		[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    } catch [system.exception] {
		write-host "! ERROR: Could not implement TLS 1.2 Support."
		write-host "  This can occur on Windows 7 devices lacking Service Pack 1."
		write-host "  Please install that before proceeding."
		exit 1
    }
	
	write-host "- Downloading: $url"

	if ($useProxy) {
        setUserAgent
        write-host ": Proxy location: $script:varProxyLoc`:$script:varProxyPort"
	    $script:WebClient.Proxy = New-Object System.Net.WebProxy("$script:varProxyLoc`:$script:varProxyPort",$true)
	    $script:WebClient.DownloadFile("$url","$filename")
		if (!(test-path $filename)) {$useProxy=$false}
    }

	if (!$useProxy) {
		setUserAgent #do it again so we can fallback if proxy fails
		$script:webClient.DownloadFile("$url","$filename")
	} 

    if (!(test-path $filename)) {
        write-host "! ERROR: File $filename could not be downloaded."
        write-host "  Please ensure you are whitelisting $whitelist."
        write-host "- Operations cannot continue; exiting."
        exit 1
    } else {
        write-host ": Downloaded:  $filename"
    }
}

function getShortlink { # getShortlink build 10 :: copyright datto, inc.
    Param([Parameter(Mandatory=$true,ValueFromPipeline=$true)]$shortLink)

    try { #enable TLS 1.2
		[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    } catch [system.exception] {
		write-host "! ERROR: Could not implement TLS 1.2 Support."
		write-host "  This can occur on Windows 7 devices lacking Service Pack 1."
		write-host "  Please install that before proceeding."
		exit 1
    }

    function setRequestData {
        $script:webRequest=[System.Net.HttpWebRequest]::Create("$shortlink")
        $script:webRequest.Method = "HEAD"
    }

    write-host ": Short link:  $shortLink"

    if ($useProxy) {
        setRequestData
        write-host ": Proxy location: $script:varProxyLoc`:$script:varProxyPort"
        $script:webRequest::DefaultWebProxy = [System.Net.WebProxy]::new("$script:varProxyLoc`:$script:varProxyPort",$true)
        $longLink=($script:webRequest.GetResponse()).ResponseURI.AbsoluteURI
        if (!$longLink) {$useProxy=$false}
    }

    if (!$useProxy) {
        setRequestData
        $longLink=($script:webRequest.GetResponse()).ResponseURI.AbsoluteURI
    }

    write-host ": Full link:   $longLink"
    $longLink
}

function verifyPackage ($file, $certificate, $thumbprint, $name, $url) { #verifyPackage build 4/seagull :: datto/kaseya
    if (!(test-path "$file")) {
        write-host "! ERROR: Downloaded file could not be found."
        write-host "  Please ensure firewall access to $url."
        exit 1
    }

    #construct chain
    $varChain=New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
    try {
        $varChain.Build((Get-AuthenticodeSignature -FilePath "$file").SignerCertificate) | out-null
    } catch [System.Management.Automation.MethodInvocationException] {
        write-host "! ERROR: $name installer did not contain a valid digital certificate."
        write-host "  This could suggest a change in the way $name is packaged; it could"
        write-host "  also suggest tampering in the connection chain."
        write-host "- Please ensure $url is whitelisted and try again."
        write-host "  If this issue persists across different devices, please file a support ticket."
        exit 1
    }

    #check digsig status
    if ((Get-AuthenticodeSignature "$file").status.value__ -ne 0) {
        write-host "! ERROR: $name installer contained a digital signature, but it was invalid."
        write-host "  This strongly suggests that the file has been tampered with."
        write-host "  Please re-attempt download. If the issue persists, contact Support."
        exit 1
    }

    #inspect certificate thumbprints
    $varIntermediate=($varChain.ChainElements | % {$_.Certificate} | ? {$_.Subject -match "$certificate"}).Thumbprint
    if ($varIntermediate -ne $thumbprint) {
        write-host "! ERROR: $file did not pass verification checks for its digital signature."
        write-host "  This could suggest that the certificate used to sign the $name installer"
        write-host "  has changed; it could also suggest tampering in the connection chain."
        write-host `r
        if ($varIntermediate) {
            write-host ": We received: $varIntermediate"
            write-host "  We expected: $thumbprint"
            write-host "  Please report this issue."
        } else {
            write-host "  The installer's certificate authority has changed."
        }
        write-host "- Installation cannot continue. Exiting."
        exit 1
    } else {
        write-host ": Digital Signature verification passed."
    }
}

#region Opener ---------------------------------------------------------------------------------------------------------------------

write-host "Mozilla Firefox (x86/x64/Arm64 :: EXE/MSI)"
write-host "=========================================="
write-host ": Installation Action:        $env:usrAction"

#region Compatibility --------------------------------------------------------------------------------------------------------------

if ([int](gwmi win32_operatingsystem).buildnumber -lt 10240) {
    write-host "! ERROR: Mozilla Firefox requires at least Windows 10/Server 2016 to function."
    write-host "  Whilst older ESR builds remain supported on older Windows builds, these are"
    write-host "  out-of-scope for this Component and must be installed manually."
    write-host "  More info: https://www.mozilla.org/en-GB/firefox/system-requirements/"
    exit 1
}

#region Native system attributes ---------------------------------------------------------------------------------------------------

#language...........................................................................................................................
switch ((gp HKLM:\system\controlset001\control\nls\language).InstallLanguage) {
    '01$'  {$varNativeLang='ar'}    #Arabic
    '04$'  {$varNativeLang='zh-TW'} #Chinese (Generic)
    '0404' {$varNativeLang='zh-TW'} #Chinese (Traditional)
    '0804' {$varNativeLang='zh-CN'} #Chinese (Simplified)
    '05$'  {$varNativeLang='cs'}    #Czech
    '06$'  {$varNativeLang='da'}    #Danish
    '07$'  {$varNativeLang='de'}    #German
    '08$'  {$varNativeLang='el'}    #Greek
    '09$'  {$varNativeLang='en-GB'} #English (Generic)
    '0409' {$varNativeLang='en-US'} #English (US)
    '0809' {$varNativeLang='en-GB'} #English (UK)
    '1009' {$varNativeLang='en-CA'} #English (CA)
    '11$'  {$varNativeLang='ja'}    #Japanese
    '12$'  {$varNativeLang='ko'}    #Korean
    '0A$'  {$varNativeLang='es-ES'} #Spanish (Generic)
    '040A' {$varNativeLang='es-ES'} #Spanish (Spain)
    '080A' {$varNativeLang='es-MX'} #Spanish (Mexico)
    '0B$'  {$varNativeLang='fi'}    #Finnish
    '0C$'  {$varNativeLang='fr'}    #French
    '0E$'  {$varNativeLang='hu'}    #Hungarian
    '0F$'  {$varNativeLang='is'}    #Icelandic
    '10$'  {$varNativeLang='it'}    #Italian
    '13$'  {$varNativeLang='nl'}    #Dutch
    '0414' {$varNativeLang='nb-NO'} #Norwegian (Bokmal)
    '0814' {$varNativeLang='nn-NO'} #Norwegian (Nynorsk)
    '15$'  {$varNativeLang='pl'}    #Polish
    '0416' {$varNativeLang='pt-BR'} #Portuguese (Brazil)
    '0816' {$varNativeLang='pt-PT'} #Portuguese (Portugal)
    '18$'  {$varNativeLang='ro'}    #Romanian
    '1A$'  {$varNativeLang='hr'}    #Croatian/Serbian/Bosnian
    '1D$'  {$varNativeLang='sv-SE'} #Swedish
    '1F$'  {$varNativeLang='tr'}    #Turkish
    '22$'  {$varNativeLang='uk'}    #Ukrainian
    default {
        write-host "- NOTICE: Unable to identify system OS language (Unhandled input '$_')."
        write-host "  Falling back to English (UK)."
        $varNativeLang='en-GB'
    }
}

#architecture.......................................................................................................................
if ((gwmi win32_processor).architecture -eq 12) {
    $varNativeArch='Arm64'
} else {
    if ([intptr]::Size -eq 4) {
        $varNativeArch='x86'
    } else {
        $varNativeArch='x64'
    }
}

#declare
write-host ": Native System Architecture: $varNativeArch"
write-host ": Native System Language:     $varNativeLang"

#region Load user hives ------------------------------------------------------------------------------------------------------------

$arrUserSID=@{}
$arrUserLoaded=@()

#enumerate users who are not logged in..............................................................................................
gci "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | % {Get-ItemProperty $_.PSPath} | ? {$_.PSChildName -match '^S-1-5-21-'} | % {
    $varObject=New-Object PSObject
    $varObject | Add-Member -MemberType NoteProperty -Name "Username" -Value "$(split-path $_.ProfileImagePath -Leaf)"
    $varObject | Add-Member -MemberType NoteProperty -Name "ImagePath" -Value "$($_.ProfileImagePath)"
    if (Test-Path "$($_.ProfileImagePath)\NTUser.dat" -ea 0) {
        $arrUserSID+=@{$($_.PSChildName)=$varObject}
    }
}

#load the registry hives of these users to an array containing their SIDs...........................................................
$arrUserSID.Keys | ? {$_ -notin $(gci "Registry::HKEY_USERS" | % {$_.name} | % {split-path $_ -leaf})} | % {
    cmd /c "reg load `"HKU\$($_)`" `"$($arrUserSID[$_].ImagePath)\NTUSER.DAT`"" 2>&1>$null
    $arrUserLoaded+=$_
}

#region Gather info on installed Firefox copies ------------------------------------------------------------------------------------

#system-level
"Software","Software\Wow6432Node" | % {
    gci "Registry::HKEY_LOCAL_MACHINE\$_\Microsoft\Windows\CurrentVersion\Uninstall" -ea 0 | ? {$("registry::$($_.name)" | split-path -leaf) -match '^Firefox$|^Mozilla\sFirefox'} | % {
        getFFinfo $null $_.name
    }
}

#user-level (absent/s)
$arrUserLoaded | % {
    $varUser=$_
    "Software","Software\WoW6432Node" | % {
        gci "Registry::HKEY_USERS\$varUser\$_\Microsoft\Windows\CurrentVersion\Uninstall" -ea 0 | ? {$("registry::$($_.name)" | split-path -leaf) -match '^Firefox$|^Mozilla\sFirefox'} | % {
            getFFinfo $varUser $_.name
        }
    }
}

#user-level (current)
"Software","Software\WoW6432Node" | % {
    gci "Registry::HKEY_USERS\$varCurrentUser\$_\Microsoft\Windows\CurrentVersion\Uninstall" -ea 0 | ? {$("registry::$($_.name)" | split-path -leaf) -match '^Firefox$|^Mozilla\sFirefox'} | % {
        getFFinfo $varCurrentUser $_.name
    }
}

#region Unload user hives ----------------------------------------------------------------------------------------------------------

$arrUserLoaded | % {
    [gc]::Collect()
    start-sleep -seconds 3
    cmd /c "reg unload `"HKU\$($_)`"" 2>&1>$null
}

#region Uninstall ------------------------------------------------------------------------------------------------------------------

if ($env:usrAction -eq 'Uninstall') {
    write-host `r
    write-host "- Uninstalling all (System-/User-level) copies of Firefox from this system."
    #system
    $script:arrFirefox.Values | ? {$_.user -eq '[System]'} | % {
        uninstallFF System $_.Uninstall $_.Location
    }
    #user
    $script:arrFirefox.Values | ? {$_.user -ne '[System]'} | % {
        uninstallFF $_.user $_.Uninstall $_.Location
    }
    exit
}

#region Display installation information -------------------------------------------------------------------------------------------

if (($script:arrFirefox.count | ? {$_}) -gt 0) {
    write-host ": Mozilla Firefox is already installed. Discovered copies are:"
    write-host `r
    $varTable=($script:arrFirefox.getEnumerator() | sort -property Name | % {$_.value} | % {($_ | ft -AutoSize -HideTableHeaders | out-string).trim()}).split([environment]::newline) | ? {$_}
    $varTable[0..($($varTable.count)-2)] | Select-String -NotMatch '^Uninstall','^Chosen' #all other methods of hiding these 'columns' from `ft` failed
    write-host `r
} else {
    write-host ": Mozilla Firefox is not installed at System- or User-level."
}

#region Process installation information -------------------------------------------------------------------------------------------

#logic: multiple system-level copies................................................................................................
if ((($script:arrFirefox.values | ? {$_.user -eq '[System]'}).language).count -gt 1) {
    if ((($script:arrFirefox.values | ? {$_.user -eq '[System]' -and $_.channel -eq 'Stable'}).language).count -gt 1) {
        #multiple stable system-level copies
        write-host "! ERROR: Multiple System-level copies of Firefox Stable are installed at once."
        write-host "  Please set the Component's usrAction variable to 'Uninstall' and remove"
        write-host "  all extraneous copies before proceeding."
        exit 1
    } else {
        #multiple system-level copies; favour the stable installation
        ($($script:arrFirefox.values | ? {$_.user -eq '[System]' -and $_.channel -match 'Stable'})).Chosen=$true
    }
}

#logic: zero/one system-level stable copies :: an 'if' will do because of the above logic's filtration..............................
if ($script:arrFirefox.values | ? {$_.user -eq '[System]' -and $_.channel -match 'Stable'}) {
    ($($script:arrFirefox.values | ? {$_.user -eq '[System]' -and $_.channel -match 'Stable'})).Chosen=$true
} else {
    createRecord
}

#logic: only ESR installed on system-level..........................................................................................
if ($script:arrFirefox.values | ? {$_.user -eq '[System]' -and $_.channel -match 'ESR'}) {
    if ($script:arrFirefox.values | ? {$_.user -eq '[System]' -and $_.channel -match 'Stable'}) {
	    write-host ": System-level copies of Firefox for Release and ESR branches were detected."
        write-host "  The ESR-branch copy will be removed."
    } else {
        if ($env:usrFirefoxESRSwitch -eq 'true') {
            write-host "- usrFirefoxESRSwitch set to TRUE via Site-/Global-level variable. Migrating."
            ($script:arrFirefox.Values | ? {$_.chosen}).Chosen=$false
            createRecord
        } else {
            write-host "! ERROR: The only installed System-level copy of Firefox is of the ESR branch."
            write-host "  Out of respect for user preference for this branch, the installation will not"
            write-host "  be migrated. This Component does not cater to the ESR branch, only to Release."
            write-host "  Set the Site-/Account-level variable 'usrFirefoxESRSwitch' to TRUE to permit"
            write-host "  this Component to promote sole ESR installations to Release-branch versions."
            exit 1
        }
    }
}

#region Upgrade-type installations -------------------------------------------------------------------------------------------------

if ($env:usrAction -eq 'Upgrade') {
    if (($script:arrFirefox.Values | ? {$_.chosen}).Arch -ne $varNativeArch) {
        write-host "- Upgrade installation: A native-arch version of Firefox Stable will be installed."
        write-host "  All other versions will be removed, but system-level configuration data will be retained where possible."
        ($script:arrFirefox.Values | ? {$_.chosen}).Chosen=$false
        createRecord
    } else {
        write-host "- Upgrade installation: A native-arch version of Firefox Stable is already installed."
        write-host "  It will be updated to the latest version."
    }
}

#region Download Firefox -----------------------------------------------------------------------------------------------------------

#make sure we have a chosen entry
if (!($script:arrFirefox.Values | ? {$_.chosen})) {
    write-host "! ERROR: No Firefox installation parameters have been nominated."
    write-host "  This is a script error. Please report this to the Support team."
    exit 1
}

#transmute 'chosen' parameters into mozilla URL parameters
$script:arrFirefox.Values | ? {$_.chosen} | % {
    switch ($_.Arch) {
        'x86' {$varFFArch='win'}
        'x64' {$varFFArch='win64'}
      'arm64' {$varFFArch='win64-aarch64'}
    }
    $varFFLang=$_.Language
}

#declare our choice
write-host `r
if (($script:arrFirefox.Values | ? {$_.chosen}).Location) {
    write-host "- Using parameters from installation #$(($script:arrFirefox.Values | ? {$_.chosen}).'#'): $varFFLang, $(($script:arrFirefox.Values | ? {$_.chosen}).Arch), Stable channel"
} else {
    write-host "- Using best-fit parameters for this system: $varFFLang, $varFFArch, Stable channel"
}

#do the do
"https://download.mozilla.org/?product=firefox-latest-ssl&os=$varFFArch&lang=$varFFLang" | getShortlink | downloadFile -filename 'fxLatest.exe' -whitelist "https://download.mozilla.org"
verifyPackage "fxLatest.exe" "DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1" "7B0F360B775F76C94A12CA48445AA2D2A875701C" "Mozilla Firefox" "https://download.mozilla.org"

write-host `r

#region Remove extraneous copies ---------------------------------------------------------------------------------------------------

$script:arrFirefox.Values | ? {!($_.chosen)} | ? {$_.Location} | ? {$_.user -eq '[System]'} | % {
    uninstallFF System $_.Uninstall $_.Location
}

$script:arrFirefox.Values | ? {!($_.chosen)} | ? {$_.Location} | ? {$_.user -ne '[System]'} | % {
    uninstallFF $_.user $_.Uninstall $_.Location
}

if (!$script:varUninstalled) {
    write-host ": No copies of Firefox needed to be uninstalled."
}

#region Install --------------------------------------------------------------------------------------------------------------------

write-host `r
write-host "- Installing Mozilla Firefox..."
$varInstaller=start-process fxLatest -ArgumentList "/S /PreventRebootRequired=true" -wait -NoNewWindow -PassThru
if ($varInstaller.ExitCode -ne 0) {
    write-host "! ERROR: Installer exited with non-zero exit code ($($varInstaller.ExitCode))."
    write-host "  Please check the StdErr stream."
    exit 1
}

write-host "- Actions completed @ $(get-date)."