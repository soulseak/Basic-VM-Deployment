# Variables for common values
$prefix = "bsflo"
$project = "uno"
$location = "westeurope"
$vmCount = 2
<# Get Available VM Sizes
Get-AzVMSize -Location "westeurope" | Where-Object {$_.Name -like "Standard_D*s*"} | Sort-Object MemoryInMB
#>
$vmSize = "Standard_D2s_v3"

$vn = Get-AzVirtualNetwork
$sn = $vn.Subnets | Where-Object {$_.Name -eq "bsflo-production-subnet"}

.\scripts\New-CommonResources.ps1 -prefix $prefix -project $project -Location $location 
$vms = .\scripts\New-VMs.ps1 -Location $location -prefix $prefix -project $project -vmSize $vmSize `
                      -subnetId $sn.id -vmCount $vmCount -JoinDomain $true -EnableBackup $true -InstallNotePad $true
$vms | ft