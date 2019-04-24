[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String] $vmName,
    [Parameter(Mandatory = $true)]
    [String] $resourceGroupName
)
# Parameter help description

$vault = Get-AzRecoveryServicesVault
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $vault.id | Where-Object Name -eq $policy
$context = Set-AzRecoveryServicesVaultContext -Vault $vault

$BackupProtection = Enable-AzRecoveryServicesBackupProtection -Policy ProductionPolicy -Name $vmName -ResourceGroupName $resourceGroupName