$SourceRG = ""
$RecoveryRG = ""
$RecoveryRGLocation = ""
$VaultRG   = ""
$VaultName = ""
$RecoveryVnetName = ""
$RecoveryVnetRG = ""
$PrimaryFabricName = "primary-fabric"
$RecoveryFabricName = "secondary-fabric"
$StorageAccountNameRG = ""
$StorageAccountName = ""

$VMs= Get-AzVm -ResourceGroupName $SourceRG

foreach ( $VM in $VMs ) {
    $VmName = $VM.Name
    $VmDisk = $VM.StorageProfile.OsDisk.Name


    $Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultRG -Name $VaultName
    Set-AzRecoveryServicesAsrVaultContext -Vault $Vault
    
    $PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName
    $RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName

    ## Get the details of Primary and Secondary Protection Containers

    $PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name "PrimaryProtectionContainer"
    $RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name "RecoveryProtectionContainer"
    
    if ($PrimaryProtContainer -eq $null) {

        New-AzRecoveryServicesAsrProtectionContainer -InputObject $PrimaryFabric -Name "PrimaryProtectionContainer"
        $PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name "PrimaryProtectionContainer"
    
    }

    if ($RecoveryProtContainer -eq $null) {

        New-AzRecoveryServicesAsrProtectionContainer -InputObject $RecoveryFabric -Name "RecoveryProtectionContainer"
        $RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name "RecoveryProtectionContainer"
    
    }
    
    ## Get the details for Vault Policy

    $ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name "VaultPolicy"

    if ($ReplicationPolicy -eq $null) {

        New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name "VaultPolicy" -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4
        $ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name "VaultPolicy"
    
    }

    ## Get the details of Container Mapping

    $ContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name "ContainerMapping"
    
    if ($ContainerMapping -eq $null) {

        New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ContainerMapping" -Policy $ReplicationPolicy -PrimaryProtectionContainer $PrimaryProtContainer -RecoveryProtectionContainer $RecoveryProtContainer
        $ContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name "ContainerMapping"
    
    }

    ## Get the details of Failback Container Mapping

    $FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "FailbackContainerMapping"
    
    if ($FailbackContainerMapping -eq $null) {

        New-AzRecoveryServicesAsrProtectionContainerMapping -Name "FailbackContainerMapping" -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $PrimaryProtContainer
        $FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "FailbackContainerMapping"
    
    }

    ## Get the details of Storage Account

    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageAccountNameRG -Name $StorageAccountName
    
    ## Get the details of Recovery Vnet
    $RecoveryVnet = Get-AzVirtualNetwork -Name $RecoveryVnetName -ResourceGroupName $RecoveryVnetRG
    $RecoveryVnetID = $RecoveryVnet.Id

    ## Get the details of Primary Vnet
    $SplitNicArmId = $VM.NetworkProfile.NetworkInterfaces[0].Id.split("/")
    $NICRG = $SplitNicArmId[4]
    $NICname = $SplitNicArmId[-1]
    $NIC = Get-AzNetworkInterface -ResourceGroupName $NICRG -Name $NICname
    $PrimarySubnet = $NIC.IpConfigurations[0].Subnet
    $PrimaryVnetID = (Split-Path(Split-Path($PrimarySubnet.Id))).Replace("\","/")
    
    ## Get the details of Network mapping
    New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "NetworkMapping" -PrimaryFabric $PrimaryFabric -PrimaryAzureNetworkId $PrimaryVnetID -RecoveryFabric $RecoveryFabric -RecoveryAzureNetworkId $RecoveryVnetID
    New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "FailbackNetworkMapping" -PrimaryFabric $RecoveryFabric -PrimaryAzureNetworkId $RecoveryVnetID -RecoveryFabric $PrimaryFabric -RecoveryAzureNetworkId $PrimaryVnetID
    
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
    New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $ContainerMapping -AzureToAzureDiskReplicationConfiguration $diskconfigs -RecoveryResourceGroupId $RecoveryRGID.ResourceId   
}
