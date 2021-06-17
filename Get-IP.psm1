Function Get-IP {

Write-Host "Fetching IP info..." -ForegroundColor Gray -BackgroundColor Black
$AdapterList = @()
Get-NetAdapter | ? {$_.InterfaceDescription -NOTmatch 'Bluetooth'}  | % { 
$adapter = $_
$prefix = (Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex | ? {$_.ipv4address}).prefixlength
('1' * $prefix).PadRight(32, '0') | Out-Null;$bitString=('1' * $prefix).PadRight(32,'0'); $SnM=[String]::Empty
    for($i=0;$i -lt 32;$i+=8)
    {$byteString=$bitString.Substring($i,8); $SnM+="$([Convert]::ToInt32($byteString, 2))."}
If ((Get-NetIPInterface -InterfaceAlias $_.InterfaceAlias).Dhcp -eq "Enabled") {$DHCP = "DHCP"} else {$DHCP = "STATIC"}
$AdapterList += ((Get-NetIPConfiguration | ? {$_.InterfaceIndex -match "$($adapter.InterfaceIndex)"} | select `
    @{Name='Alias';Expression ={$_.InterfaceAlias}},`
    @{Name='Status';Expression ={$_.NetAdapter.Status}},`
    @{Name='IPAddress';Expression ={"$($_.IPv4Address.IPAddress) ($DHCP)"}},`
    @{Name='SubnetMask';Expression ={"$($SnM.TrimEnd('.')) (/$prefix)"}},`
    @{Name='Gateway';Expression ={$_.IPv4DefaultGateway.NextHop}},`
    @{Name='DNSServer(s)';Expression ={$_.DNSServer.ServerAddresses}},`
    @{Name='MAC';Expression ={$adapter.MacAddress}},`
    @{Name='Index';Expression ={$_.InterfaceIndex}},`
    @{Name='Description';Expression ={$_.InterfaceDescription}}))
    }
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Gray
$AdapterList | % {
$_ | % {
If ($_.IPAddress -match "169.") {
    $_.IPAddress = "($DHCP)"
    $_.SubnetMask = " - "
}

$Item00 = $_
($Item00 | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries) | % {
If ($Item00.Status -match "Disconnected") {Write-Host ">> " -fore Red -No }
If ($Item00.Status -match "Up") {Write-Host "<< " -fore Green -No }
If ($_ -match "Index") {Write-Host " " $_ -ForegroundColor cyan} 
If ($_ -match "Alias") {Write-Host " " $_ -ForegroundColor Yellow} 
If ($_ -match ": Up") {Write-Host " " $_ -ForegroundColor Green} 
If ($_ -match ": Disconnected") {Write-Host " " $_ -ForegroundColor Magenta}
If ($_ -NOTmatch "Index" -and $_ -NOTmatch "Alias" -and $_ -NOTmatch "Status") {Write-Host " " $_} 
}

($Item00 | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries) | % {
    If ($_ -match "Alias" -and $_ -match "Wi-Fi" -and $Item00.Status -match "Up") {
        netsh wlan show interfaces | % {
            If ($_ -match "SSID" -and $_ -NOTmatch "BSSID") {$SSID = $_}
            If ($_ -match "State") {$State = $_}
            If ($_ -match "Signal") {$Signal = $_}
            If ($_ -match "Authentication") {$Auth = $_}
        }
            Function SplitWrite($arg0) {Write-Host ($arg0.Split(':')[1]).Trim() -Fore 11}
                Write-Host "             SSID: " -Fore 14 -No; SplitWrite $SSID
                Write-Host "            State: " -Fore 14 -No; SplitWrite $State
                Write-Host "           Signal: " -Fore 14 -No; SplitWrite $Signal
                Write-Host "             Auth: " -Fore 14 -No; SplitWrite $Auth
    } 
}

}
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Gray
}

} # End Function Get-IP

set-alias -name gip -value Get-IP
