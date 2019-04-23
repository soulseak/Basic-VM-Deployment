# Variables for common values
$prefix = "bsflo"
$project = "pro01"
$resourceGroup = $prefix + "-$project-rg"
$location = "westeurope"
$vmName = $prefix + "-$project"
$nsgName = $prefix + "-$project-nsg"
$avaiabilitysetName = $prefix + "-$project-avs"
$keyvaultname = $prefix + "-$project-keyvault"
$bootdiagStorageName = $prefix + $project + "bootdiag"

$vmcount = 1

#DomainJoin Credentials
$mydomain = "mydomain.local"
$domainjoinuser = "domainjoinuser"
<# Generate new Passwordfile
$password = "MeinS3curePassw0rd"
$secpw = ConvertTo-SecureString $password -AsPlainText -Force
$secpw | ConvertFrom-SecureString | Set-Content domainpw.secret
#>

$secpw = Get-Content domainpw.secret | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secpw)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$domainjoinuserPassword = $UnsecurePassword

<#
Get-AzVMSize -Location "westeurope" | Where-Object {$_.Name -like "Standard_D*s*"} | Sort-Object MemoryInMB
#>
$vmSize = "Standard_D2s_v3"

$subnetId = "/subscriptions/6edb6b85-26e7-4646-b853-2db8bc690aa3/resourceGroups/bsflo-core-rg/providers/Microsoft.Network/virtualNetworks/bsflo-core-vnet/subnets/bsflo-production-subnet"

# Create a resource group
$rg = New-AzResourceGroup -Name $resourceGroup -Location $location

#Create Keyvault and Credentials

New-AzKeyvault -Name $keyvaultname -ResourceGroupName $resourceGroup -Location $location -Sku Standard

$Password = (([char[]]([char]65..[char]90)) + ([char[]]([char]97..[char]122)) + 0..9 + 0..9 | Sort-Object {Get-Random})[0..16] -join ''
$secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyvaultname -Name ("$vmName-localadmin") -SecretValue $secpasswd

$cred = New-Object System.Management.Automation.PSCredential ("localadmin", $secpasswd)


# Create Availabiliy Set

$avaiabilityset = New-AzAvailabilitySet -ResourceGroupName $resourceGroup -Name $avaiabilitysetName -Location $location -Sku Aligned -PlatformUpdateDomainCount 2 -PlatformFaultDomainCount 2

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name $($vmName + $(Get-Random)) -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -Name $($vmName + "-nic") -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $subnetId -PublicIpAddressId $pip.Id

$bootdiagstorage = New-AzStorageAccount -Name $bootdiagStorageName -ResourceGroupName $resourceGroup -SkuName Standard_LRS -Location $location

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avaiabilityset.Id | `
Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest | `
Add-AzVMNetworkInterface -Id $nic.Id | `
Set-AzVMBootDiagnostics -Enable -StorageAccountName $bootdiagstorage.StorageAccountName -ResourceGroupName $bootdiagStorage.ResourceGroupName

# Create a virtual machine
$job = New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig -AsJob

$job | Wait-Job
<# Connect VM
$machinename = $pip.IpAddress
Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$machinename"
#>

<# Create Domain Controller
Make Domain Controller
Install-windowsfeature AD-domain-services
Install-WindowsFeature RSAT-ADDS

Import-Module ADDSDeployment

$password = "MySecurePW01" | ConvertTo-SecureString -Force -AsPlainText


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
#>

restart-azvm -Name $vmName -ResourceGroupName $resourceGroup

$settings = '{
 "Name": "' + $mydomain + '",
 "User": "' + $mydomain + '\\' + $domainjoinuser + '",
 "Restart": "true",
 "Options": "3" 
}'

$protectedSettings = '{ "Password": "' + $domainjoinuserPassword + '" }'

Set-AzVMExtension -ResourceGroupName $resourceGroup -ExtensionType "JsonADDomainExtension" `
                  -Name "joindomain" -Publisher "Microsoft.Compute" -TypeHandlerVersion "1.0" `
                  -VMName $VmName -Location $location -SettingString $Settings -ProtectedSettingString $protectedSettings

                  
restart-azvm -Name $vmName -ResourceGroupName $resourceGroup


Write-Output $pip.IpAddress
Write-Output "localadmin"
Write-Output $Password
Write-Output "mydomain.local\meinbenutzer"
