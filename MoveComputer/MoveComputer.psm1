Function MoveComputer {

Write-Host "Move Computer - Enter hostname:" -fore 10 -back 8 -no
Write-Host " " -no
$Computer_Name = (Read-Host).Trim()  # "9SMCY93"
If ($Computer_Name -eq "") {Write-Host "Hostname not entered... Exiting..."; break}

$MoveFrom = $null
$MoveFrom = (Get-ADComputer $Computer_Name).DistinguishedName
If (!$MoveFrom) {Write-Host "$Computer_Name was not found... Exiting..."; break}

$OU_Except = ("
SVPAcctOU
SVPEngOU
SVPExecOU
SVPHROU
SVPMktgOU
SVPProdOU
SVPPurchOU
SVPQualityOU
WCPAcctOU
WCPEngOU
WCPExecOU
WCPLaptopOU
WCPMktgOU
WCPProdOU
WCPQualityOU
SVPTest
").Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries)

$OU = 'OU=UsuiOU,OU=UICOU,DC=corp,DC=usuiusa,DC=com'
$_OUs = (Get-ADOrganizationalUnit -SearchBase $OU -SearchScope Subtree -Filter * `
| ? {$_.Name -match "SVP" -or $_.Name -match "WCP" } `
| ? {$_.Name -ne "SVPOU" -and $_.Name -ne "WCPOU" }).Name `
| ? {$OU_Except -NOTcontains $_} | Sort
Do {
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -fore 7
#$_OUs | % {If ($_ -match "Lpt10" -or $_ -match "DskOffice" ) {Write-Host "$_" -fore 10}; If ($_ -NOTmatch "Lpt10" -and $_ -NOTmatch "DskOffice" ) {Write-Host "$_" -fore 11}}
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -fore 7
Write-Host "Currently:" -fore 14
$Space = "Computer: "
((Get-ADComputer $Computer_Name).DistinguishedName).Split(',')[0..1] | % {
Write-Host "$Space" -No -fore 11
Write-Host "$($_.substring(3))"
$Space =  "  OU: "
}
''
Write-Host "What is the target OU?:" -fore 10 -back 8 #-no
#Write-Host " " #-no
##################
$menu = @{}
for ($i=1;$i -le $_OUs.count; $i++) 
{
Write-Host "   $i. " -fore 14 -No; 
#Write-Host "$($_OUs[$i-1])" 
If ($($_OUs[$i-1]) -match "Lpt10" -or $($_OUs[$i-1]) -match "DskOffice" ) {Write-Host "$($_OUs[$i-1])" -fore 10}
If ($($_OUs[$i-1]) -NOTmatch "Lpt10" -and $($_OUs[$i-1]) -NOTmatch "DskOffice" ) {Write-Host "$($_OUs[$i-1])" -fore 11}

$menu.Add($i,($_OUs[$i-1]))
}
Write-Host "Enter selection " -No
Write-Host "[1-$($menu.Count)]: " -Fore 14 -No
$EAP = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$ans = $null; [int]$ans = Read-Host #"Enter selection [1-$($menu.Count)]"
$selection = $null; $selection = $menu.Item($ans) ; Write-Host " Selected: $ans - $selection" -fore 14
$ErrorActionPreference = $EAP

##################
$New_OU = $selection #(Read-Host).Trim() #"SVPLpt10"
break
} Until 
($_OUs -contains $New_OU -or $New_OU -eq "")
If ($New_OU -eq "" -or !$New_OU) {Write-Host "No OU was entered / MOVE cancelled." -fore 14 -back 0; break }
$EAP = $ErrorActionPreference 
$ErrorActionPreference = "Inquire"
$MoveTo = (Get-ADOrganizationalUnit -SearchBase $OU -SearchScope Subtree -Filter * | ? {$_.Name -match $New_OU}).DistinguishedName
Write-Host "Move " -fore 11 -No
Write-Host "$Computer_Name " -fore 14 -No
Write-Host "TO" -fore 10 -back 0 -No
Write-Host " $New_OU " -fore 14 -No
Write-Host "OU? " -fore 11 -No
Write-Host "'Y', to proceed: " -fore 10 -No
$Answer = $null; $Answer = (Read-Host).Trim()
If ($Answer -eq "y") {
Move-ADObject –Identity $MoveFrom -TargetPath $MoveTo -Verbose
Write-Host "Wait a few seconds for the move to complete..." -Fore 14
Sleep -Seconds 5
}
If ($Answer -ne "y") {Write-Host "'Y' was not entered - No action taken / MOVE cancelled." -fore 14 -back 0 }

$ErrorActionPreference = $EAP

$Space = "Computer: "
((Get-ADComputer $Computer_Name).DistinguishedName).Split(',')[0..1] | % {
Write-Host "$Space" -No -fore 11
Write-Host "$($_.substring(3))"
$Space =  "  OU: "
}

} # END Function MoveComputer

set-alias -name movepc -value MoveComputer
