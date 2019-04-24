[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String] $vmName,
    [Parameter(Mandatory = $true)]
    [String] $resourceGroup,
    [Parameter(Mandatory = $false)]
    [String] $policy = "ProductionPolicy"
)
# Parameter help description

$vault = Get-AzRecoveryServicesVault
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $vault.id | Where-Object Name -eq $policy
$context = Set-AzRecoveryServicesVaultContext -Vault $vault

$BackupProtection = Enable-AzRecoveryServicesBackupProtection -Policy $policy -Name $vmName -ResourceGroupName $resourceGroup