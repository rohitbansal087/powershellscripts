$SubscriptionName = "US-AZSUB-AME-TAX-DCMSHARED-PSGAPPS-PRD"
$Subscriptions = Get-AzSubscription
Select-AzSubscription $SubscriptionName
$results = @()
$RGs = Get-AzResourceGroup
foreach($RG in $RGs) {
$VMs = Get-AzVM -ResourceGroupName $RG.ResourceGroupName
foreach($VM in $VMs)
{
    $VmName = $VM.Name
    $NicName = $VM.NetworkProfile.NetworkInterfaces.Id.Split('/')[8]
    $NICRG = $VM.NetworkProfile.NetworkInterfaces.Id.Split('/')[4]
    $NIC = Get-AzNetworkInterface -ResourceGroupName $NICRG -Name $NICname
    $PrivateIpAddress =  $NIC.IpConfigurations.PrivateIpAddress
    $alloc =  $NIC.IpConfigurations.PrivateIpAllocationMethod
    $AsgResourceID = ($NIC.IpConfigurationsText | ConvertFrom-Json).ApplicationSecurityGroups.Id
    $NsgResourceID = $NIC.NetworkSecurityGroup.Id
    $SubnetId = Get-AzVirtualNetworkSubnetConfig -ResourceId $NIC.IpConfigurations.Subnet.Id


    IF($asgResourceID.length -EQ 0) {
        $AsgName  = "NO ASG FOUND" 
    } ELSE {
        $AsgName = (Get-AzResource -ErrorAction SilentlyContinue -ResourceId $asgResourceID).Name
    }
    IF ($nic.NetworkSecurityGroupText -EQ "null" -and !$SubnetId.NetworkSecurityGroup.Id) {
        $NsgName  = "NO NSG FOUND"
    } ELSEIF(!$SubnetId.NetworkSecurityGroup.Id) {
        $NsgName = (Get-AzResource -ErrorAction SilentlyContinue -ResourceId $NsgResourceID).Name
    } ELSE {
        $NsgName = (Get-AzResource -ErrorAction SilentlyContinue -ResourceId $SubnetId.NetworkSecurityGroup.Id).Name
    }
    $details = @{
        "SubscriptionName" = $SubscriptionName
        "VMName"           = $VmName
        "ResourceGroup"    = $RG.ResourceGroupName
        "IpAddress"        = $PrivateIpAddress
        "ASG"              = $AsgName
        "NsgName"          = $NsgName
    }
    $results += New-Object PSObject -Property $details
}
}

$results | export-csv -Path c:\temp\so.csv -NoTypeInformation
