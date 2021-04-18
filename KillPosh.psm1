Function KillPoSh {
Write-Host "Enter the Process ID... " -ForegroundColor Green -BackgroundColor Black
$PoSh_PIDs = $null; $PoSh_PIDs = (Get-Process | ? {$_.ProcessName -match "Powershell_"}).Id
$PoSh_PIDs
$PID_No = $null; Write-Host "  ID #: " -ForegroundColor Cyan -NoNewline ; $PID_No = (Read-Host).Trim()
If ($PID_No) {
$PoSh_Path = (Get-Process -Id $PID_No).Path
Stop-Process -Id $PID_No
Start-Sleep -Seconds 2
& $PoSh_Path
}
If (!$PID_No) {Write-Host "Aborted!" -ForegroundColor Yellow}
} # END Function killposh {

set-alias -name kps -value KillPoSh
