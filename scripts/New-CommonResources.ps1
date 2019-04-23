param (
    [Parameter(Mandatory = $true)]
    [string]  $prefix,
    [Parameter(Mandatory = $true)]
    [string]  $project,
    [Parameter(Mandatory = $false)]
    [string]  $location = "westeurope"    
)

$resourceGroup = $prefix + "-$project-rg"
$keyvaultname = $prefix + "-$project-keyvault"
$bootdiagStorageName = $prefix + $project + "bootdiag"

# Create ResourceGroup
$rg = New-AzResourceGroup -Name $resourceGroup -Location $location

#Create Keyvault
$keyvault = New-AzKeyvault -Name $keyvaultname -ResourceGroupName $resourceGroup -Location $location -Sku Standard

#Create BootDiagnostics Storage
$bootdiagstorage = New-AzStorageAccount -Name $bootdiagStorageName -ResourceGroupName $resourceGroup -SkuName Standard_LRS -Location $location
