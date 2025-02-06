# Ensure the script is running with administrative privileges
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    Exit
}

# Function to output status messages
function Write-Status ($Message) {
    Write-Host "[*] $Message" -ForegroundColor Green
}

# No screen timeout
Write-Status "Disabling screen timeout..."
New-Item -Path "HKCU:\Control Panel\PowerCfg\PowerPolicies" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Control Panel\PowerCfg\UserPowerPolicy" -Name "Policies" -Value "00000000" | Out-Null

# No password expiration
Write-Status "Disabling password expiration..."
wmic UserAccount where "Name='%username%'" set PasswordExpires=FALSE

# No lock screen
Write-Status "Disabling lock screen..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value 1 -Type DWord -Force

# Power settings: Closing the lid does nothing
Write-Status "Setting power options to 'lid close action = do nothing'..."
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0

# Disable USB power savings
Write-Status "Disabling USB selective suspend..."
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_USB SETTINGS 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_USB SETTINGS 0

# Set performance mode when plugged in
Write-Status "Setting high-performance mode when plugged in..."
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_PROCESSOR PROCOOLING 0
powercfg -SETACTIVE SCHEME_MIN

# Disable Windows Bing search for all users
Write-Status "Disabling Windows Bing search and box suggestions..."
$ExplorerPoliciesPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $ExplorerPoliciesPath)) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Explorer" -Force | Out-Null
}
Set-ItemProperty -Path $ExplorerPoliciesPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force

# Set time zone to MST (Mountain Standard Time)
Write-Status "Setting time zone to MST..."
tzutil /s "Mountain Standard Time"

Write-Status "All configuration complete. Some changes may require a reboot to take effect."
