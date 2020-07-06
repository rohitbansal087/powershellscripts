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

$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name "24-hour-retention-policy"

$FailbackContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "FailbackContainerMapping"


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


    $ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VmName -ProtectionContainer $RecoveryProtContainer
    $RecoveryPoints = Get-AzRecoveryServicesAsrRecoveryPoint -ReplicationProtectedItem $ReplicationProtectedItem
"{0} {1}" -f $RecoveryPoints[0].RecoveryPointType, $RecoveryPoints[-1].RecoveryPointTime
$Job_Failover = Start-AzRecoveryServicesAsrUnplannedFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem -Direction PrimaryToRecovery -RecoveryPoint $RecoveryPoints[-1]

do {
        $Job_Failover = Get-AzRecoveryServicesAsrJob -Job $Job_Failover;
        sleep 30;
} while (($Job_Failover.State -eq "InProgress") -or ($JobFailover.State -eq "NotStarted"))

$Job_Failover.State

$CommitFailoverJOb = Start-AzRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem

Get-AzRecoveryServicesAsrJob -Job $CommitFailoverJOb

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

        $ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VmName -ProtectionContainer $RecoveryProtContainer
        $RecoveryPoints = Get-AzRecoveryServicesAsrRecoveryPoint -ReplicationProtectedItem $ReplicationProtectedItem
    "{0} {1}" -f $RecoveryPoints[0].RecoveryPointType, $RecoveryPoints[-1].RecoveryPointTime
    $Job_Failover = Start-AzRecoveryServicesAsrUnplannedFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem -Direction PrimaryToRecovery -RecoveryPoint $RecoveryPoints[-1]
    
    do {
            $Job_Failover = Get-AzRecoveryServicesAsrJob -Job $Job_Failover;
            sleep 30;
    } while (($Job_Failover.State -eq "InProgress") -or ($JobFailover.State -eq "NotStarted"))
    
    $Job_Failover.State
    
    $CommitFailoverJOb = Start-AzRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem
    
    Get-AzRecoveryServicesAsrJob -Job $CommitFailoverJOb

#Remove-AzRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $ReplicationProtectedItem
}

}

}
