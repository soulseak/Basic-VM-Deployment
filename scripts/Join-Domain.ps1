[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]  $vmName,
    [Parameter(Mandatory = $true)]
    [string]  $resourceGroupName
)
#Domain Join
$prefBackup = $WarningPreference
$WarningPreference = 'SilentlyContinue'
Restart-AzVM -Name $vmName -ResourceGroupName $resourceGroupName
$WarningPreference = $prefBackup

#DomainJoin Credentials
$mydomain = "mydomain.local"
$domainjoinuser = "domainjoinuser"

$secret = Get-AzKeyVaultSecret -VaultName bsflo-domain-keyvault -Name domainjoinuser
$domainjoinuserPassword = $secret.SecretValueText

$settings = '{
 "Name": "' + $mydomain + '",
 "User": "' + $mydomain + '\\' + $domainjoinuser + '",
 "Restart": "true",
 "Options": "3" 
}'

$protectedSettings = '{ "Password": "' + $domainjoinuserPassword + '" }'

$extension = Set-AzVMExtension -ResourceGroupName $resourceGroupName -ExtensionType "JsonADDomainExtension" `
    -Name "joindomain" -Publisher "Microsoft.Compute" -TypeHandlerVersion "1.0" `
    -VMName $VmName -Location $location -SettingString $Settings -ProtectedSettingString $protectedSettings

$WarningPreference = 'SilentlyContinue'
Restart-AzVM -Name $vmName -ResourceGroupName $resourceGroupName
$WarningPreference = $prefBackup