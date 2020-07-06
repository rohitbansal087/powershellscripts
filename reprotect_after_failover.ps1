$grp = 
#$SourceRG = "rg-sc-SAP-PRD-h-679"
$SourceRGLocation = "South Central US"
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
$StorageAccountRecoveryName = "azstore2asr01"
$StorageAccountRecoveryRG = "rg-e2-NSP-NRD-azurestorage"
$SourceVnetName = "GBSDSERPPlatformsouthcentralusevn02"
$SourceVnetRG = "GBSDSERPPlatformssouthcentralusmrg"


$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultRG -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $Vault
    
$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName
$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName

$PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name "PrimaryProtectionContainer" 
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name "RecoveryProtectionContainer"

$FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "FailbackContainerMapping"


## Get the details of Storage Account in Recovery Region

$StorageAccountRec = Get-AzStorageAccount -ResourceGroupName $StorageAccountRecoveryRG -Name $StorageAccountRecoveryName
 

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
         $SourceRGID = Get-AzResourceGroup -Name $SourceRG -Location $SourceRGLocation

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
    $ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VmName -ProtectionContainer $PrimaryProtContainer

       Update-AzRecoveryServicesAsrProtectionDirection  -AzureToAzure -ReplicationProtectedItem $ReplicationProtectedItem  -ProtectionContainerMapping $FailbackContainerMapping -LogStorageAccountId $StorageAccountRec.Id -RecoveryResourceGroupID $SourceRGID.ResourceId -RecoveryProximityPlacementGroupId $SourcePPPGID.Id 
     
     }

    }
  
    # For SBD servers

    if ($ServiceName -eq 's') {


      VMs = Get-AzVm -ResourceGroupName $SourceRG

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

          $ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VmName -ProtectionContainer $PrimaryProtContainer

          Update-AzRecoveryServicesAsrProtectionDirection  -AzureToAzure -ReplicationProtectedItem $ReplicationProtectedItem  -ProtectionContainerMapping $FailbackContainerMapping -LogStorageAccountId $StorageAccountRec.Id -RecoveryResourceGroupID $SourceRGID.ResourceId -RecoveryProximityPlacementGroupId $SourcePPPGID.Id 
      }
      
    }

  }
