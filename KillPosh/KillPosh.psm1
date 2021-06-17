# if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -NoExit -NoLogo -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
Function KillPoSh($PID_No) {
if (!(Test-IsAdmin)){
Write-Host "This only works in an ADMIN session..." -ForegroundColor Yellow -BackgroundColor DarkRed
Write-Host "   Hold on... Opening this in an ADMIN sesssion..."  -ForegroundColor Cyan -BackgroundColor DarkRed
Sleep 5
Start-Process powershell.exe "-NoExit -NoLogo -ExecutionPolicy Bypass -command `"&{kps}`"" -Verb RunAs
break }
$EAP = $ErrorActionPreference 
$ErrorActionPreference = "SilentlyContinue"
$PoSh_PIDs = $null; $PoSh_PIDs = (Get-Process | ? {$_.ProcessName -match "Powershell"}).Id

If ($PID_No) {
$PID_No = ($PID_No).Trim()
If ($PID_No -NOTmatch "^[\d\.]+$" -or $PoSh_PIDs -NOTcontains $PID_No) {
    Write-Host "This is not a valid PoSh 'Process ID': $PID_No"; $PID_No = $null}
}

If (!$PID_No) {
Write-Host "Enter the Process ID " -Fore 10 -Back 0 -NoNewline
Write-Host "- Or COPY it to the clipboard, and hit 'ENTER'..." -Fore 11 -Back 0 -NoNewline
Write-Host "('X' to EXIT)" -Fore 14 -Back 0
#$PoSh_PIDs = $null; $PoSh_PIDs = (Get-Process | ? {$_.ProcessName -match "Powershell"}).Id
Set-Clipboard | Out-Null
$PoSh_PIDs
$PID_No = $null; Write-Host "  ID #: " -ForegroundColor Cyan -NoNewline ; $PID_No = (Read-Host).Trim()
If ($PID_No -eq "x") {break}
}
If ($PID_No -eq "") {$FromClip = (Get-Clipboard).Trim(); $PID_No = $FromClip}

If ($PID_No  -NOTmatch "^[\d\.]+$" -or $PoSh_PIDs -NOTcontains $PID_No) {
    Write-Host "This is not a valid PoSh 'Process ID': $FromClip"; break}
Write-Host "Found / Terminating process: $PID_No" -for 14

If ($PID_No) {
$PoSh_Path = (Get-Process -Id $PID_No).Path
Stop-Process -Id $PID_No
If ($PoSh_Path -match "ise") {
Start-Sleep -Seconds 2
Start-Process $PoSh_Path -ArgumentList "-NoLogo -NoExit"
}
}
If (!$PID_No) {Write-Host "Aborted!" -ForegroundColor Yellow}
$ErrorActionPreference = $EAP 
} # END Function killposh {

set-alias -name kps -value KillPoSh

<#
Modules cannot have an open ''break' command - else they will not load properly
break 
0..5 | % {Write-Host " -Fore $_ -Back 15 " -Fore $_ -Back 15 }
6..8 | % {Write-Host " -Fore $_ -Back 0 " -Fore $_ -Back 0 }
9..9 | % {Write-Host " -Fore $_ -Back 0 " -Fore $_ -Back 15 }
10..15 | % {Write-Host " -Fore $_ -Back 0 " -Fore $_ -Back 0 }
#>

# Start-Process "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoLogo -NoExit"

#& "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe"
