Function MSConnect {

$Pw = mypwd

If ($host.Name -match "Console") {
Function Trying {Write-Host "Attempting to connect to 'ExchangeOnline' and 'MsolService'..." -Fore Yellow -Back DarkRed}
Function Connected {Write-Host "'ExchangeOnline' and 'MsolService' are connected." -Fore Yellow -Back DarkGreen}
}

If ($host.Name -match "ISE") {
    Function Trying {
        $ErrFgCol = (((((($host.privatedata) | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries))[13]).Split(':'))[1]).Trim()
        $ErrBgCol = (((((($host.privatedata) | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries))[14]).Split(':'))[1]).Trim()
        $host.PrivateData.ErrorForegroundColor  = '#FFFF8C00'
        $host.PrivateData.ErrorBackgroundColor  = '#FF7B00FF'
        $host.UI.WriteErrorLine('▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒')
        $host.UI.WriteErrorLine("Attempting to connect to 'ExchangeOnline' and 'MsolService'...")
        $host.UI.WriteErrorLine('▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒')
        $host.PrivateData.ErrorForegroundColor  = $ErrFgCol # Set the color ErrorForegroundColor to its default - Red / '#FFFF0000'
        $host.PrivateData.ErrorBackgroundColor  = $ErrBgCol # Set the ErrorBackgroundColor back to its default - White / '#00FFFFFF'
    }
Function Connected {
        $ErrFgCol = (((((($host.privatedata) | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries))[13]).Split(':'))[1]).Trim()
        $ErrBgCol = (((((($host.privatedata) | Out-String).Split("`n|`r",[System.StringSplitOptions]::RemoveEmptyEntries))[14]).Split(':'))[1]).Trim()
        $host.PrivateData.ErrorForegroundColor  = '#FFFFD800'
        $host.PrivateData.ErrorBackgroundColor  = '#FFAA3F3F'
        $host.UI.WriteErrorLine('▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒')
        $host.UI.WriteErrorLine("'ExchangeOnline' and 'MsolService' are connected.")
        $host.UI.WriteErrorLine('▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒')
        $host.PrivateData.ErrorForegroundColor  = $ErrFgCol # Set the color ErrorForegroundColor to its default - Red / '#FFFF0000'
        $host.PrivateData.ErrorBackgroundColor  = $ErrBgCol # Set the ErrorBackgroundColor back to its default - White / '#00FFFFFF'
}
}

If (!(Get-MsolCompanyInformation -ErrorAction SilentlyContinue)) {
Trying
$Admin_username = ([adsi]"LDAP://$(whoami /fqdn)").mail
$Admin_password = ConvertTo-SecureString "$Pw" -AsPlainText -Force
$Credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $Admin_username, $Admin_password
Connect-ExchangeOnline -ShowBanner:$false -Credential $Credentials 
Connect-MsolService -Credential $Credentials 
}
If (Get-MsolCompanyInformation -ErrorAction SilentlyContinue) {
Connected
}

} # END Function MSConnect {

set-alias -name msc -value MSConnect