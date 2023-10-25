net accounts /minpwlen:10
net accounts /minpwage:10
net accounts /maxpwage:90
net accounts /lockoutduration:30
net accounts /lockoutthreshold:10
net accounts /uniquepw:24
net accounts /passwordmustmeetcomplexityrequirements:Enabled
net accounts /enforcepasswordhistory:5

stop-service remoteregistry
stop-service SSDPSRV
stop-service TermService
stop-service UmRdpService
stop-service upnphost
stop-service FTPSVC

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

Set-Service -Name remoteregistry -Status stopped -StartupType disabled
Set-Service -Name SSDPSRV -Status stopped -StartupType disabled
Set-Service -Name TermService -Status stopped -StartupType disabled
Set-Service -Name UmRdpService -Status stopped -StartupType disabled
Set-Service -Name upnhost -Status stopped -StartupType disabled
Set-Service -Name FTPSVC -Status stopped -StartupType disabled

Auditpol /get /category:*
Auditpol /set /category:"Detailed Tracking" /success:enable /failure:enable
Auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
Auditpol /set /category:"Policy Change" /success:enable /failure:enable
Auditpol /set /category:"Account Logon" /success:enable /failure:enable
Auditpol /set /category:"Account Management" /success:enable /failure:enable
Auditpol /set /category:"DS Access" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"System" /success:enable /failure:enable

Set-ExecutionPolicy RemoteSigned





Start-MpScan -ScanType QuickScan

reg add "HKLM\SYSTEM\CurrentControlSet\Conrtol\Terminal server" /v fDenyTSConnections /t REG_DWORD /d 1 /f
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DisableCAD" /t REG_DWORD /d 0 /f

# Set SmartScreen to Block
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 2 -PropertyType DWORD -Force

# Force Group Policy Update
gpupdate /force

Disable-localuser Guest
Disable-localuser Administrator