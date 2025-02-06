# Ensure the script is running with administrative privileges
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    Exit
}

# Function to output status messages
function Write-Status ($Message) {
    Write-Host "[*] $Message" -ForegroundColor Green
}

# Function to get registry hives for all non-admin users
function Get-NonAdminUserSIDs {
    # Get all local user profile registry keys
    $ProfileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $UserSIDs = Get-ChildItem -Path $ProfileListPath | Where-Object {
        # Skip system accounts (exclude SIDs for SYSTEM, LOCAL SERVICE, NETWORK SERVICE)
        $_.PSChildName -notmatch '^S-1-5-(18|19|20)$'
    } | ForEach-Object {
        $_.PSChildName
    }

    # Filter only non-admin accounts
    $NonAdminSIDs = @()
    foreach ($SID in $UserSIDs) {
        # Check if the account is part of the Administrators group
        $IsAdmin = (New-Object Security.Principal.SecurityIdentifier($SID)).Translate([Security.Principal.NTAccount]).Value | `
            ForEach-Object { Get-LocalGroupMember -Group 'Administrators' | Select-Object -ExpandProperty Name | Where-Object { $_ -eq $_ } }
        
        if (-NOT $IsAdmin) {
            $NonAdminSIDs += $SID
        }
    }

    return $NonAdminSIDs
}

# Gather non-admin user SIDs
$NonAdminSIDs = Get-NonAdminUserSIDs
if (-Not $NonAdminSIDs) {
    Write-Error "No non-administrator user profiles found!"
    Exit
}

Write-Status "Found non-administrator user profiles: $($NonAdminSIDs -join ', ')"

# Apply settings for each non-admin user
foreach ($SID in $NonAdminSIDs) {
    $UserHive = "HKU:\$SID"

    # No screen timeout (via power policies)
    Write-Status "Configuring screen timeout for user SID: $SID..."
    New-Item -Path "$UserHive\Control Panel\PowerCfg" -Force | Out-Null
    New-ItemProperty -Path "$UserHive\Control Panel\PowerCfg\UserPowerPolicy" -Name "Policies" -Value "00000000" -Force | Out-Null

    # No lock screen
    Write-Status "Disabling lock screen for user SID: $SID..."
    New-ItemProperty -Path "$UserHive\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value 1 -PropertyType DWord -Force | Out-Null
}

# -- GLOBAL SETTINGS THAT APPLY SYSTEM-WIDE --

# No password expiration (global setting, applies to all users)
Write-Status "Disabling password expiration globally..."
wmic UserAccount where "Name='%username%'" set PasswordExpires=FALSE

# Power settings: Closing the lid does nothing
Write-Status "Setting power options globally: closing the lid does nothing..."
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0

# Disable USB power savings
Write-Status "Disabling USB selective suspend globally..."
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_USB SETTINGS 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_USB SETTINGS 0

# Set performance mode when plugged in
Write-Status "Setting high-performance mode when plugged in globally..."
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_PROCESSOR PROCOOLING 0
powercfg -SETACTIVE SCHEME_MIN

# Disable Windows Bing search for all users
Write-Status "Disabling Windows Bing search globally..."
$ExplorerPoliciesPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $ExplorerPoliciesPath)) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Explorer" -Force | Out-Null
}
Set-ItemProperty -Path $ExplorerPoliciesPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force

# Set time zone to MST (Mountain Standard Time)
Write-Status "Setting time zone to MST..."
tzutil /s "Mountain Standard Time"

Write-Status "All configuration complete. Some changes may require a reboot to take effect."
