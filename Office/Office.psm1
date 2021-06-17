Function Office {

$EAP = $ErrorActionPreference 
$ErrorActionPreference = "SilentlyContinue"
$Who = Get-Clipboard
# if ($Who -eq "x" -or $Who -eq $null) {Write-Host "Nothing entered - Exiting..."; break}
if ($Who -eq "x") {Write-Host " - Exiting..."; break}
If ($Who -is [array]) {
$Who =  [string]::Join(" ",$Who)
}
If (!$Who) {
Write-Host "Full name, username, or email address? " -NoNewline -ForegroundColor Yellow -BackgroundColor DarkMagenta
Write-Host "('X' to exit)" -NoNewline -ForegroundColor Cyan -BackgroundColor DarkMagenta
Write-Host ":" -NoNewline -ForegroundColor Yellow -BackgroundColor DarkMagenta; Write-Host " " -NoNewline
$Who = (Read-Host).Trim()
}
If ($Who -eq "x") {break}
If ($Who) {$Who = "$(($Who).Trim())"}

If (!$Who) {Write-host "Nothing to look for / Nothing entered." -ForegroundColor Yellow -BackgroundColor Black; break}
$Quality = 0
If ($Who -NOTmatch " " -and $Who -NOTmatch "@") { $Quality = 1; Write-Host "Looking for this username: $Who" -ForegroundColor Cyan }
If ($Who -match "@") { $Quality = 2; Write-Host "Looking for this email adddress: $Who" -ForegroundColor Cyan }
If ($Who -match " ") { $Quality = 3; Write-Host "Looking for this name: $Who" -ForegroundColor Cyan }

Function ADU1 {
$ErrorActionPreference = "SilentlyContinue"
Get-ADUser -filter * -Properties City, State, telephoneNumber, mail, Title, Manager, Description
$ErrorActionPreference = "Continue"
} 
$Output = $null
If ($Quality -eq 1) { $Output = ADU1 | ? {$_.SamAccountName -match $Who} }
If ($Quality -eq 2) { $Output = ADU1 | ? {$_.mail -match $Who} }
If ($Quality -eq 3) { $Output = ADU1 | ? {$_.Name -match $Who} }

If (!$Output) {Write-host "`'$Who`' is not valid." -ForegroundColor Yellow -BackgroundColor Black
Set-Clipboard $null
office
}

$Desription = $null; $Desription = ($Output.Description).Replace('|','-')
$Username = $Output.SamAccountName
#$Output = $Output | Select Name, @{Name='Username';Expression ={($_.SamAccountName).ToUpper()}}, City, State, @{Name='Phone';Expression={$("{0:# ###-###-####}" -f [int64](($Output.telephoneNumber).Trim('+')))}}, mail, Title,@{Name='Manager';Expression ={($_.SamAccountName).ToUpper()}} | Out-String
$Output = $Output | Select Name, `
@{Name='Username';Expression ={($_.SamAccountName).ToUpper()}}, `
@{Name='Description';Expression ={($Desription)}},`
 City, State, `
@{Name='Phone';Expression={$("{0:# ###-###-####}" -f [int64](($Output.telephoneNumber).Trim('+')))}}, `
mail, Title, `
@{Name='Manager';Expression ={"$((Get-ADUser ((get-aduser ($_.SamAccountName) -Properties Manager).Manager) | Select `
    @{name="Manager";expression={"$($_.Name) ($(($_.SamAccountName).ToUpper())) - $($_.UserPrincipalName)"}}).Manager)"}} `
| Out-String
Write-Host " "
$Output.Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries)  | % {
If ($_ -match "City" -or $_ -match "State" ) { Write-Host " $_" -ForegroundColor Yellow }
If ($_ -NOTmatch "City" -and $_ -NOTmatch "State" ) { Write-Host "   $_" }
}
############################
$BuildUp_01 = get-aduser $Username -Properties Description,PasswordLastSet,LastLogonDate,PasswordExpired,PasswordNeverExpires,Modified,lockoutTime,LockedOut,whenChanged,CanonicalName,AccountExpirationDate 
$UPN = $BuildUp_01.UserPrincipalName
$CanonicalName = $BuildUp_01.CanonicalName

$BuildUp_01_lockoutTime = $BuildUp_01.lockoutTime
If ($BuildUp_01_lockoutTime -gt 0) {$BuildUp_01_lockoutTime = [datetime]::FromFileTime($($BuildUp_01_lockoutTime))}
($BuildUp_01 | select -Property `
@{name="Name";expression={$_.Name}},` 
@{name="Description";expression={$_.Description}},` 
@{name="Lockout time";expression={$BuildUp_01_lockoutTime}},` 
@{name="Locked out";expression={$BuildUp_01.LockedOut}},` 
@{name="Password Never Expires";expression={$_.PasswordNeverExpires}},`
@{name="Expiration";expression={$BuildUp_01.AccountExpirationDate}},` 
@{name="Password Last Set";expression={$_.PasswordLastSet}},` 
@{name="Password Expired";expression={$_.PasswordExpired}},` 
@{name="Last Logon";expression={$BuildUp_01.LastLogonDate}},`  
@{name="Object last changed";expression={$_.whenChanged}} | fl | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries) | % {

    If ($_ -match "Last Logon"){  Write-Host "  $_" }

    If ($_ -match "Lockout time"){ 
    If (($_ -NOTlike "*: 0") -and ($BuildUp_01.LockedOut -eq $true)) {
    $lockout = 1; $lockoutPolicy = 1
    Write-Host " " $_ 
    $LockOutTime = $BuildUp_01_lockoutTime
    }}

    If (($_ -match "Locked out") -and ($BuildUp_01.LockedOut -eq $true)){
    Write-Host " " $_ -ForegroundColor White -BackgroundColor Red
    $lockout = 0}

    If (($_ -Like "Password Never Expires*") -and ($BuildUp_01.PasswordNeverExpires -eq $True)){
    Write-Host " " $_ -ForegroundColor White -BackgroundColor Red
    }

If (($_ -Like "Password Never Expires*") -and ($BuildUp_01.PasswordNeverExpires -ne $True)){


    If (($_ -match "Expiration") -and ($BuildUp_01.AccountExpirationDate  -ne $null)){
    Write-Host " " $_ -ForegroundColor White -BackgroundColor Red
    }

    If ($_ -match ("Password Last Set")){
    Write-Host " " $_ -NoNewline
        If (($BuildUp_01.PasswordLastSet) -eq $null) {Write-Host "Just a few minutes ago..." -ForegroundColor Magenta}
            If (($BuildUp_01.PasswordLastSet) -ne $null) {
    Write-Host " [$( ( (Get-Date)-($BuildUp_01.PasswordLastSet) ).Days ) day(s), $(((Get-Date)-($BuildUp_01.PasswordLastSet) ).Hours) hour(s), $(((Get-Date)-($BuildUp_01.PasswordLastSet) ).Minutes) minute(s) ago]"  -ForegroundColor Yellow
    Write-Host "  Max Password Age    : " -No 
    Write-Host "$((Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days) days " -fore 10 -No
    If ($(((Get-Date)-($BuildUp_01.PasswordLastSet)).TotalDays) -ge 60) { Write-Host "<EXPIRED>" -fore 12 -Back 0 }
    Else { Write-Host ""}
    # Write-Host " ($(((Get-Date)-($BuildUp_01.PasswordLastSet)).Days) days ago)" -ForegroundColor Yellow
    }
}
    }


}
If ($host.name -eq "ConsoleHost") {Write-Host "`n"}
Set-Clipboard $null
$ErrorActionPreference = $EAP 

} # END Function Office {

set-alias -name ofc -value Office
