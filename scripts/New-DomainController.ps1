# Create Domain Controller

$password = "MySecurePW01" | ConvertTo-SecureString -Force -AsPlainText


Install-windowsfeature AD-domain-services
Install-WindowsFeature RSAT-ADDS

Import-Module ADDSDeployment

Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "mydomain.local" `
    -DomainNetbiosName "dc01" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $password `
    -Force:$true

New-ADUser -Name domainjoinuser `
    -GivenName "Domainjoinuser" `
    -Surname "Domainjoinuser" `
    -SamAccountName  "Domainjoinuser" `
    -AccountPassword (ConvertTo-SecureString "MeinS3curePassw0rd" -AsPlainText -force) -Enabled $true


#give create rights on computer out