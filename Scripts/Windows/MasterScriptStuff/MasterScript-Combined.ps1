<#
MasterScript-Combined.ps1
Combined version of MasterScript and its modules. This script inlines the module functions so it can be run as a single file.
Run on Windows PowerShell (run as Administrator).
#>
#region Helpers

# Command-line switches: use these to run subsets of the script.
param(
    [switch]$RunAll,
    [switch]$RunFirewall,
    [switch]$RunSecPol,
    [switch]$RunServices,
    [switch]$RunSSH,
    [switch]$RunTasks,
    [switch]$DisableSAMEnumeration,
    [switch]$EnableSAMEnumeration,
    [switch]$ScanUsers,
    [switch]$SyncUsers,
    [string]$UsersSourceUrl = '',
    [switch]$WhatIf
)

#region Helpers
function log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$message
    )
    Write-Host $message
}

function Invoke-Action {
    param(
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$true)][scriptblock]$Action
    )

    if ($WhatIf) {
        log "[WhatIf] $Description"
        return
    }

    try {
        log "Starting: $Description"
        & $Action
        log "Completed: $Description"
    } catch {
        log "Error during $Description: $_"
    }
}

#endregion

#region SAM enumeration
function Set-SAMEnumeration {
    param(
        [Parameter(Mandatory=$true)][bool]$Disable
    )

    $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    $props = @{
        'RestrictAnonymous' = ($(if ($Disable) {1} else {0}))
        'RestrictAnonymousSAM' = ($(if ($Disable) {1} else {0}))
    }

    foreach ($name in $props.Keys) {
        $value = $props[$name]
        try {
            if (Get-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue) {
                Set-ItemProperty -Path $regPath -Name $name -Value $value -ErrorAction Stop
            } else {
                New-ItemProperty -Path $regPath -Name $name -Value $value -PropertyType DWord -ErrorAction Stop | Out-Null
            }
            log "Set registry $regPath\$name to $value"
        } catch {
            log "Failed to set $name in $regPath: $_"
        }
    }
}
#endregion

#region Scan user directories for all files
function Scan-UserFiles {
    param(
        [string]$OutputFile = $(Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath 'user_file_paths.txt'),
        [string]$ErrorsFile = $(Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath 'user_file_paths_errors.txt')
    )

    $roots = @()
    if ($IsWindows) {
        $roots += 'C:\Users'
    } else {
        # macOS / Linux
        $roots += '/Users'
    }

    # Prepare output files
    try { Remove-Item -Path $OutputFile -ErrorAction SilentlyContinue } catch { }
    try { Remove-Item -Path $ErrorsFile -ErrorAction SilentlyContinue } catch { }

    foreach ($root in $roots) {
        if (-not (Test-Path $root)) {
            "$root not found" | Out-File -FilePath $ErrorsFile -Encoding utf8 -Append
            continue
        }

        # Use Get-ChildItem and capture non-terminating errors in $errs
        $errs = $null
        try {
            Get-ChildItem -Path $root -File -Recurse -ErrorAction SilentlyContinue -ErrorVariable errs | ForEach-Object {
                $_.FullName
            } | Out-File -FilePath $OutputFile -Encoding utf8 -Append
        } catch {
            "Error scanning $root: $_" | Out-File -FilePath $ErrorsFile -Encoding utf8 -Append
        }

        if ($errs) {
            $errs | ForEach-Object {
                "[$($_.CategoryInfo.Category)] $($_.Exception.Message) --> $($_.CategoryInfo.TargetName)"
            } | Out-File -FilePath $ErrorsFile -Encoding utf8 -Append
        }
    }

    # Report counts
    try {
        $count = (Get-Content -Path $OutputFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        log "Scan complete. Files found: $count. Output: $OutputFile. Errors (if any): $ErrorsFile"
    } catch {
        log "Scan complete. Output: $OutputFile. Errors (if any): $ErrorsFile"
    }
}
#endregion

#region Sync users from remote source
function Fetch-UserDefinitionsFromUrl {
    param(
        [Parameter(Mandatory=$true)][string]$Url
    )

    $defs = @{}
    try {
        log "Fetching user definitions from $Url"
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
        $content = $resp.Content -split "`n"
    } catch {
        log "Failed to fetch $Url: $_"
        return $defs
    }

    foreach ($line in $content) {
        $l = $line.Trim()
        if ($l -match '^\|') {
            # markdown table row: | username | role |
            $parts = $l -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
            if ($parts.Count -ge 2) {
                $user = $parts[0]
                $role = $parts[1]
                if ($user -and $role) { $defs[$user] = $role }
            }
            continue
        }

        # common patterns: "username - admin" or "username: admin" or "- username - admin"
        if ($l -match '^[\-\*\+\s]*([A-Za-z0-9_.@\\-]{2,})\s*[:\-]\s*(admin|administrator|localadmin|user|member|standard|non-admin|nonadmin|staff)\b') {
            $user = $matches[1]
            $role = $matches[2]
            $defs[$user] = $role
            continue
        }

        # lines like "Create user: username (admin)"
        if ($l -match '([A-Za-z0-9_.@\\-]{2,})\s*\(?\b(admin|administrator|localadmin)\b\)?') {
            $user = $matches[1]
            $role = $matches[2]
            $defs[$user] = $role
            continue
        }
    }

    # Normalize roles to Admin / User
    $normalized = @{}
    foreach ($k in $defs.Keys) {
        $r = $defs[$k].ToString().ToLower()
        if ($r -match 'admin') { $normalized[$k] = 'Admin' } else { $normalized[$k] = 'User' }
    }
    return $normalized
}

function Get-AllLocalUsers {
    $users = @()
    try {
        $local = Get-LocalUser -ErrorAction Stop
        foreach ($u in $local) { $users += [PSCustomObject]@{ Name = $u.Name; Object = $u } }
        return $users
    } catch {
        # fallback to WinNT ADSI enumeration
        try {
            $comp = [ADSI]("WinNT://$env:COMPUTERNAME")
            foreach ($child in $comp.Children) {
                if ($child.SchemaClassName -eq 'User') {
                    $users += [PSCustomObject]@{ Name = $child.Name; Object = $child }
                }
            }
        } catch {
            log "Failed to enumerate local users: $_"
        }
    }
    return $users
}

function Is-UserInAdminGroup {
    param([string]$UserName)
    try {
        $members = Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop | Select-Object -ExpandProperty Name
        return $members -contains $UserName
    } catch {
        # fallback: check ADSI
        try {
            $group = [ADSI]('WinNT://' + $env:COMPUTERNAME + '/Administrators,group')
            foreach ($m in $group.Members()) { if ($m.GetType().InvokeMember('Name','GetProperty',$null,$m,$null) -eq $UserName) { return $true } }
        } catch { }
    }
    return $false
}

function Remove-UserAccount {
    param([string]$UserName)
    try { Remove-LocalUser -Name $UserName -ErrorAction Stop; log "Removed local user $UserName"; return } catch { }
    try { net user $UserName /delete 2>&1 | Out-Null; log "Removed local user $UserName (net user)"; return } catch { log "Failed to remove $UserName: $_" }
}

function Create-UserAccount {
    param(
        [string]$UserName,
        [string]$Role = 'User'
    )
    # generate a random password
    $plain = [System.Web.Security.Membership]::GeneratePassword(12,2) -replace '\\','A'
    $secure = ConvertTo-SecureString $plain -AsPlainText -Force
    try {
        New-LocalUser -Name $UserName -Password $secure -FullName $UserName -ErrorAction Stop
        log "Created user $UserName"
    } catch {
        # fallback to net user
        try { net user $UserName $plain /add 2>&1 | Out-Null; log "Created user $UserName (net user)" } catch { log "Failed to create $UserName: $_" }
    }

    if ($Role -eq 'Admin') {
        try { Add-LocalGroupMember -Group 'Administrators' -Member $UserName -ErrorAction Stop; log "Added $UserName to Administrators" } catch { try { net localgroup Administrators $UserName /add 2>&1 | Out-Null; log "Added $UserName to Administrators (net localgroup)" } catch { log "Failed to add $UserName to Administrators: $_" } }
    }
}

function Sync-UsersFromDefinitions {
    param([hashtable]$Definitions)

    if ($Definitions.Count -eq 0) { log "No user definitions provided to sync."; return }

    $locals = Get-AllLocalUsers
    $localNames = $locals | Select-Object -ExpandProperty Name
    $protected = @('Administrator','Guest','DefaultAccount','WDAGUtilityAccount')
    $currentUser = $env:USERNAME

    foreach ($lu in $localNames) {
        if ($protected -contains $lu) { continue }
        if ($lu -eq $currentUser) { continue }

        if (-not $Definitions.ContainsKey($lu)) {
            $ans = Read-Host "Local user '$lu' not in remote list. Delete? (y/n)"
            if ($ans -match '^[Yy]') {
                Invoke-Action "Remove local user $lu" { Remove-UserAccount -UserName $lu }
            } else { log "Kept user $lu" }
        } else {
            # user present in definitions, check admin membership
            $expected = $Definitions[$lu]
            $isAdmin = Is-UserInAdminGroup -UserName $lu
            if ($expected -eq 'Admin' -and -not $isAdmin) {
                $ans = Read-Host "User '$lu' should be Admin per source but is not. Add to Administrators? (y/n)"
                if ($ans -match '^[Yy]') { Invoke-Action "Add $lu to Administrators" { Add-LocalGroupMember -Group 'Administrators' -Member $lu -ErrorAction SilentlyContinue } }
            } elseif ($expected -eq 'User' -and $isAdmin) {
                $ans = Read-Host "User '$lu' is Admin but source lists as User. Remove from Administrators? (y/n)"
                if ($ans -match '^[Yy]') { Invoke-Action "Remove $lu from Administrators" { Remove-LocalGroupMember -Group 'Administrators' -Member $lu -ErrorAction SilentlyContinue } }
            }
        }
    }

    # Add any missing users listed in definitions
    foreach ($k in $Definitions.Keys) {
        if (-not ($localNames -contains $k)) {
            $role = $Definitions[$k]
            $ans = Read-Host "User '$k' (Role=$role) is in remote list but not local. Create? (y/n)"
            if ($ans -match '^[Yy]') {
                Invoke-Action "Create user $k (Role=$role)" { Create-UserAccount -UserName $k -Role $role }
            } else { log "Skipped creating $k" }
        }
    }
}
#endregion

#region Firewall functions
function set-FirewallRule {
    # Disable every pre-existing rule
    Set-NetFirewallRule * -Enabled False -Action NotConfigured

    # Block multiple Windows features by pre-existing rules
    Set-NetFirewallRule -DisplayGroup "AllJoyn Router","*BranchCache*","Cast to Device functionality","Connect","Cortana","Delivery Optimization","DIAL protocol server","Feedback Hub","File and Printer Sharing","Get Office","Groove Music","HomeGroup","iSCSI Service","mDNS","Media Center Extenders","Microsoft Edge","Microsoft Photos","Microsoft Solitaire Collection","Movies & TV","MSN Weather","Network Discovery","OneNote","*Wi-Fi*","Paint 3D","Proximity Sharing","*Remote*","Secure Socket Tunneling Protocol","*Skype*","SNMP Trap","Store","*Smart Card*","Virtual Machine Monitoring","Windows Collaboration Computer Name Registration Service","*Windows Media Player*","Windows Peer to Peer Collaboration Foundation","Windows View 3D Preview","*Wireless*","*WFD*","*Xbox*","3D Builder","Captive Portal Flow","Take a Test","Wallet" -Action Block -Enabled True -Profile Any

    # Block multiple insecure protocols by pre-existing rules
    Set-NetFirewallRule -DisplayName "*IPv6*","*ICMP*","*SMB*","*UPnP*","*FTP*","*Telnet*" -Action Block -Enabled True -Profile Any

    # Block multiple ports with new rule (Inbound)
    New-NetFirewallRule -DisplayName "FTP, SSH, Telnet" -LocalPort 20-21 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "FTP, SSH, Telnet" -LocalPort 22 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "FTP, SSH, Telnet" -LocalPort 23 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "HTTP" -LocalPort 80 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "TorPark onion routing" -LocalPort 81 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "TorPark control" -LocalPort 82 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "RTelnet" -LocalPort 107 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "RTelnet" -LocalPort 107 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "DHCPv6" -LocalPort 546-547 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "DHCPv6" -LocalPort 546-547 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Flash" -LocalPort 843 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "B.net (Free HK)" -LocalPort 1119 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "B.net (Free HK)" -LocalPort 1119 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Kazaa" -LocalPort 1214 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Kazaa" -LocalPort 1214 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "WASTE" -LocalPort 1337 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Civ" -LocalPort 1492 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Garena" -LocalPort 1513 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Garena" -LocalPort 1513 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "iSketch" -LocalPort 1626-1627 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Defunct RADIUS Ports" -LocalPort 1645-1646 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Windward" -LocalPort 1707 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Windward" -LocalPort 1707 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "America's Army" -LocalPort 1716 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Microsoft Media Services" -LocalPort 1755 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Microsoft Media Services" -LocalPort 1755 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "SSDP" -LocalPort 1900 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Macro Flash" -LocalPort 1935 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Macro Flash" -LocalPort 1935 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Netop" -LocalPort 1970 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Netop" -LocalPort 1970 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Civ 4" -LocalPort 2033 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Civ 4" -LocalPort 2033 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Warzone 2100" -LocalPort 2100 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Apple Notifs" -LocalPort 2195 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Apple Notifs Feedback" -LocalPort 2196 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "ArmA/Halo" -LocalPort 2302-2305 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "AIM/Ghost" -LocalPort 2351-2368 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Ultima Online" -LocalPort 2593 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Ultima Online" -LocalPort 2593 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Ultima Online 2" -LocalPort 2599 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Ultima Online 2" -LocalPort 2599 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "iSync" -LocalPort 3004 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Xbox LIVE" -LocalPort 3074 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Xbox LIVE" -LocalPort 3074 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "iSCSI" -LocalPort 3260 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "iSCSI" -LocalPort 3260 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "RDP" -LocalPort 3389 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "RDP" -LocalPort 3389 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "PlayStation" -LocalPort 3479-3480 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "PlayStation" -LocalPort 3479-3480 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Cyc" -LocalPort 3645 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Cyc" -LocalPort 3645 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "BF4" -LocalPort 3659 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Blizzard games/Club Penguin" -LocalPort 3724 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Blizzard games/Club Penguin" -LocalPort 3724 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "WarMUX" -LocalPort 3826 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "WarMUX" -LocalPort 3826 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Warframe" -LocalPort 3960 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Warframe again" -LocalPort 3962 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "OpenTTD" -LocalPort 3978-3979 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "OpenTTD" -LocalPort 3978-3979 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Diablo 2" -LocalPort 4000 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Diablo 2" -LocalPort 4000 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Microsoft Ants" -LocalPort 4001 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Amazon Echo" -LocalPort 4070 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Amazon Echo" -LocalPort 4070 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Microsoft Remote Web Workplace admin" -LocalPort 4125 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Apprentice" -LocalPort 4747 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Many things" -LocalPort 5000 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Many things" -LocalPort 5000 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "LoL" -LocalPort 5000-5500 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Neverwinter Nights" -LocalPort 5121 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Apple Notif 2" -LocalPort 5223 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Outlaws" -LocalPort 5310 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "PostgreSQL" -LocalPort 5432 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Freeciv" -LocalPort 5556 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Freeciv" -LocalPort 5556 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "TeamViewer" -LocalPort 5938 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "TeamViewer" -LocalPort 5938 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "More b.net/CP 2 (Free HK)" -LocalPort 6112 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "More b.net/CP 2 (Free HK)" -LocalPort 6112 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "B.net/Club penguin 3" -LocalPort 6113 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "BitTorrent" -LocalPort 6881-6887 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "BitTorrent" -LocalPort 6881-6887 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "BitTorrent" -LocalPort 6888 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "BitTorrent" -LocalPort 6888 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "BitTorrent" -LocalPort 6889-6900 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "BitTorrent" -LocalPort 6889-6900 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "BitTorrent tracker" -LocalPort 6969 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "HTTP Bittorrent" -LocalPort 7000 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Enemy Territory: Quake Wars" -LocalPort 7133 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Tibia" -LocalPort 7171 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "WatchMe" -LocalPort 7272 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "WatchMe" -LocalPort 7272 -Protocol UDP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Rise: The Vieneo Province" -LocalPort 7473 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Saratoga FTP" -LocalPort 7542 -Protocol TCP -Action Block -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "Saratoga FTP" -LocalPort 7542 -Protocol UDP -Action Block -Enabled True -Direction Inbound

    # (Outbound rules mirror many of the inbound blocks)
    New-NetFirewallRule -DisplayName "FTP, SSH, Telnet" -LocalPort 20-21 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "FTP, SSH, Telnet" -LocalPort 22 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "FTP, SSH, Telnet" -LocalPort 23 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "HTTP" -LocalPort 80 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "TorPark onion routing" -LocalPort 81 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "TorPark control" -LocalPort 82 -Protocol UDP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "RTelnet" -LocalPort 107 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "RTelnet" -LocalPort 107 -Protocol UDP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "DHCPv6" -LocalPort 546-547 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "DHCPv6" -LocalPort 546-547 -Protocol UDP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "Flash" -LocalPort 843 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "B.net (Free HK)" -LocalPort 1119 -Protocol TCP -Action Block -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "B.net (Free HK)" -LocalPort 1119 -Protocol UDP -Action Block -Enabled True -Direction Outbound

    # Block ICMP/ICMPv6 rules
    New-NetFirewallRule -DisplayName "ICMPv4" -Protocol ICMPv4 -Action Block -Enabled True -Direction Inbound -Profile Any
    New-NetFirewallRule -DisplayName "ICMPv4" -Protocol ICMPv4 -Action Block -Enabled True -Direction Outbound -Profile Any
    New-NetFirewallRule -DisplayName "ICMPv6" -Protocol ICMPv6 -Action Block -Enabled True -Direction Inbound -Profile Any
    New-NetFirewallRule -DisplayName "ICMPv6" -Protocol ICMPv6 -Action Block -Enabled True -Direction Outbound -Profile Any

    # Allow some necessary outbound ports
    New-NetFirewallRule -DisplayName "HTTPS" -LocalPort 443 -Protocol TCP -Action Allow -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "NTP" -LocalPort 123 -Protocol UDP -Action Allow -Enabled True -Direction Outbound
    New-NetFirewallRule -DisplayName "NTP" -LocalPort 123 -Protocol UDP -Action Allow -Enabled True -Direction Inbound

    # Allow Defender related rules
    Set-NetFirewallRule -DisplayName "*Defender*" -Enabled True -Action Allow -Profile Any
}

function set-Firewall {
    # Ensure firewall service running
    Set-Service -Name MpsSvc -StartupType Automatic -Status Running

    # Enable the firewall profiles
    Set-NetFirewallProfile -Name Domain, Public, Private -Enabled True

    # Set direction defaults
    Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction Allow

    # Settings for profiles
    Set-NetFirewallProfile -Name Domain, Private, Public -NotifyOnListen False

    # Unique settings for Public
    Set-NetFirewallProfile -Name Public -AllowLocalFirewallRules False -AllowLocalIPsecRules False

    # Logging settings
    Set-NetFirewallProfile -Name Domain, Private, Public -LogFileName "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log" -LogMaxSizeKilobytes 16384 -LogBlocked True -LogAllowed True
}
#endregion

#region SSH
function setSSHconfig {
    # Start the service and ensure startup
    Set-Service -Name sshd -StartupType Automatic -Status Running

    # Configure firewall rules for SSH (ensure idempotency)
    # Remove any previous blocking rule on port 22 (if present)
    Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { ($_ | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue).LocalPort -contains 22 } | Remove-NetFirewallRule -ErrorAction SilentlyContinue

    New-NetFirewallRule -DisplayName "OpenSSH" -Protocol TCP -LocalPort 22 -Action Allow -Enabled True -Direction Inbound
    New-NetFirewallRule -DisplayName "OpenSSH" -Protocol TCP -LocalPort 22 -Action Allow -Enabled True -Direction Outbound
}
#endregion

#region SecPol helpers
function Get-Secpol {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CfgFile
    )
    secedit /export /cfg "$CfgFile" | Out-Null
    $obj = New-Object psobject
    $index = 0
    $contents = Get-Content $CfgFile -Raw
    [regex]::Matches($contents,"(?<=\[)(.*)(?=\])") | ForEach-Object {
        $title = $_.Value
        [regex]::Matches($contents,"(?<=\]).*?((?=\[)|(\Z))", [System.Text.RegularExpressions.RegexOptions]::Singleline)[$index] | ForEach-Object{
            $section = New-Object psobject
            $_.Value -split "\r\n" | Where-Object{$_.Length -gt 0} | ForEach-Object {
                $value = [regex]::Match($_,"(?<=\=).*).Value
                $name = [regex]::Match($_,".*(?=\=") ).Value
            }
        }
        $index += 1
    }

    # Fallback simple parser (previous implementation returned a nested PSObject).
    # Use the original implementation from module file for compatibility instead of complex rewrite.
    secedit /export /cfg "$CfgFile" | Out-Null
    $obj = New-Object psobject
    $index = 0
    $contents = Get-Content $CfgFile -Raw
    [regex]::Matches($contents,"(?<=\[)(.*)(?=\])") | ForEach-Object {
        $title = $_
        [regex]::Matches($contents,"(?<=\]).*?((?=\[)|( ))", [System.Text.RegularExpressions.RegexOptions]::Singleline)[$index] | ForEach-Object{
            $section = New-Object psobject
            $_.Value -split "\r\n" | Where-Object{ $_.Length -gt 0 } | ForEach-Object {
                $value = [regex]::Match($_,"(?<=\=).*" ).Value
                $name = [regex]::Match($_,".*(?=\=)" ).Value
                try { $section | Add-Member -MemberType NoteProperty -Name $name.ToString().Trim() -Value $value.ToString().Trim() -ErrorAction SilentlyContinue } catch { }
            }
            try { $obj | Add-Member -MemberType NoteProperty -Name $title -Value $section } catch { }
        }
        $index += 1
    }
    return $obj
}

function Set-SecPol {
    param(
        [Parameter(Mandatory=$true)]
        $Object,
        [Parameter(Mandatory=$true)]
        [string]$CfgFile
    )
    $Object.psobject.Properties.GetEnumerator() | ForEach-Object{
        "[$($_.Name)]"
        $_.Value | ForEach-Object{
            $_.psobject.Properties.GetEnumerator() | ForEach-Object{
                "$($_.Name)=$($_.Value)"
            }
        }
    } | Out-File -FilePath $CfgFile -ErrorAction Stop -Encoding ASCII
    secedit /configure /db c:\windows\security\local.sdb /cfg "$CfgFile" /areas SECURITYPOLICY
}
#endregion

#region Services and Tasks
function disableUnsecureServices {
    # Disable unneeded/insecure services (idempotent)
    $svcnames = @(
        'Browser','bthserv','Fax','icssvc','irmon','lfsvc','lltdsvc','MapsBroker','MSiSCSI','p2pimsvc','p2psvc','PhoneSvc','PlugPlay','PNRPAutoReg','PNRPsvc','RasAuto','RemoteAccess','RemoteRegistry','RpcLocator','SessionEnv','SharedAccess','SNMPTRAP','SSDPSRV','TermService','UmRdpService','upnphost','vmicrdv','W32Time','W3SVC','wercplsupport','WerSvc','WinHttpAutoProxySvc','WinRM','WlanSvc','WMPNetworkSvc','WpnService','WpnUserService*','WwanSvc','xbgm','XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc','PushToInstall','spectrum','icssvc','wisvc','StiSvc','FrameServer','WbioSrvc','WFDSConSvc','WebClient','WMSVC','WalletService','UevAgentService','UwfServcingSvc','TabletInputService','TapiSrv','WiaRpc','SharedRealitySvc','SNMP','SCPolicySvc','ScDeviceEnum','simptcp','ShellHWDetection','shpamsvc','SensorService','SensrSvc','SensorDataService','SstpSvc','iprip','RetailDemo','RasMan','RmSvc','PrintNotify','WpcMonSvc','SEMgrSvc','CscService','NcaSVC','NcbService','NcdAutoSetup','Netlogon','NetTcpPortSharing','NetTcpActivator','NetMsmqActivator','Wms','WmsRepair','SmsRouter','MsKeyboardFilter','ftpsvc','AppVClient','wlidsvc','diagnosticshub.standardcollector.service','MSMQTriggers','MSMQ','LxssManager','LPDSVC','lpxlatCfgSvc','iphlpsvc','IISADMIN','vmicvss','vmms','vmictimesync','vmicrdv','vmicmsession','vmcompute','vmicheartbeat','vmicshutdown','vmicguestinterface','vmickvpexchange','HvHost','EapHost','dmwappushsvc','TrkWks','WdiSystemHost','WdiServiceHost','diagsvc','DiagTrack','NfsClnt','CertPropSvc','CaptureService_*','camsvc','PeerDistSvc','BluetoothUserService_*','BTAGService','BthAvctpSvc','tzautoupdate','ALG','AJRouter'
    )
    foreach ($s in $svcnames) {
        try {
            Set-Service -Status Stopped -StartupType Disabled -Name $s -ErrorAction SilentlyContinue
        } catch { }
    }

    # Enable needed services
    $needed = @('BDESVC','BFE','CryptSvc','DcomLaunch','Dhcp','Dnscache','EventLog','Group','LanmanServer','LanmanWorkstation','MpsSvc','nsi','Power','RpcEptMapper','RpcSs','SamSs','SecurityHealthService','Sense','WdNisSvc','Wecsvc','WEPHOSTSVC','WinDefend','wuauserv','WSearch','TrustedInstaller','Winmgmt','msiserver','FontCache','Wcmsvc','AudioSrv','AudioEndpointBuilder','vds','ProfSvc','UserManager','UsoSvc','Themes','Schedule','SgrmBroker','SystemEventsBroker','SENS','OneSyncSvc_*','SysMain','sppsvc','wscsvc','PcaSvc','Spooler','WPDBusEnum','ssh-agent','NlaSvc','LSM','gpsvc','EFS','DPS','DoSvc','DusmSvc','CoreMessagingRegistrar','CDPUserSvc_*','CDPSvc','EventSystem','BrokerInfrastructure','BITS','AppHostSvc')
    foreach ($n in $needed) {
        try { Set-Service -Status Running -StartupType Automatic -Name $n -ErrorAction SilentlyContinue } catch { }
    }

    # Manual services list
    $manual = @('dot3svc','WaaSMedicSvc','wmiApSrv','LicenseManager','SDRSVC','TokenBroker','W3LOGSVC','VSS','UnistoreSvc_*','UserDataSvc_*','upnphost','TimeBroker','lmhosts','TieringEngineService','StorSvc','StateRepository','svsvc','seclogon','QWAVE','PrintWorkflowUserSvc_*','pla','PerfHost','defragsvc','NetSetupSvc','netprofm','Netman','InstallService','smphost','sqprv','NgcCtnrSvc','NgcSvc','MessagingService_*','wlpasvc','KtmRm','UI0Detect','PolicyAgent','IKEEXT','hidserv','hns','GraphicsPerfSvc','FDResPub','fdPHost','fhsvc','EntAppSvc','embeddedmode','DsRoleSvc','MSDTC','DevQueryBroker','DevicesFlowUserSvc_*','DevicePickerUserSvc_*','DsmSVC','DmEnrollmentSvc','DeviceInstall','DsSvc','COMSysApp','KeyIso','ClipSVC','c2wts','wbegine','aspnet_state','AssignedAccessManagerSvc','AppXSVC','AppMgmt','Appinfo','AppIDSvc','AppReadiness','AxInstSV')
    foreach ($m in $manual) {
        try { Set-Service -StartupType Manual -Name $m -ErrorAction SilentlyContinue } catch { }
    }

    # Some services cannot be disabled but should be stopped or set manual
    $stoppedManual = @('BcastDVRUserService_*','DeviceAssociationService','VaultSvc','PimIndexMaintenanceSvc_*')
    foreach ($t in $stoppedManual) {
        try { Set-Service -Status Stopped -StartupType Manual -Name $t -ErrorAction SilentlyContinue } catch { }
    }
}

function disableTasks {
    try { Unregister-ScheduledTask -TaskPath *Bluetooth* -ErrorAction SilentlyContinue } catch { }
    try { Unregister-ScheduledTask -TaskPath *Location* -ErrorAction SilentlyContinue } catch { }
    try { Unregister-ScheduledTask -TaskPath *Maps* -ErrorAction SilentlyContinue } catch { }
    try { Unregister-ScheduledTask -TaskPath *UPnP* -ErrorAction SilentlyContinue } catch { }
    try { Unregister-ScheduledTask -TaskPath '*Plug and Play*' -ErrorAction SilentlyContinue } catch { }
    try { Unregister-ScheduledTask -TaskPath '*Windows Error Reporting*' -ErrorAction SilentlyContinue } catch { }
}
#endregion

# Main orchestration (selective by switches)
try {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    log "Using script dir: $ScriptDir"

    $systemAccessPath = Join-Path $ScriptDir 'lib/System Access.json'
    $eventAuditPath = Join-Path $ScriptDir 'lib/Event Audit.json'

    if (Test-Path $systemAccessPath) {
        $SystemAccessSecPolConfig = Get-Content -Path $systemAccessPath | ConvertFrom-Json
    } else { log "Warning: $systemAccessPath not found"; $SystemAccessSecPolConfig = $null }

    if (Test-Path $eventAuditPath) {
        $EventAuditSecPolConfig = Get-Content -Path $eventAuditPath | ConvertFrom-Json
    } else { log "Warning: $eventAuditPath not found"; $EventAuditSecPolConfig = $null }

    $secTemp = Join-Path $env:TEMP 'SecPool.cfg'

    # Determine which actions to run
    $DoFirewall = $RunAll -or $RunFirewall
    $DoSecPol = $RunAll -or $RunSecPol
    $DoServices = $RunAll -or $RunServices
    $DoSSH = $RunAll -or $RunSSH
    $DoTasks = $RunAll -or $RunTasks
    # Default secure behavior: when -RunAll is used, disable SAM enumeration unless explicitly enabled
    $DoSAMDisable = $DisableSAMEnumeration -or $RunAll
    $DoSAMEnable = $EnableSAMEnumeration

    if ($DoSecPol) {
        Invoke-Action "Export current SecPol and apply JSON settings" {
            log "Exporting current SecPol to $secTemp"
            $SecPool = Get-Secpol -CfgFile $secTemp

            if ($SystemAccessSecPolConfig -ne $null) {
                $SystemAccessSecPolConfig.PSObject.Properties | ForEach-Object {
                    $name = $_.Name
                    $value = $_.Value

                    if (-not $SecPool.PSObject.Properties.Match('System Access')) {
                        $null = $SecPool | Add-Member -MemberType NoteProperty -Name 'System Access' -Value (New-Object PSObject) -Force
                    }
                    try { $SecPool.'System Access'.$name = $value } catch { }
                }
            }

            if ($EventAuditSecPolConfig -ne $null) {
                $EventAuditSecPolConfig.PSObject.Properties | ForEach-Object {
                    $name = $_.Name
                    $value = $_.Value

                    if (-not $SecPool.PSObject.Properties.Match('Event Audit')) {
                        $null = $SecPool | Add-Member -MemberType NoteProperty -Name 'Event Audit' -Value (New-Object PSObject) -Force
                    }
                    try { $SecPool.'Event Audit'.$name = $value } catch { }
                }
            }

            Set-SecPol -Object $SecPool -CfgFile $secTemp
        }
    }

    if ($DoFirewall) {
        Invoke-Action "Configure firewall rules" {
            set-FirewallRule
            set-Firewall
        }
    }

    if ($DoTasks) {
        Invoke-Action "Disable scheduled tasks" {
            disableTasks
        }
    }

    if ($DoServices) {
        Invoke-Action "Disable insecure services" {
            disableUnsecureServices
        }
    }

    if ($DoSSH) {
        Invoke-Action "Configure SSH" {
            setSSHconfig
        }
    }

    if ($DoSAMDisable -and $DoSAMEnable) {
        log "Cannot specify both -DisableSAMEnumeration and -EnableSAMEnumeration. Choose one."
    } elseif ($DoSAMDisable) {
        Invoke-Action "Disable anonymous enumeration of SAM accounts and shares" {
            Set-SAMEnumeration -Disable $true
        }
    } elseif ($DoSAMEnable) {
        Invoke-Action "Enable anonymous enumeration of SAM accounts and shares" {
            Set-SAMEnumeration -Disable $false
        }
    }

    if ($ScanUsers) {
        Invoke-Action "Scan user directories for all files and save to Desktop" {
            Scan-UserFiles
        }
    }

    if ($SyncUsers) {
        $url = $UsersSourceUrl
        if ([string]::IsNullOrWhiteSpace($url)) {
            $url = Read-Host "Enter the URL of the CyberPatriot README or user list to sync from"
        }
        if (-not [string]::IsNullOrWhiteSpace($url)) {
            $defs = Fetch-UserDefinitionsFromUrl -Url $url
            if ($defs.Count -gt 0) {
                Sync-UsersFromDefinitions -Definitions $defs
            } else { log "No user definitions parsed from $url" }
        } else { log "No URL provided for user sync." }
    }

    if (-not ($DoSecPol -or $DoFirewall -or $DoTasks -or $DoServices -or $DoSSH)) {
        log "No action switches provided. Use -RunAll or one of -RunFirewall, -RunSecPol, -RunServices, -RunSSH, -RunTasks. Use -WhatIf for a dry-run."
    } else {
        log "Completed selected actions."
    }

} catch {
    log "Error during execution: $_"
    throw
}
