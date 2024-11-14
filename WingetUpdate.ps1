# Import the necessary module
Install-Module Microsoft.Winget.Client
Import-Module Microsoft.Winget.Client


# Check if winget is installed
$wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue

if (-not $wingetInstalled) {
    Write-Host "winget is not installed. Installing the latest version."
    # Install the latest winget
    Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Add-AppxPackage -Path ".\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
} else {
    # Get the currently installed version
    $currentVersion = winget --version | Select-String -Pattern "([0-9]+\.[0-9]+\.[0-9]+)" | ForEach-Object { $_.Matches.Groups[1].Value }

    # Check the latest version available online
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $latestVersion = $latestRelease.tag_name.TrimStart('v')

    if ($currentVersion -ne $latestVersion) {
        Write-Host "winget is not the latest version. Installing version $latestVersion."
        # Update winget
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Add-AppxPackage -Path ".\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    } else {
        Write-Host "winget is already the latest version ($currentVersion)."
    }
}


Add-Type -AssemblyName PresentationFramework

# Get the list of installed applications
Get-WinGetPackage -OutVariable apps
$apps = $apps | Select-Object -Property Name, Id, InstalledVersion

# Create the WPF window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Uninstall Applications" Height="600" Width="800">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBox x:Name="SearchBox" Width="300" Height="25" Margin="0,0,0,10" />
        <ListView x:Name="AppListView" Grid.Row="1">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="" Width="30">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate>
                                <CheckBox IsChecked="{Binding Path=IsSelected, Mode=TwoWay}"/>
                            </DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Name" DisplayMemberBinding="{Binding Package}" Width="250"/>
                    <GridViewColumn Header="Id" DisplayMemberBinding="{Binding Id}" Width="250"/>
                    <GridViewColumn Header="Version" DisplayMemberBinding="{Binding Version}" Width="100"/>
                    <GridViewColumn Header="Status" DisplayMemberBinding="{Binding Status}" Width="150"/>
                </GridView>
            </ListView.View>
        </ListView>
        <Button x:Name="UninstallButton" Content="Uninstall Selected" Grid.Row="2" Width="150" Height="30" HorizontalAlignment="Right" Margin="0,10,0,0"/>
    </Grid>
</Window>
"@

# Load the XAML and create the window
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$SearchBox = $window.FindName("SearchBox")
$AppListView = $window.FindName("AppListView")
$UninstallButton = $window.FindName("UninstallButton")

# Prepare the data
$appData = @()
foreach ($app in $apps) {
    $appData += [PSCustomObject]@{
        IsSelected = $false
        Package    = $app.Name
        Id         = $app.Id
        Version    = $app.Installedversion
        Status     = ""
    }
}

# Set the initial ItemsSource
$AppListView.ItemsSource = $appData

# Add filtering functionality
$SearchBox.Add_TextChanged({
    $filter = $SearchBox.Text
    if ([string]::IsNullOrWhiteSpace($filter)) {
        $AppListView.ItemsSource = $appData
    } else {
        $filteredData = $appData | Where-Object {
            $_.Package -like "*$filter*" -or
            $_.Id -like "*$filter*" -or
            $_.Version -like "*$filter*"
        }
        $AppListView.ItemsSource = $filteredData
    }
})

# Handle the Uninstall button click
$UninstallButton.Add_Click({
    foreach ($app in $appData) {
        if ($app.IsSelected -and $app.Status -ne "Uninstalled") {
            $app.Status = "Uninstalling..."
            $AppListView.Items.Refresh()
            try {
                # Use winget to uninstall the application silently and forcefully
                $wingetArgs = @("uninstall", "--id", "`"$($app.Id)`"", "--silent", "--force")
                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processInfo.FileName = "winget"
                $processInfo.Arguments = $wingetArgs -join " "
                $processInfo.RedirectStandardOutput = $true
                $processInfo.RedirectStandardError = $true
                $processInfo.UseShellExecute = $false
                $processInfo.CreateNoWindow = $true
                $process = [System.Diagnostics.Process]::Start($processInfo)
                $output = $process.StandardOutput.ReadToEnd()
                $errorOutput = $process.StandardError.ReadToEnd()
                $process.WaitForExit()
                if ($process.ExitCode -eq 0) {
                    $app.Status = "Uninstalled"
                } else {
                    $app.Status = "Error: ExitCode $($process.ExitCode)"
                }
            } catch {
                $app.Status = "Exception: $($_.Exception.Message)"
            }
            $AppListView.Items.Refresh()
        }
    }
})

# Show the window
$window.ShowDialog()