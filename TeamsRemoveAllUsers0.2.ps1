# Configuration: Enable or disable logging
$enableLogging = $false
$logFile = "C:\Temp\TeamsUninstallLog.txt"

# Define a timeout value (in seconds) for uninstallation
$uninstallTimeout = 60

# Function to write both to the console and optionally to the log file
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Output $logEntry   # Write to console
    if ($enableLogging) {
        Add-Content -Path $logFile -Value $logEntry   # Write to log file
    }
}

# Start of the script
Write-Log "Starting Teams uninstall script..."

# Define Teams directories for cleanup
$teamsFolders = @(
    "AppData\Local\Microsoft\Teams",
    "AppData\Roaming\Microsoft\Teams"
)

# Loop through all user profiles under C:\Users
Get-ChildItem -Directory -Path "C:\Users" | ForEach-Object {
    # Enhanced detection logic: Check for Update.exe or Teams.exe
    $updateExePath = Join-Path -Path $_.FullName -ChildPath "AppData\Local\Microsoft\Teams\Update.exe"
    $teamsExePath = Join-Path -Path $_.FullName -ChildPath "AppData\Local\Microsoft\Teams\current\Teams.exe"

    Write-Log "Checking user profile: $($_.FullName)" "DEBUG"

    # Detect Teams via either Update.exe or Teams.exe
    if ((Test-Path -Path $updateExePath) -or (Test-Path -Path $teamsExePath)) {
        Write-Log "Found Microsoft Teams installation for user: $($_.FullName)." "INFO"

        # Kill Teams process and related processes
        try {
            kill -Name teams, squirrel -Force -ErrorAction SilentlyContinue
            Write-Log "Successfully killed Teams-related processes." "DEBUG"
        } catch {
            Write-Log "Failed to kill running processes: $($_.Exception.Message)" "ERROR"
        }

        # Attempt uninstallation
        if (Test-Path -Path $updateExePath) {
            try {
                Write-Log "Starting uninstall process for user: $($_.FullName) using: $updateExePath" "DEBUG"
                $process = Start-Process -FilePath $updateExePath `
                    -ArgumentList "--uninstall /s" `
                    -NoNewWindow -PassThru

                # Wait for the process with a timeout
                if ($process | Wait-Process -Timeout $uninstallTimeout) {
                    Write-Log "Successfully uninstalled Teams for user: $($_.FullName)." "INFO"
                } else {
                    Write-Log "Uninstall process timed out after $uninstallTimeout seconds for user: $($_.FullName)." "ERROR"
                    $process | Stop-Process -Force
                }
            } catch {
                Write-Log "Failed to uninstall Teams for user: $($_.FullName). Error: $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-Log "Update.exe not found for user: $($_.FullName). Attempting manual cleanup." "WARNING"
        }

        # Manual cleanup fallback
        foreach ($folder in $teamsFolders) {
            $fullPath = Join-Path -Path $_.FullName -ChildPath $folder
            if (Test-Path -Path $fullPath) {
                Write-Log "Deleting Teams folder: $fullPath" "DEBUG"
                try {
                    Remove-Item -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log "Successfully deleted Teams folder." "DEBUG"
                } catch {
                    Write-Log "Failed to delete Teams folder: $fullPath. Error: $($_.Exception.Message)" "WARNING"
                }
            }
        }
    } else {
        Write-Log "Microsoft Teams not found for user: $($_.FullName). Skipping user profile." "INFO"
    }
}

# Cleanup residual registry keys (run once, globally)
Write-Log "Cleaning up residual registry keys..." "DEBUG"
$teamsRegistryPaths = @(
    "HKCU:\Software\Microsoft\Teams",
    "HKLM:\Software\Microsoft\Teams",
    "HKCU:\Software\SquirrelTemp"
)
foreach ($path in $teamsRegistryPaths) {
    if (Test-Path -Path $path) {
        Write-Log "Deleting registry key: $path" "DEBUG"
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Successfully deleted registry key: $path" "DEBUG"
        } catch {
            Write-Log "Failed to delete registry key: $path. Error: $($_.Exception.Message)" "WARNING"
        }
    } else {
        Write-Log "Registry key not found: $path. Skipping." "DEBUG"
    }
}

Write-Log "Teams uninstall script completed."