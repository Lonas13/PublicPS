set-executionpolicy -executionpolicy remotesigned -force

<#
(New-Object System.Net.WebClient).DownloadFile("https://zinfandel.centrastage.net/csm/profile/downloadAgent/23b43566-f401-43c3-a09a-2135bfb66bf3", "$env:TEMP/AgentInstall.exe");start-process "$env:TEMP/AgentInstall.exe"
#>


# Ensure the script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    exit
}

Add-AppxPackage https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

winget source update

if ((Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer -match 'Dell') { winget install dell.commandupdate --accept-source-agreements --accept-package-agreements --silent}

# 1. Configure power settings to "do nothing" when the display is closed
Write-Output "Configuring power settings..."
& powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
& powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
& powercfg -SetActive SCHEME_CURRENT
Write-Output "Power settings configured to do nothing when the display is closed."

# 2. Disable USB power saving settings to prevent USB ports from being disabled
Write-Output "Disabling USB power-saving settings..."
Get-WmiObject -Namespace "root\cimv2\power" -Class Win32_PowerSettingDataIndex | Where-Object {
    $_.InstanceID -like "*GUID*"
} | ForEach-Object {
    & powercfg /SETACVALUEINDEX SCHEME_CURRENT $_.InstanceID 0
    & powercfg /SETDCVALUEINDEX SCHEME_CURRENT $_.InstanceID 0
}
& powercfg -SetActive SCHEME_CURRENT
Write-Output "USB power-saving settings disabled."

# 3. Configure "Performance" power mode when plugged in
Write-Output "Configuring performance mode when plugged in..."
& powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
& powercfg -SetActive SCHEME_CURRENT
Write-Output "Performance mode configured."

# 4. Disable Bing search in Windows Search for all users
Write-Output "Disabling Bing Search integration in Windows Search..."
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
$regSubKey = "Explorer"
$regValueName = "DisableSearchBoxSuggestions"
if (-not (Test-Path "$regPath\$regSubKey")) {
    New-Item -Path "$regPath" -Name $regSubKey -Force | Out-Null
}
Set-ItemProperty -Path "$regPath\$regSubKey" -Name $regValueName -Value 1 -Type DWord
Write-Output "Bing search integration disabled in Windows Search for all users."

# 5. Set system time zone to MST (Mountain Standard Time)
Write-Output "Configuring system time zone to MST..."
tzutil /s "Mountain Standard Time"
Write-Output "System time zone set to MST."

winget install microsoft.office --accept-source-agreements --accept-package-agreements

# 6. disable new outlook
function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Type = "DWORD",
        [string]$Value
    )
    New-Item -Path $Path -Force | Out-Null
    New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}

    # Step 7: Block the New Outlook Toggle
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -Value 0


# Step 8: Restart explorer.exe to apply all changes
get-process explorer | foreach-object {stop-process $_}

Write-Output "All configurations applied successfully!"



# Step 9: Check if Dell Command Update is installed and run


# Define the path to the Dell Command Update executable
$dcuPath = "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"

if (Test-Path $dcuPath) {
    Write-Output "Dell Command Update found. Running updates..."
    
    # Run Dell Command Update to apply updates and allow reboot if necessary
    Start-Process -FilePath $dcuPath -ArgumentList "/applyUpdates -autoSuspendBitLocker=enable -reboot=enable" -Wait
    Write-Output "Updates applied. System may reboot if necessary."
} else {
    Write-Output "Dell Command Update not found. Please install it first."
}# Define the path to the Dell Command Update executable
$dcuPath = "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
