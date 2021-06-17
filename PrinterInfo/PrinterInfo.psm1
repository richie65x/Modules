Function PrinterInfo {

$EAP = $ErrorActionPreference 
$ErrorActionPreference = "SilentlyContinue"
$PTRname = Get-Clipboard
# if ($Who -eq "x" -or $Who -eq $null) {Write-Host "Nothing entered - Exiting..."; break}
if ($PTRname -eq "x") {Write-Host " - Exiting..."; break}

If (!$PTRname) {
Write-Host "Printer name? " -NoNewline -ForegroundColor Yellow -BackgroundColor DarkMagenta
Write-Host "('X' to exit)" -NoNewline -ForegroundColor Cyan -BackgroundColor DarkMagenta
Write-Host ":" -NoNewline -ForegroundColor Yellow -BackgroundColor DarkMagenta; Write-Host " " -NoNewline
$PTRname = (Read-Host).Trim()
}
If ($PTRname -eq "x") {break}
If ($PTRname) {$PTRname = "$(($PTRname).Trim())"}

If (!$PTRname) {Write-host "Nothing to look for / Nothing entered." -ForegroundColor Yellow -BackgroundColor Black; break}
Write-Host "Gathering Printer info..." -for 10
$PTR_deets = Get-Printer -ComputerName SVDC3 | ? {$_.Name -match $PTRname} | select Name, PortName, IP, DriverName
$PTR_deets.IP = (Get-PrinterPort -ComputerName SVDC3 | ? {$_.Name -eq $($PTR_deets.PortName)} | select PrinterHostAddress).PrinterHostAddress

($PTR_deets | fl | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries) | % {
$Line_ = ($_).Split(':')
Write-Host "$($Line_[0]):" -ForegroundColor Cyan -NoNewline
Write-Host "$($Line_[1])" -ForegroundColor Yellow
}
$Connected = 0
Function connect {
$R_Time = $null; $R_Time = (Test-Connection $PTR_deets.IP -Count 1).ResponseTime
If ($R_Time) {$Response = "$R_Time ms"}
If (!$R_Time) {$Response = "..."}
$R_Time = $null; Return $Response
}
$Response = connect

Write-Host "    Checking connectivity...    " -Fore 1 -Back 14
Write-Host "Response times: " -NoNewline; connect
Write-Host "                " -NoNewline; connect
Write-Host "                " -NoNewline; connect
If (Test-Connection $PTR_deets.IP -Quiet -Count 1) {}
Else {
$Connected = 1
Write-Host "  $($PTR_deets.IP) / $($PTR_deets.Name) did NOT respond.  " -Fore 14 -Back 5
break
}

If ($Connected -eq 0) {
Write-Host "  $($PTR_deets.IP) / $($PTR_deets.Name) responded.  " -Fore 14 -Back 2
break
}
Write-Host "This message:" -for 14
Write-Host "  Unable to connect to label component  " -for 15 -back 4
Write-Host "Is saying: `"Install the 'Plex Component Host' from the PC setup page on Plex.`"
    Found here: "  -for 11 -No

Write-Host "https://www.plexonline.com/modules/Platform/Login/ComponentHost.aspx
Script to get / download the installer is: .\Download the Plex Component Host.ps1" -for 14


} # END Function PrinterInfo {

set-alias -name ptr -value PrinterInfo