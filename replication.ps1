$ResourceGroupNum = "900"
$RecoveryRGLocation = "East US"
$VaultRG   = "VaultRG"
$VaultName = "RecoveryVault"
$SourceVnetName = ""
$SourceVnetRG  = ""
$RecoveryVnetName = "RecoveryVnet"
$RecoveryVnetRG = "RecoveryVnetRG"
$PrimaryFabricName = "PrimaryFabric"
$RecoveryFabricName = "RecoveryFabric"
$StorageAccountRG = "SourceStorageRG"
$StorageAccountName = "sourcestorageabc"


$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultRG -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $Vault

$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName
$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName

$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultRG -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $Vault
    
$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName
$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName

## Get the details of Primary and Secondary Protection Containers
    

$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $PrimaryFabric -Name $PrimaryProtectionContainer

while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $PrimaryProtectionContainer

$PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $PrimaryProtectionContainer
    
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $RecoveryFabric -Name $RecoveryProtectionContainer

while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $RecoveryProtectionContainer
    
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name $RecoveryProtectionContainer
    
## Get the details for Vault Policy


$TempASRJob = New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name $VaultPolicy -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4

while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $VaultPolicy

$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name $VaultPolicy


## Get the details of Container Mapping

$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $ContainerMapping -Policy $ReplicationPolicy -PrimaryProtectionContainer $PrimaryProtContainer -RecoveryProtectionContainer $RecoveryProtContainer
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $ContainerMapping

$ContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name $ContainerMapping

## Get the details of Failback Container Mapping

$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $FailbackContainerMapping -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $PrimaryProtContainer
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State $FailbackContainerMapping

$FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name $FailbackContainerMapping

## Get the details of Storage Account

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageAccountRG -Name $StorageAccountName

## Get the details of Source Vnet

$SourceVnet = Get-AzVirtualNetwork -Name $SourceVnetName -ResourceGroupName $SourceVnetRG
$SourceVnetID = $SourceVnet.Id
    
## Get the details of Recovery Vnet
$RecoveryVnet = Get-AzVirtualNetwork -Name $RecoveryVnetName -ResourceGroupName $RecoveryVnetRG
$RecoveryVnetID = $RecoveryVnet.Id
        
## Get the details of Network Mapping
    
$TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "NetworkMapping" -PrimaryFabric $PrimaryFabric -PrimaryAzureNetworkId $PrimaryVnetID -RecoveryFabric $RecoveryFabric -RecoveryAzureNetworkId $RecoveryVnetID
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob    
}
    
Write-Output $TempASRJob.State "NetworkMapping"
    
    
## Get the details of Failback Network Mapping
    
$TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "FailbackNetworkMapping" -PrimaryFabric $RecoveryFabric -PrimaryAzureNetworkId $RecoveryVnetID -RecoveryFabric $PrimaryFabric -RecoveryAzureNetworkId $PrimaryVnetID
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob    
}
    
Write-Output $TempASRJob.State "FailbackNetworkMapping"



$ResourceGroup = Get-AzResourceGroup

$ResourceGroupNames = @($ResourceGroup.ResourceGroupName | select-string "PRD" | select-string $ResourceGroupNum)

foreach ($SourceRG in $ResourceGroupNames) {

    $ServiceName = $SourceRG.Line.Split('-')[4]

    ## Replication for Application and Central servers

    if ($ServiceName -eq 'a' -OR $ServiceName -eq 'c') {


        VMs = Get-AzVm -ResourceGroupName $SourceRG

        $RecoveryRG = "rg-sc-SAP-PDR-$ServiceName-$ResourceGroupNum"

        $RecoveryRGID = Get-AzResourceGroup -Name $RecoveryRG -Location $RecoveryRGLocation


        foreach ( $VM in $VMs ) {
            $VmName = $VM.Name
            $VmDisk = $VM.StorageProfile.OsDisk.Name
            $VMSpec = Get-AzVm -ResourceGroupName $SourceRG -Name $VmName

            ## Source AVSet Details

            $SourceAVSetID = $VMSpec.AvailabilitySetReference.Id
            $AVSetName = $SourceAVSetID.Split('/')[8]

            ## Source PPG Details

            $SourcePPPGID = $VMSpec.ProximityPlacementGroup.Id
            $PPGName = $SourceAVSetID.Split('/')[8]

            ## Recovery AVSet Details

            $RecoveryAVSet = Get-AzAvailabilitySet -ResourceGroupName $RecoveryRG -Name $AVSetName
            $RecoveryAVSetID = $RecoveryAVSet.Id

            ## Recovery PPG Details

            $RecoveryPPGID = $RecoveryAVSet.ProximityPlacementGroup.Id

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
    }
    
    ## Replication for SBD servers

    if ($ServiceName -eq 's') {


        VMs = Get-AzVm -ResourceGroupName $SourceRG

        $RecoveryRG = "rg-sc-SAP-PDR-$ServiceName-$ResourceGroupNum"

        $RecoveryRGID = Get-AzResourceGroup -Name $RecoveryRG -Location $RecoveryRGLocation


        foreach ( $VM in $VMs ) {
            $VmName = $VM.Name
            $VmDisk = $VM.StorageProfile.OsDisk.Name
            $VMSpec = Get-AzVm -ResourceGroupName $SourceRG -Name $VmName

            ## Source AVSet Details

            $SourceAVSetID = $VMSpec.AvailabilitySetReference.Id
            $AVSetName = $SourceAVSetID.Split('/')[8]

            ## Source PPG Details

            $SourcePPPGID = $VMSpec.ProximityPlacementGroup.Id
            $PPGName = $SourceAVSetID.Split('/')[8]

            ## Recovery AVSet Details

            $RecoveryAVSet = Get-AzAvailabilitySet -ResourceGroupName $RecoveryRG -Name $AVSetName
            $RecoveryAVSetID = $RecoveryAVSet.Id

            ## Recovery PPG Details

            $RecoveryPPGID = $RecoveryAVSet.ProximityPlacementGroup.Id
        
    
            ## Replicate the Virtual Machine with Managed disk
    
            #OsDisk
            $OSdiskId = $VM.StorageProfile.OsDisk.ManagedDisk.Id
            $RecoveryOSDiskAccountType = $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
            $RecoveryReplicaDiskAccountType = $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
            $OSDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $StorageAccount.Id `
                 -DiskId $OSdiskId -RecoveryResourceGroupId  $RecoveryRGID.ResourceId -RecoveryReplicaDiskAccountType  $RecoveryReplicaDiskAccountType `
                -RecoveryTargetDiskAccountType $RecoveryOSDiskAccountType

            $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $ContainerMapping -AzureToAzureDiskReplicationConfiguration $OSDiskReplicationConfig -RecoveryResourceGroupId $RecoveryRGID.ResourceId   
            while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                sleep 10;
                $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
            }
            Write-Output $TempASRJob.State
    
        }
    }
}
