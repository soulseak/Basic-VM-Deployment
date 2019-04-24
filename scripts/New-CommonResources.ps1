[CmdletBinding()]
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
Write-Host "Deploy ResourceGroup $resourceGroup"
$rg = New-AzResourceGroup -Name $resourceGroup -Location $location

#Create Keyvault
Write-Host "Deploy Keyvault $Keyvaultname"
$keyvault = New-AzKeyvault -Name $keyvaultname -ResourceGroupName $resourceGroup -Location $location -Sku Standard

Write-Host "Deploy Storage for Bootdiag $boodiagStorageName"
#Create BootDiagnostics Storage
$bootdiagstorage = New-AzStorageAccount -Name $bootdiagStorageName -ResourceGroupName $resourceGroup -SkuName Standard_LRS -Location $location
