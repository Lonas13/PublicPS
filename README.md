Some cool stuff

https://learn.microsoft.com/en-us/microsoftteams/teams-client-uninstall-script

# Additional policy to disable the lock screen entirely
Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "NoLockScreen" -Type Dword -Value 1


#####
Install winget: 

Add-AppxPackage https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

###
powershell -Command "Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile 'C:\temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'"

Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile 'C:\temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
