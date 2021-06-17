Function Get-PC {

$EAP = $ErrorActionPreference 
$ErrorActionPreference = "SilentlyContinue"

Write-Host "Computer info - Enter hostname:" -fore Cyan -back Black -no
Write-Host " " -no
$Computer_Name = ((Read-Host).Trim()).ToUpper()
If ($Computer_Name -eq "") {Write-Host "Hostname not entered... Exiting..."; break}

$PC_Deets = $null
$PC_Deets = (Get-ADComputer $Computer_Name).DistinguishedName
If (!$PC_Deets) {Write-Host "$Computer_Name was not found... Exiting..."; break}

If (!((Test-NetConnection $Computer_Name).PingSucceeded)) {Write-Host "   $Computer_Name is unreachable..."; break}

# WinRM test
WinRM $Computer_Name
# END WinRM test

Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -fore 7
Write-Host "Gatering info about: " -fore 14 -No; Write-Host $Computer_Name
$Remote_Info = icm -ComputerName $Computer_Name {
((Get-WMIObject -class Win32_ComputerSystem).username).Trim()
((Get-WmiObject win32_operatingsystem | select @{LABEL=’LastBootUpTime’;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}).LastBootUpTime | Out-String).Trim()
} 

$UpTime = (Get-Date) - ([DateTime]$Remote_Info[1])
If ($UpTime.Days -eq 0) {$UpTime = "$($UpTime.Hours) hour(s)"}
If ($UpTime.Days -gt 0) {$UpTime = "$($UpTime.Days) day(s), $($UpTime.Hours) hour(s)"}

$FL_Name = $null; $FL_Name = (Get-ADUser $(($Remote_Info[0]).Split('\')[1])).Name
$Deets = Get-ADComputer $Computer_Name | Select `
@{Name='Hostname';Expression ={($_.Name)}},`
@{Name='      OU';Expression ={( ((($_).DistinguishedName).Split(',')[1]).substring(3) )}}, `
@{Name='      IP';Expression ={( (Test-Connection $_.Name -Count 1).IPV4Address.IPAddressToString )}},`
@{Name='    User';Expression ={ "$FL_Name / $(($Remote_Info[0]).Split('\')[1])" } },`
@{Name='    Boot';Expression ={ $($Remote_Info[1]) } },`
@{Name='    Uptime';Expression ={ $UpTime } }

Write-Host ($Deets | fl | Out-String).Trim() -Fore 14
''
If ( $FL_Name ) { $FL_Name | clip; ofc }
Set-Clipboard $null
$ErrorActionPreference = $EAP 

} # END Function MoveComputer

set-alias -name gpc -value Get-PC

