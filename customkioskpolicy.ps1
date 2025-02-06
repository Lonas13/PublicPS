# Ensure the script is run as Administrator
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an Administrator." -ErrorAction Stop
}

# Function to set power settings
function Set-PowerSettings {
    Write-Output "Configuring power settings..."

    # Set action for closing lid to "Do Nothing" (AC and DC mode)
    powercfg -setacvalueindex SCHEME_BALANCED SUB_BUTTONS LIDACTION 0
    powercfg -setdcvalueindex SCHEME_BALANCED SUB_BUTTONS LIDACTION 0

    # Disable USB selective suspend (AC and DC mode)
    powercfg -setacvalueindex SCHEME_BALANCED SUB_USB USBSELECTIVESETTING 0
    powercfg -setdcvalueindex SCHEME_BALANCED SUB_USB USBSELECTIVESETTING 0

    # Set performance power mode when plugged in
    powercfg -setacvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMAX 100

    # Apply settings
    powercfg -setactive SCHEME_BALANCED

    Write-Output "Power settings configured."
}

# Function to disable Windows Bing Search (registry modification)
function Disable-BingSearch {
    Write-Output "Disabling Windows Bing Search for all users..."

    # Define registry path and key
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    $regName = "DisableSearchBoxSuggestions"

    # Check if the registry path exists; if not, create it
    if (-Not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Output "Created registry path: $regPath"
    }

    # Set the DisableSearchBoxSuggestions registry key to 1
    Set-ItemProperty -Path $regPath -Name $regName -Value 1 -Type DWord
    Write-Output "Bing search suggestions disabled."
}

# Function to set the time zone
function Set-TimeZone {
    Write-Output "Setting time zone to MST..."

    # Set the time zone to Mountain Standard Time
    tzutil /s "Mountain Standard Time"

    Write-Output "Time zone set to MST."
}

# Execute the functions
Set-PowerSettings
Disable-BingSearch
Set-TimeZone

Write-Output "All requested settings have been configured successfully."
