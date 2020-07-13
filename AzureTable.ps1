$StorageAccountName = ""
$SourceRG = ""
$TableName = ""
$PartitionKey = ""

$StorageAccount =  Get-AzStorageAccount -ResourceGroupName $SourceRG  -Name $StorageAccountName
$ctx = $StorageAccount.context
$CloudTable = (Get-AzStorageTable –Name $TableName –Context $ctx).CloudTable

$vms = Get-AzVM

foreach ($vm in $vms) {
    $vmd = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
    $NicName = $vmd.networkprofile.networkinterfaces.id.split('/')[8]
    $Nic = Get-AzNetworkInterface -Name $NicName
    $PubIpName = $nic1.IpConfigurations.PublicIpAddress.id.split('/')[8]
    $PubIp = (Get-AzPublicIpAddress -Name $PubIpName).IpAddress
    $rg = Get-AzResourceGroup -Name $vmd.ResourceGroupName
    $sapsid = (Get-AzTag -ResourceId $rg.ResourceId).Properties.TagsProperty.sapsid
    $Deployuser = (Get-AzTag -ResourceId $rg.ResourceId).Properties.TagsProperty.Deployuser
    Add-StorageTableRow -table $cloudtable -partitionKey $PartitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{
    "ResourceGroupName"=$vmd.ResourceGroupName;
    "Name"=$vmd.Name;
    "Location"=$vmd.Location;
    "ProvisioningState"=$vmd.ProvisioningState
    "SkuSize"=$vmd.hardwareprofile.vmsize
    "PublicIpAddress"=$PubIp
    "PrivateIpAddress"=$Nic.IpConfigurations.PrivateIpAddress
    "SubnetName"=$Nic.IpConfigurations.subnet.id.split('/')[10]
    "VnetName"=$Nic.IpConfigurations.subnet.id.split('/')[8]
    "Deployuser"=$Deployuser
    "sapsid"=$sapsid
    } | Out-Null
}
