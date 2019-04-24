[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [string] $scriptpath,
    
    [Parameter(Mandatory = $true)]
    [string] $vmName,
    
    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName
)
    
#Install MSI
    
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath .\scripts\installnotepad.ps1


