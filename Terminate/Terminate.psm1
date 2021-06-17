Function Termintate {
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
if ($Who -eq "x") {Write-Host " - Exiting..."; break}
If ($Who) {$Who = "$(($Who).Trim())"}

If (!$Who) {Write-host "Nothing to look for / Nothing entered." -ForegroundColor Yellow -BackgroundColor Black; break}
$Quality = 0
If ($Who -NOTmatch " " -and $Who -NOTmatch "@") { $Quality = 1; Write-Host "Looking for this username: $Who" -ForegroundColor Cyan }
If ($Who -match "@") { $Quality = 2; Write-Host "Looking for this email adddress: $Who" -ForegroundColor Cyan }
If ($Who -match " ") { $Quality = 3; Write-Host "Looking for this name: $Who" -ForegroundColor Cyan }

Function ADU1 {
$ErrorActionPreference = "SilentlyContinue"
Get-ADUser -filter * -Properties EmailAddress
$ErrorActionPreference = "Continue"
}; $Output = $null
If ($Quality -eq 1) { $Output = ADU1 | ? {$_.SamAccountName -match $Who} }
If ($Quality -eq 2) { $Output = ADU1 | ? {$_.EmailAddress -match $Who} }
If ($Quality -eq 3) { $Output = ADU1 | ? {$_.Name -match $Who} }

If (!$Output) {Write-host "`'$Who`' is not valid." -ForegroundColor Yellow -BackgroundColor Black
Set-Clipboard $null
Term
}
$OutputSamAccountName = $Output.SamAccountName
#### Expire the account (but do not disable it) - So it cannot be logged into at all!
[nullable]$AcctExpDate = $null
#[nullable]$ExpDate = $null
$WhatDoin = $null
Write-Host "
For $($Output.Name)  / $($Output.EmailAddress)
  Hit 'ENTER' for NOW, EOD for 'end-of-day, or -"  -ForegroundColor Cyan
$ErrorActionPreference = "SilentlyContinue" # because if you hit 'enter' / 'NOW' - the empty value cant be converted to datetime - Supress that error
Write-Host "   Enter TERMINATION DATE (ie: 05/22/2020 00:00): " -ForegroundColor Yellow -NoNewline
$ExpDate = Read-Host

Function dating {Get-Date ( Get-Date -Hour 0 -Minute 0 -Second 0)}
Function confirm {
    Write-Host "Setting an expiry of $($AcctExpDate)`n`tOn: $($Output.Name)  / $($Output.EmailAddress)" -ForegroundColor Green
    Write-Host "Type 'Y' to confirm: " -NoNewline -ForegroundColor Cyan; $Confirm = Read-Host; If ($Confirm -ne "y") {Write-Host "'Y' was not entered... Exiting!" -ForegroundColor Yellow -BackgroundColor Black; break } }
Function Expire {Set-ADAccountExpiration -Identity $OutputSamAccountName -DateTime $AcctExpDate
    Write-Host "Waiting 5 seconds..."; Start-Sleep -Seconds 5
    $script:GetExpDt = (Get-ADUser $OutputSamAccountName -Properties AccountExpirationDate).AccountExpirationDate}

If ($ExpDate -match "/" -and $ExpDate -ne "") {$Period = "LATER"; [datetime]$AcctExpDate = $ExpDate; $AcctExpDate = $AcctExpDate.AddHours(17) }
If ($ExpDate -eq "EOD") {$Period = "EOD"; [datetime]$AcctExpDate = (dating).AddHours(17) }
If ($ExpDate -eq "") {$Period = "NOW"; [datetime]$AcctExpDate = (dating).AddDays(-1) }
$ErrorActionPreference = "Continue"

Try {[datetime]$AcctExpDate | Out-Null}
Catch {Write-Host "`"$ExpDate`" Not a valid DateTime... 
(ie: 05/22/2020 00:00) 
Exiting"
break
}

# Period: NOW , EOD , LATER
If ($Period -eq "EOD") {
Write-Host "The End of today...."
confirm
Expire
}

If ($Period -eq "LATER") {
Write-Host "This is in the future....)"
confirm
Expire
}

If ($Period -eq "NOW") {
Write-Host "Expiring the account NOW..."
confirm
Expire
$WhatDoin = "PassScramble"
Write-Host "Confirming expiry date: $($GetExpDt)"
Write-Host "   So, at the 'End of': $(((Get-Date ($AcctExpDate).AddDays(-1) -DisplayHint Date)  | Out-String).Trim())"
Write-Host "Continuing to password change...
"
}

If ($Period -ne "NOW") {
Write-Host "Confirming expiry date: $($GetExpDt)"
Write-Host "   So, at: $(((Get-Date ($($GetExpDt)) -DisplayHint Time) `
| Out-String).Trim()), on, $(((Get-Date ($($GetExpDt)) -DisplayHint Date) `
| Out-String).Trim())..." -ForegroundColor Black -BackgroundColor Cyan
Write-Host "     - The account will still exist. But after this date and time, login to the account is no longer possible." -ForegroundColor Black -BackgroundColor Cyan
Write-Host "Exiting - No passwords are changed..." -ForegroundColor Yellow
}


#Write-Host " Password scramble, or Azure Sync?" -ForegroundColor Yellow
#Write-Host " 'PP' for password scramble - any other key for just Azure sync..." -ForegroundColor Black -BackgroundColor White
#$WhatDoin = Read-Host

If ($WhatDoin -eq "PassScramble") {
# GeneratePassword() takes two arguments: 
## The first sets the length of the password. 
## The second sets the number of non-alphanumeric characters that you want in it.
    Add-Type -AssemblyName System.web
    $PasswordArray = (1..10 | % { [System.Web.Security.Membership]::GeneratePassword(14, 4) })
$PasswordBlowout = $null
$PasswordBlowout = Set-ADAccountPassword -Identity $OutputSamAccountName -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $($PasswordArray | Get-Random) -Force) -PassThru
            If ($PasswordBlowout) {
            Write-Host " Password has been changed, and the account expired on the " -ForegroundColor Yellow -NoNewline
            Write-Host "'$($PasswordBlowout.Name)' ($(($PasswordBlowout.SamAccountName).ToUpper()))" -ForegroundColor Yellow -BackgroundColor DarkMagenta -NoNewline
            Write-Host " account... "  -ForegroundColor Yellow
            }
            If (!($PasswordBlowout)) {
            Write-Host " Something went wrong with the password reset... " -ForegroundColor Yellow -BackgroundColor DarkRed
            }
#### END Password blow out
} # END If ($WhatDoin -eq "pp") 

<#
# Sync ActiveDirectory and Azure
     	Write-Host "Connecting to Azure..." -ForegroundColor Yellow

		Write-Host "Initializing Azure AD Delta Sync..." -ForegroundColor Yellow
		Invoke-Command -ComputerName bpsbl-azure01 {Start-ADSyncSyncCycle -PolicyType Delta}


		#Display a progress indicator and hold up the rest of the script while the sync completes.
		Write-Host "Checking Azure AD Delta Sync Status..." -ForegroundColor Yellow
		Invoke-Command -ComputerName bpsbl-azure01 {
        While(Get-ADSyncConnectorRunStatus){
		Write-Host "." -NoNewline
		Start-Sleep -Seconds 1
		}
		}

Do {
$ADSyncSchedule = Invoke-Command -ComputerName bpsbl-azure01 {Get-ADSyncScheduler}
} While ($ADSyncSchedule.SyncCycleInProgress -eq $True)

If ($ADSyncSchedule.SyncCycleInProgress -eq $False)
{
$NextAD_Azure_SyncLocal = $ADSyncSchedule.NextSyncCycleStartTimeInUTC.AddHours(([System.TimeZoneInfo]::FindSystemTimeZoneById((Get-WmiObject win32_timezone).StandardName)).BaseUtcOffset.Hours) 
If ((Get-Date).IsDaylightSavingTime()){
$NextAD_Azure_SyncLocal = $NextAD_Azure_SyncLocal.AddHours(1)
}

$TimeZone = (Get-WmiObject win32_timezone).StandardName

Write-Host "Synch completed." -ForegroundColor Yellow
Write-Host "Next Synch: " -NoNewline
Write-Host "$NextAD_Azure_SyncLocal ($TimeZone)" -ForegroundColor Yellow
}
#$ADSyncSchedule | select CurrentlyEffectiveSyncCycleInterval,SyncCycleEnabled | fl
($ADSyncSchedule | select @{name="Sync Interval";expression={$_.CurrentlyEffectiveSyncCycleInterval}},@{name="Sync Enabled";expression={$_.SyncCycleEnabled}}).PSObject.Properties   | % {
Write-Host "   $($_.Name): " -NoNewline
If ($_.Value.Minutes) {Write-Host $_.Value.Minutes -ForegroundColor Yellow}
If (!($_.Value.Minutes)) {Write-Host $_.Value -ForegroundColor Yellow}
}
#>
} # END Function Term {

set-alias -name term -value Termintate

