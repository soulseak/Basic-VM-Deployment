[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [string]  $prefix,
    [Parameter(Mandatory = $true)]
    [string]  $project,
    [Parameter(Mandatory = $false)]
    [string]  $location = "westeurope",
    [Parameter(Mandatory = $false)]
    [int]  $vmCount = 1,
    [Parameter(Mandatory = $false)]
    [switch]  $JoinDomain,
    [Parameter(Mandatory = $false)]
    [switch]  $EnableBackup,
    [Parameter(Mandatory = $false)]
    [switch]  $InstallNotePad,
    [Parameter(Mandatory = $true)]
    [string] $subnetId,
    [Parameter(Mandatory = $true)]
    [string] $vmSize
)

function New-Password {
    return (([char[]]([char]65..[char]90)) + ([char[]]([char]97..[char]122)) + 0..9 + 0..9 | Sort-Object { Get-Random })[0..16] -join ''
}

# Variables for common values

$resourceGroupName = $prefix + "-$project-rg"
$avaiabilitysetName = $prefix + "-$project-avs"
$keyvaultname = $prefix + "-$project-keyvault"
$bootdiagStorageName = $prefix + $project + "bootdiag"

#region Create Availabiliy Set
Write-Host "Deploy Availability set $availabilitysetName"
$avaiabilityset = New-AzAvailabilitySet -ResourceGroupName $resourceGroupName -Name $avaiabilitysetName -Location $location -Sku Aligned -PlatformUpdateDomainCount 2 -PlatformFaultDomainCount 2

#endregion Create Availabiliy Set

[System.Collections.Arraylist] $vms = @{ }

for ($i = 1; $i -le $vmCount; $i++) {
    #region Define VM Name
    $count = $('{0:d3}' -f $i )
    $vmName = $prefix + "-" + $project + $count
    #endregion Define VM Name

    #region Create and Store Secret in Vault
    
    Write-Host "Generate Password and Store it"
    $Password = New-Password
    $secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
    $secret = Set-AzKeyVaultSecret -VaultName $keyvaultname -Name ("$vmName-localadmin") -SecretValue $secpasswd

    #Create Secret Variable for vm Deployment
    $cred = New-Object System.Management.Automation.PSCredential ("localadmin", $secpasswd)
    #endregion Create Secret in Vault

    #region Network
    # Create a public IP address and specify a DNS name
    Write-Host "Generate Public IP"
    $pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location `
        -Name $($vmName + $(Get-Random)) -AllocationMethod Static -IdleTimeoutInMinutes 4


    Write-Host "Geneate NIC"
    # Create a virtual network card and associate with public IP address and NSG
    $nic = New-AzNetworkInterface -Name $($vmName + "-nic") -ResourceGroupName $resourceGroupName -Location $location `
        -SubnetId $subnetId -PublicIpAddressId $pip.Id

    #Make IP Static
    $Nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
    $NIC = Set-AzNetworkInterface -NetworkInterface $Nic
    #endregion network

    #region create VM
    # Create a virtual machine configuration
    Write-Host "Deploy VM $vmName"
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avaiabilityset.Id | `
        Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
        Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest | `
        Add-AzVMNetworkInterface -Id $nic.Id | `
        Set-AzVMBootDiagnostics -Enable -StorageAccountName $bootdiagStorageName -ResourceGroupName $resourceGroupName

    # Create a virtual machine
    $vmJob = New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig -AsJob

    #endregion craete vm

    $tempVM = [PSCustomObject]@{
        Name     = $vmName
        PublicIP = $pip.IpAddress
        LocalIP  = $nic.IpConfigurations[0].PrivateIpAddress
        User     = "localadmin"
        Password = $Password
    }
    $vms.Add($tempVM) | Out-Null
} #for i -le vmcount

#Wait for all Deployments to Finish
Write-Host "Wait for Deployments to finish"
Get-Job | Wait-Job

foreach ($vmName in $vmNames) {
    if ($InstallNotePad) {
        Write-Host "Install NotePad on $vmName"
        .\Install-MSI.ps1 -vmName $vmName -ResourceGroupName $resourceGroupName -scriptPath ".\installnotepad.ps1"
    }

    if ($JoinDomain) {
        Write-Host "Join Domain on $vmName"
        .\Join-Domain.ps1 -vmName $vmName -ResourceGroupName $resourceGroupName
    }
  
    if ($EnableBackup) {
        Write-Host "Enable Backup on $vmName"
        .\Set-VMBackup.ps1 -vmName $vmName -ResourceGroupName $resourceGroupName
    }
}

return $vms

