$rgname = ""
$RecoveryRG = ""
$vaultrg   = ""
$vaultname = ""
$RecoveryVnet = ""

$VMs= Get-AzVm -ResourceGroupName $rgname

foreach ( $VM in $VMs ) {
    $VmName = $VM.Name
    $VmDisk = $VM.StorageProfile.OsDisk.Name


    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $vaultrg -Name $vaultname
    Set-AzRecoveryServicesAsrVaultContext -Vault $vault
    
    $primaryfabric = Get-AzRecoveryServicesAsrFabric -Name primary-fabric
    $RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name secondary-fabric

    New-AzRecoveryServicesAsrProtectionContainer -InputObject $primaryfabric -Name "PrimaryProtectionContainer"
    $PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $primaryfabric -Name "PrimaryProtectionContainer"


    New-AzRecoveryServicesAsrProtectionContainer -InputObject $RecoveryFabric -Name "RecoveryProtectionContainer"
    $RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name "RecoveryProtectionContainer"

    New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name "VaultPolicy" -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4
    $ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name "VaultPolicy"


    New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ContainerMapping" -Policy $ReplicationPolicy -PrimaryProtectionContainer $PrimaryProtContainer -RecoveryProtectionContainer $RecoveryProtContainer
    $ContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name "ContainerMapping"
    

    New-AzRecoveryServicesAsrProtectionContainerMapping -Name "FailbackContainerMapping" -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $PrimaryProtContainer
    $FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "FailbackContainerMapping"
    

    $RecoveryNetwork = $RecoveryVnet.Id
    
    $SplitNicArmId = $VM.NetworkProfile.NetworkInterfaces[0].Id.split("/")
    $NICRG = $SplitNicArmId[4]
    $NICname = $SplitNicArmId[-1]
    $NIC = Get-AzNetworkInterface -ResourceGroupName $NICRG -Name $NICname
    $PrimarySubnet = $NIC.IpConfigurations[0].Subnet
    $PrimaryNetwork = (Split-Path(Split-Path($PrimarySubnet.Id))).Replace("\","/")



    New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "NetworkMapping" -PrimaryFabric $PrimaryFabric -PrimaryAzureNetworkId $PrimaryNetwork -RecoveryFabric $RecoveryFabric -RecoveryAzureNetworkId $RecoveryNetwork

    New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "FailbackNetworkMapping" -PrimaryFabric $RecoveryFabric -PrimaryAzureNetworkId $RecoveryNetwork -RecoveryFabric $PrimaryFabric -RecoveryAzureNetworkId $PrimaryNetwork
    
}
