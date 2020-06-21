$resourceGroup = "SourceRG"
$location = "South Central US"
$vmName = "myVM1"
$AvailabilitySetName = "AvailabilitySetTest"
$vnetname = "SourceVnet"
$VnetRG = "SourceVnetRG"

New-AzResourceGroup -Name $resourceGroup -Location $location
New-AzAvailabilitySet -Name $AvailabilitySetName -ResourceGroupName $resourceGroup -Location $location -PlatformFaultDomainCount 1 -PlatformUpdateDomainCount 1 -Sku "Aligned"
 
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."
$vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $VnetRG
$nic = New-AzNetworkInterface -Name "myNic1" -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[0].Id
$AvailabilitySet = Get-AzAvailabilitySet -ResourceGroupName $resourceGroup -Name $AvailabilitySetName
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_B1s" -AvailabilitySetID $AvailabilitySet.Id | Set-AzVMOperatingSystem -Linux  -ComputerName "myVM" -Credential $cred | Set-AzVMSourceImage -PublisherName "SUSE" -Offer "SLES" -Skus "12-sp4-gen2" -Version "latest" | Add-AzVMNetworkInterface -Id $nic.Id
$vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig
$diskConfig = New-AzDiskConfig -SkuName "Premium_LRS" -Location $location -CreateOption Empty -DiskSizeGB 128
$dataDisk1 = New-AzDisk -DiskName $vmName-"datadisk" -Disk $diskConfig -ResourceGroupName $resourceGroup
$vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
$vm = Add-AzVMDataDisk -VM $vm -Name $vmName-"datadisk" -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
Update-AzVM -VM $vm -ResourceGroupName $resourceGroup
