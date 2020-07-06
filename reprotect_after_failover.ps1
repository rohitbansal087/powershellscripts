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

$ContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name "ContainerMapping"

## Get the details of Storage Account

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageAccountRG -Name $StorageAccountName

##Get resource group details
$ResourceGroup = Get-AzResourceGroup

$ResourceGroupNames = @($ResourceGroup.ResourceGroupName | select-string "PDR" | select-string $grp)
  
foreach ($RecoveryRG in $ResourceGroupNames) {
  
  $ServiceName = $RecoveryRG.Line.Split('-')[4]
  
  ## Replication for Application and Central servers
  
  if ($ServiceName -eq 'a' -OR $ServiceName -eq 'c' -OR $ServiceName -eq 's') {

    $VMs = Get-AzVm -ResourceGroupName $RecoveryRG
    $SourceRG = "rg-e2-SAP-PDR-$ServiceName-$grp"
    $SourceRGID = Get-AzResourceGroup -Name $SourceRG -Location $SourceRGLocation
    $RecoveryRG = Get-AzResourceGroup -Name $RecoveryRG -Location $RecoveryRGLocation

    foreach ( $VM in $VMs ) {
 
      $VmName = $VM.Name
      $VmDisk = $VM.StorageProfile.OsDisk.Name
      $VMSpec = Get-AzVm -ResourceGroupName $RecoveryRG -Name $VmName

      $RecoveryPPGID = $VMSpec.ProximityPlacementGroup.Id

      $ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VmName -ProtectionContainer $RecoveryProtContainer

      Update-AzRecoveryServicesAsrProtectionDirection  -AzureToAzure -ReplicationProtectedItem $ReplicationProtectedItem  -ProtectionContainerMapping $ContainerMapping -LogStorageAccountId $StorageAccount.Id -RecoveryResourceGroupID $RecoveryRGID.ResourceId -RecoveryProximityPlacementGroupId $RecoveryPPGID.Id
    }
  }
}
