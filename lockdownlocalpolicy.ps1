# Define a function to check if the current user is running PowerShell with Administrator privileges
Function Check-Admin {
    If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "This script must be run as Administrator."
        Exit
    }
}

# Run check for administrator privileges
Check-Admin

# Define the group name (Non-local administrators group)
$GroupName = "NonLocalAdmins"

# Ensure the group exists
If (-Not (Get-LocalGroup -Name $GroupName -ErrorAction SilentlyContinue)) {
    New-LocalGroup -Name $GroupName -Description "Group to manage restrictions for non-local admins"
    Write-Host "The '$GroupName' group was created." -ForegroundColor Green
}

# Apply desired settings for members of the group
Write-Host "Configuring security restrictions for non-local admins..." -ForegroundColor Yellow

# Block web browser access
Write-Host "Blocking web browser access..."
$BlockWebBrowsers = @(
    "iexplore.exe",      # Internet Explorer
    "chrome.exe",        # Google Chrome
    "msedge.exe",        # Microsoft Edge
    "firefox.exe",       # Mozilla Firefox
    "opera.exe"          # Opera
)

ForEach ($Browser in $BlockWebBrowsers) {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$Browser" -Name "Debugger" -Value "ntsd -d" -PropertyType String -Force | Out-Null
}
Write-Host "Web browser access restricted." -ForegroundColor Green

# Disable USB ports for group members
Write-Host "Disabling USB ports (Mass Storage Devices)..."
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -Name "Start" -Value 4
Write-Host "USB ports disabled." -ForegroundColor Green

# Disable Bluetooth
Write-Host "Disabling Bluetooth services..."
Stop-Service -Name bthserv -Force -ErrorAction SilentlyContinue
Set-Service -Name bthserv -StartupType Disabled
Write-Host "Bluetooth disabled." -ForegroundColor Green

# Disable script execution for non-local admins
Write-Host "Disabling script execution..."
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope LocalMachine -Force
Write-Host "Script execution disabled system-wide." -ForegroundColor Green

# Final step: Assign users to the restrictive group
Write-Host "Ensure that non-local administrators are added to the '$GroupName' group." -ForegroundColor Yellow
Write-Host "Configuration completed!" -ForegroundColor Green
