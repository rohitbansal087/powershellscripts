$SourceRG = "SourceRG"
$RecoveryRG = "RecoveryRG"
$RecoveryRGLocation = "East US"
$VaultRG   = "VaultRG"
$VaultName = "RecoveryVault"
$RecoveryVnetName = "RecoveryVnet"
$RecoveryVnetRG = "RecoveryVnetRG"
$PrimaryFabricName = "PrimaryFabric"
$RecoveryFabricName = "RecoveryFabric"
$StorageAccountRG = "StorageAccountRG"
$StorageAccountName = "sourcestoragename"

$VMs = Get-AzVm -ResourceGroupName $SourceRG


$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultRG -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $Vault
    
$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName
$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName

## Get the details of Primary and Secondary Protection Containers
    

$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $PrimaryFabric -Name $SourceRG"PrimaryProtectionContainer"

while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $SourceRG"PrimaryProtectionContainer"

$PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $SourceRG"PrimaryProtectionContainer"
    
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $RecoveryFabric -Name $SourceRG"RecoveryProtectionContainer"

while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $SourceRG"RecoveryProtectionContainer"
    
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name $SourceRG"RecoveryProtectionContainer"
    
## Get the details for Vault Policy


$TempASRJob = New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name $SourceRG"VaultPolicy" -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4

while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $SourceRG"VaultPolicy"

$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name $SourceRG"VaultPolicy"


## Get the details of Container Mapping

$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $SourceRG"ContainerMapping" -Policy $ReplicationPolicy -PrimaryProtectionContainer $PrimaryProtContainer -RecoveryProtectionContainer $RecoveryProtContainer
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $SourceRG"ContainerMapping"

$ContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name $SourceRG"ContainerMapping"

## Get the details of Failback Container Mapping

$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $SourceRG"FailbackContainerMapping" -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $PrimaryProtContainer
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $SourceRG"FailbackContainerMapping"

$FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name $SourceRG"FailbackContainerMapping"

## Get the details of Storage Account

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageAccountRG -Name $StorageAccountName
    
## Get the details of Recovery Vnet
$RecoveryVnet = Get-AzVirtualNetwork -Name $RecoveryVnetName -ResourceGroupName $RecoveryVnetRG
$RecoveryVnetID = $RecoveryVnet.Id

foreach ( $VM in $VMs ) {
    $VmName = $VM.Name
    $VmDisk = $VM.StorageProfile.OsDisk.Name

    ## Get the details of Primary Vnet
    $SplitNicArmId = $VM.NetworkProfile.NetworkInterfaces[0].Id.split("/")
    $NICRG = $SplitNicArmId[4]
    $NICname = $SplitNicArmId[-1]
    $NIC = Get-AzNetworkInterface -ResourceGroupName $NICRG -Name $NICname
    $PrimarySubnet = $NIC.IpConfigurations[0].Subnet
    $PrimaryVnetID = (Split-Path(Split-Path($PrimarySubnet.Id))).Replace("\","/")
    $PrimaryVnetName =  $PrimaryVnetID.Split('/')[8]

    
    ## Get the details of Network Mapping

    $TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name $PrimaryVnetName"to"$RecoveryVnetName"mapping" -PrimaryFabric $PrimaryFabric -PrimaryAzureNetworkId $PrimaryVnetID -RecoveryFabric $RecoveryFabric -RecoveryAzureNetworkId $RecoveryVnetID
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob    
    }

    Write-Output $TempASRJob.State "NetworkMapping"


    ## Get the details of Faiback Network Mapping

    $TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name $RecoveryVnetName"to"$PrimaryVnetName"mapping" -PrimaryFabric $RecoveryFabric -PrimaryAzureNetworkId $RecoveryVnetID -RecoveryFabric $PrimaryFabric -RecoveryAzureNetworkId $PrimaryVnetID
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob    
    }

    Write-Output $TempASRJob.State "FailbackNetworkMapping"
    

    ## Replicate the Virtual Machine with Managed disk
    $RecoveryRGID = Get-AzResourceGroup -Name $RecoveryRG -Location $RecoveryRGLocation

    #OsDisk
    $OSdiskId = $VM.StorageProfile.OsDisk.ManagedDisk.Id
    $RecoveryOSDiskAccountType = $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
    $RecoveryReplicaDiskAccountType = $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
    $OSDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $StorageAccount.Id `
         -DiskId $OSdiskId -RecoveryResourceGroupId  $RecoveryRGID.ResourceId -RecoveryReplicaDiskAccountType  $RecoveryReplicaDiskAccountType `
         -RecoveryTargetDiskAccountType $RecoveryOSDiskAccountType

    # Data disk
    $DatadiskId1 = $VM.StorageProfile.DataDisks[0].ManagedDisk.Id
    $RecoveryReplicaDiskAccountType = $VM.StorageProfile.DataDisks[0].ManagedDisk.StorageAccountType
    $RecoveryTargetDiskAccountType = $VM.StorageProfile.DataDisks[0].ManagedDisk.StorageAccountType

    $DataDisk1ReplicationConfig  = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $StorageAccount.Id `
           -DiskId $DatadiskId1 -RecoveryResourceGroupId $RecoveryRGID.ResourceId -RecoveryReplicaDiskAccountType $RecoveryReplicaDiskAccountType `
           -RecoveryTargetDiskAccountType $RecoveryTargetDiskAccountType

    $diskconfigs = @()
    $diskconfigs += $OSDiskReplicationConfig, $DataDisk1ReplicationConfig
    $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $ContainerMapping -AzureToAzureDiskReplicationConfiguration $diskconfigs -RecoveryResourceGroupId $RecoveryRGID.ResourceId   
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    Write-Output $TempASRJob.State

}
