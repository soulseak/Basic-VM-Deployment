param {
    [Parameter(Mandatory = $true)]
    [string] $scriptpath
    
    [Parameter(Mandatory = $true)]
    [string] $vmName
    
    [Parameter(Mandatory = $true)]
    [string] $resourceGroup
    
}
    
#Install MSI
    
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath .\installnotepad.ps1


