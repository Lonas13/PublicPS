Some cool stuff

https://learn.microsoft.com/en-us/microsoftteams/teams-client-uninstall-script

# Additional policy to disable the lock screen entirely
Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "NoLockScreen" -Type Dword -Value 1
