$grp = 
#$SourceRG = "rg-sc-SAP-PRD-h-679"
#$RecoveryRG = "rg-e2-SAP-PDR-h-679"
$RecoveryRGLocation = "East US 2"
$VaultRG   = "rg-e2-NSP-NRD-recoveryvault"
$VaultName = "rsv-e2-asr-01"
$RecoveryVnetName = "GBSDSERPPlatformeastus2evn01"
$RecoveryVnetRG = "GBSDSERPPlatformeastus2mrg"
$PrimaryFabricName = "asr-a2a-default-southcentralus"
$RecoveryFabricName = "asr-a2a-default-eastus2"
$StorageAccountRG = "rg-sc-NSP-PRD-azurestorage"
$StorageAccountName = "azstorscasr01"
$SourceVnetName = "GBSDSERPPlatformsouthcentralusevn02"
$SourceVnetRG = "GBSDSERPPlatformssouthcentralusmrg"


$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultRG -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $Vault

#Creating Primary Fabric
$TempASRJob = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName -ErrorAction SilentlyContinue
if (!($?)) {
$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location 'South Central US'  -Name $PrimaryFabricName 

# Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        #If the job hasn't completed, sleep for 10 seconds before checking the job status again
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State
}

$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName

#Creating Recovery Fabric
$TempASRJob = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName -ErrorAction SilentlyContinue
if (!($?)) {
$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location 'East US 2'  -Name $RecoveryFabricName 

# Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        #If the job hasn't completed, sleep for 10 seconds before checking the job status again
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}


Write-Output $TempASRJob.State
}
$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName

## Get the details of Primary and Recovery Protection Containers
    
$TempASRJob = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name "PrimaryProtectionContainer" -ErrorAction SilentlyContinue
    if (!($?)) {

               $TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $PrimaryFabric -Name "PrimaryProtectionContainer"

               while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                     sleep 10;
                     $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State "PrimaryProtectionContainer"
    }

$PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name "PrimaryProtectionContainer" 

$TempASRJob = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name "RecoveryProtectionContainer" -ErrorAction SilentlyContinue
    if (!($?)) {
                $TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $RecoveryFabric -Name "RecoveryProtectionContainer"

                while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                      sleep 10;
                      $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State "RecoveryProtectionContainer"
}
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name "RecoveryProtectionContainer"
    
## Get the details for Vault Policy

$TempASRJob =  Get-AzRecoveryServicesAsrPolicy -Name "24-hour-retention-policy" -ErrorAction SilentlyContinue
    If (!($?)) {
                $TempASRJob = New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name "24-hour-retention-policy" -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4

                while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                      sleep 10;
                      $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State "24-hour-retention-policy"
    }

$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name "24-hour-retention-policy"


## Get the details of Container Mapping
$TempASRJob = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name "ContainerMapping" -ErrorAction SilentlyContinue

    if (!($?)) {

                $TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ContainerMapping" -Policy $ReplicationPolicy -PrimaryProtectionContainer $PrimaryProtContainer -RecoveryProtectionContainer $RecoveryProtContainer
                      while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                             sleep 10;
                            $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State "ContainerMapping"
    }

$ContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name "ContainerMapping"

## Get the details of Failback Container Mapping

$TempASRJob = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "FailbackContainerMapping" -ErrorAction SilentlyContinue

    if (!($?)) {

               $TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "FailbackContainerMapping" -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $PrimaryProtContainer
                   while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                         sleep 10;
                         $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
                }

Write-Output $TempASRJob.State "FailbackContainerMapping"
            }      
$FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "FailbackContainerMapping"

## Get the details of Storage Account

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageAccountRG -Name $StorageAccountName
    
##Get the details of Source Vnet
$SourceVnet = Get-AzVirtualNetwork -Name $SourceVnetName -ResourceGroupName $SourceVnetRG
$SourceVnetID = $SourceVnet.Id

## Get the details of Recovery Vnet
$RecoveryVnet = Get-AzVirtualNetwork -Name $RecoveryVnetName -ResourceGroupName $RecoveryVnetRG
$RecoveryVnetID = $RecoveryVnet.Id



## Get the details of Network Mapping
$NetworkMapping = Get-AzRecoveryServicesAsrNetworkMapping -Name "78190e81-5bc7-4a95-96c8-7763efd2ae27" -PrimaryFabric $PrimaryFabric -ErrorAction SilentlyContinue
    
   if (!($?)) {

       $TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "southcentral-eastus2-"$SourceVnetName -PrimaryFabric $PrimaryFabric -PrimaryAzureNetworkId $SourceVnetID -RecoveryFabric $RecoveryFabric -RecoveryAzureNetworkId $RecoveryVnetID
           while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                   sleep 10;
                   $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob    
   }

   Write-Output $TempASRJob.State "NetworkMapping"   
  }


    ## Get the details of Faiback Network Mapping

    $FailbackNetworkMapping = Get-AzRecoveryServicesAsrNetworkMapping -Name "eastus2-southcentralus-GBSDSERPPlatformeastus2evn01" -PrimaryFabric $RecoveryFabric -ErrorAction SilentlyContinue

    if (!($?)) {
       $TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "eastus2-southcentralus-"$RecoveryVnetName -PrimaryFabric $RecoveryFabric -PrimaryAzureNetworkId $RecoveryVnetID -RecoveryFabric $PrimaryFabric -RecoveryAzureNetworkId $SourceVnetID
           while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                   sleep 10;
                   $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob    
   }

   Write-Output $TempASRJob.State "FailbackNetworkMapping"
    
   }

   ##Get resource group details
   $ResourceGroup = Get-AzResourceGroup

   $ResourceGroupNames = @($ResourceGroup.ResourceGroupName | select-string "PRD" | select-string $grp)
   
   foreach ($SourceRG in $ResourceGroupNames) {
   
       $ServiceName = $SourceRG.Line.Split('-')[4]
   
       ## Replication for Application and Central servers
   
       if ($ServiceName -eq 'a' -OR $ServiceName -eq 'c') {
          $VMs = Get-AzVm -ResourceGroupName $SourceRG
          $RecoveryRG = "rg-e2-SAP-PDR-$ServiceName-$grp"
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

    # # $av_details = Get-AzAvailabilitySet -ResourceGroupName "rg-e2-SAP-PDR-h-679"
    # # $AvsetName = $av_details.Id.split('/')[8]
    # $RecoveryAVSetID = Get-AzAvailabilitySet -ResourceGroupName $RecoveryRG -Name "avset-h-679-01"

    # $Ppg_ID = $RecoveryAvset.ProximityPlacementGroup

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
    $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name $VM.Name -ProtectionContainerMapping $ContainerMapping -AzureToAzureDiskReplicationConfiguration $diskconfigs -RecoveryResourceGroupId $RecoveryRGID.ResourceId -RecoveryProximityPlacementGroupId $RecoveryPPGID -RecoveryAvailabilitySetId $RecoveryAVSetID
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    Write-Output $TempASRJob.State
}

}
    ## Replication for SBD servers

    # if ($ServiceName -eq 's') {


    #     $VMs = Get-AzVm -ResourceGroupName $SourceRG

    #     $RecoveryRG = "rg-e2-SAP-PDR-$ServiceName-$grp"

    #     $RecoveryRGID = Get-AzResourceGroup -Name $RecoveryRG -Location $RecoveryRGLocation


    #     foreach ( $VM in $VMs ) {
    #         $VmName = $VM.Name
    #         $VmDisk = $VM.StorageProfile.OsDisk.Name
    #         $VMSpec = Get-AzVm -ResourceGroupName $SourceRG -Name $VmName

    #         ## Source AVSet Details

    #         $SourceAVSetID = $VMSpec.AvailabilitySetReference.Id
    #         $AVSetName = $SourceAVSetID.Split('/')[8]

    #         ## Source PPG Details

    #         $SourcePPPGID = $VMSpec.ProximityPlacementGroup.Id
    #         $PPGName = $SourceAVSetID.Split('/')[8]

    #         ## Recovery AVSet Details

    #         $RecoveryAVSet = Get-AzAvailabilitySet -ResourceGroupName $RecoveryRG -Name $AVSetName
    #         $RecoveryAVSetID = $RecoveryAVSet.Id

    #         ## Recovery PPG Details

    #         $RecoveryPPGID = $RecoveryAVSet.ProximityPlacementGroup.Id
        
    
    #         ## Replicate the Virtual Machine with Managed disk
    
    #         #OsDisk
    #         $OSdiskId = $VM.StorageProfile.OsDisk.ManagedDisk.Id
    #         $RecoveryOSDiskAccountType = $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
    #         $RecoveryReplicaDiskAccountType = $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
    #         $OSDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $StorageAccount.Id `
    #              -DiskId $OSdiskId -RecoveryResourceGroupId  $RecoveryRGID.ResourceId -RecoveryReplicaDiskAccountType  $RecoveryReplicaDiskAccountType `
    #             -RecoveryTargetDiskAccountType $RecoveryOSDiskAccountType

    #         $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $ContainerMapping -AzureToAzureDiskReplicationConfiguration $OSDiskReplicationConfig -RecoveryResourceGroupId $RecoveryRGID.ResourceId -RecoveryProximityPlacementGroupId $RecoveryPPGID -RecoveryAvailabilitySetId $RecoveryAVSetID
    #         while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    #             sleep 10;
    #             $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    #         }
    #         Write-Output $TempASRJob.State
    
    #     }
    # }
}
