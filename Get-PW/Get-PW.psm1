Function Get-PW {
$Location = "SV" # or "VA", or "MI"

Write-Host "
Enter a USERNAME:" -NoNewline -ForegroundColor Cyan -BackgroundColor DarkMagenta
Write-Host " " -NoNewline
$UserName = (Read-Host).Trim()

$EAP = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"

$DateArray = @()

$line = ($_).Split(',')
(Get-ADDomainController -filter *).Hostname | ? {$_ -match $Location -or $_ -match "az"} | % {
$Server = ($_).ToUpper()
Write-Host "~~~~~~~~~~~~~~~~~" -ForegroundColor Yellow
Write-Host " ($Server)" -ForegroundColor Cyan
$BuildUp_01 = $null
$lockoutPolicy = $null
$GeneratePW = $null
$ErrorActionPreference = "SilentlyContinue"
$PingIt = $null
$PingIt = Test-Connection $Server -count 1 -ErrorAction SilentlyContinue
    If (!$PingIt){
    $PingIt = Test-Connection $Server -count 2 -ErrorAction SilentlyContinue
    }
If (!$PingIt){
Write-Host "  $Server did not respond..." -ForegroundColor Yellow -BackgroundColor Black}

$ErrorActionPreference = "SilentlyContinue"
$BuildUp_01 = get-aduser -Server $Server $UserName -Properties PasswordLastSet,LastLogonDate,PasswordExpired,Modified,lockoutTime,LockedOut,telephoneNumber,ipphone,officephone,whenChanged,CanonicalName,AccountExpirationDate 
$UPN = $BuildUp_01.UserPrincipalName
$CanonicalName = $BuildUp_01.CanonicalName
If ((!$BuildUp_01) -and ($PingIt)) { 
Write-Host "   " -NoNewline
Write-Host " $(($UserName).ToUpper()) was not found " -ForegroundColor DarkMagenta -BackgroundColor Yellow
}

If (($BuildUp_01) -and ($PingIt)) {
$BuildUp_01_lockoutTime = $BuildUp_01.lockoutTime #132101020387799683
If ($BuildUp_01_lockoutTime -gt 0) {$BuildUp_01_lockoutTime = [datetime]::FromFileTime($($BuildUp_01_lockoutTime))}
$DateArray = $DateArray + $BuildUp_01.PasswordLastSet
#$DateArray = $DateArray + $BuildUp_01.whenChanged
($BuildUp_01 | select -Property `
@{name="Name";expression={$_.Name}},` 
@{name="Lockout time";expression={$BuildUp_01_lockoutTime}},` 
@{name="Locked out";expression={$BuildUp_01.LockedOut}},` 
@{name="Expiration";expression={$BuildUp_01.AccountExpirationDate}},` 
@{name="Password Last Set";expression={$_.PasswordLastSet}},` 
@{name="Password Expired";expression={$_.PasswordExpired}},` 
@{name="Last Logon";expression={$BuildUp_01.LastLogonDate}},`  
@{name="Object last changed";expression={$_.whenChanged}} | fl | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries) | % {

#Write-Host "$_" -ForegroundColor Green

    If ($_ -match "Name"){
    Write-Host "  $_  ($($UserName.ToUpper()))" }

    If ($_ -match "Last Logon"){
    Write-Host "  $_" }

    If ($_ -match "Lockout time"){
    If (($_ -NOTlike "*: 0") -and ($BuildUp_01.LockedOut -eq $true)){
    $lockout = 1
    $lockoutPolicy = 1
    Write-Host " " $_ 
    $LockOutTime = $BuildUp_01_lockoutTime
    }}

    If (($_ -match "Locked out") -and ($BuildUp_01.LockedOut -eq $true)){
    Write-Host " " $_ -ForegroundColor White -BackgroundColor Red
    $lockout = 0}

    If (($_ -match "Expiration") -and ($BuildUp_01.AccountExpirationDate -ne $null)){
    Write-Host " " $_ -ForegroundColor White -BackgroundColor Red
    }

    If ($_ -match "Password Expired    : True"){
    $ExpiredPW = 1
    $GeneratePW = 1 }

    If ($_ -match ("Password Last Set")){
    Write-Host " " $_ -NoNewline
        If (($BuildUp_01.PasswordLastSet) -eq $null) {Write-Host "Just a few minutes ago..." -ForegroundColor Magenta}
            If (($BuildUp_01.PasswordLastSet) -ne $null) {
    Write-Host " [$( ( (Get-Date)-($BuildUp_01.PasswordLastSet) ).Days ) day(s), $(((Get-Date)-($BuildUp_01.PasswordLastSet) ).Hours) hour(s), $(((Get-Date)-($BuildUp_01.PasswordLastSet) ).Minutes) minute(s) ago]"  -ForegroundColor Yellow
    # Write-Host " ($(((Get-Date)-($BuildUp_01.PasswordLastSet)).Days) days ago)" -ForegroundColor Yellow
    }
    }

    If (($_ -match "Password Expired") -and ($ExpiredPW -eq 1)){
    Write-Host " " $_ -ForegroundColor White -BackgroundColor Red #-NoNewline
    #If (($BuildUp_01.PasswordLastSet) -eq $null) {Write-Host "Just a few minutes ago..." -ForegroundColor Magenta}
        If (($BuildUp_01.PasswordLastSet) -ne $null) {
            Write-Host "  (Expired $(((Get-Date)-(($BuildUp_01.PasswordLastSet).AddDays(90))).Days) days ago:" -ForegroundColor Magenta -NoNewline
        Write-Host " $((($BuildUp_01.PasswordLastSet).AddDays(90).ToString("dd MMM yyyy")))" -ForegroundColor Yellow -NoNewline
        Write-Host ")" -ForegroundColor Magenta
        }
    $ExpiredPW = 0}

    If ($_ -match "Object last changed"){Write-Host " " $_ -ForegroundColor Green}
}
} #End - if null
}
Write-Host "~~~~~~~~~~~~~~~~~" -ForegroundColor Yellow
$SyncReport = 0
function Date-Range {
    BEGIN { $script:earliest = $null
            $script:latest = $null }
    PROCESS {
            $ErrorActionPreference = "SilentlyContinue"
            if (($_ -ne $null) -and (($earliest -eq $null) -or ($_ -lt $earliest))) {
                $script:earliest = $_ }
            if (($_ -ne $null) -and (($latest -eq $null) -or ($_ -gt $latest))) {
                $script:latest = $_ }
    }
    
    END { Write-Host "    Newest PW Δ: $($latest.ToString('dd MMM yyyy, h:mm tt'))"
          Write-Host "    Oldest PW Δ: $($earliest.ToString('dd MMM yyyy, h:mm tt'))" 
          $script:Difference = [math]::Round((($latest - $earliest).TotalMinutes),1)

          If ($Difference -le 120) {
          Write-Host "       " -NoNewline
          Write-Host " Difference: $Difference minutes " -ForegroundColor Green -BackgroundColor Black
          }

          If (($Difference -gt 120) -and ($Difference -le 1440)) {         
          Write-Host "       " -NoNewline
          Write-Host " Difference: $([math]::Round((($Difference/60/24)),2)) hours " -ForegroundColor Green -BackgroundColor Black
          }
          If ($Difference -gt 1440) {          
          Write-Host "       " -NoNewline
          Write-Host " Difference: $([math]::Round((($Difference/60/24)),2)) days " -ForegroundColor Green -BackgroundColor Black
          $script:SyncReport = 1
          }
        }
}

$DateArray | Date-Range
Write-Host "~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
$DefaultPW_Policy = Get-ADDefaultDomainPasswordPolicy
If ($lockoutPolicy -gt 0) {
Write-Host " Domain lockout duration: $((($DefaultPW_Policy).LockoutDuration.TotalMinutes)) minutes " -ForegroundColor Yellow -BackgroundColor Red
Write-Host "   " -NoNewline
Write-Host " Locked out $((((get-date) -  $LockOutTime)).Minutes) minutes ago. "  -ForegroundColor Black -BackgroundColor White
}

If (!($lockoutPolicy -gt 0)) {
Write-Host "      Bad passwords allowed: $((($DefaultPW_Policy).LockoutThreshold)) tries. " -ForegroundColor Yellow
Write-Host "    Domain lockout duration: $((($DefaultPW_Policy).LockoutDuration.TotalMinutes)) minutes. " -ForegroundColor Yellow
Write-Host " Passsword length (minimum): $((($DefaultPW_Policy).MinPasswordLength)) Characters. " -ForegroundColor Yellow
Write-Host "     Password age (maximum): $((($DefaultPW_Policy).MaxPasswordAge.TotalDays)) days. " -ForegroundColor Yellow
}
Write-Host "~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
##################################################
} # END Function Get-PW

set-alias -name gpw -value Get-PW