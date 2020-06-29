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
$FailbackStorageAccountName = ""
$FailbackStorageAccountRG = ""


$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultRG -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $Vault
    
$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName
$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName

## Get the details of Primary and Secondary Protection Containers

$PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $SourceRG"PrimaryProtectionContainer"
    
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name $SourceRG"RecoveryProtectionContainer"
$ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName "AzureDemoVM" -ProtectionContainer $PrimaryProtContainer

$FailbackStorageAccount = Get-AzStorageAccount -ResourceGroupName $FailbackStorageAccountRG -Name $FailbackStorageAccountName

$FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name $SourceRG"FailbackContainerMapping"

Update-AzRecoveryServicesAsrProtectionDirection -ReplicationProtectedItem $ReplicationProtectedItem -AzureToAzure -ProtectionContainerMapping $FailbackContainerMapping -LogStorageAccountId $FailbackStorageAccount.Id -RecoveryResourceGroupID $SourceRG.ResourceId
