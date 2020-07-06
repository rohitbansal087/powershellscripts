$grp =
$RecoveryRGLocation = "East US 2"
$VaultRG   = "rg-e2-NSP-NRD-recoveryvault"
$VaultName = "rsv-e2-asr-01"
$RecoveryVnetName = "GBSDSERPPlatformeastus2evn01"
$RecoveryVnetRG = "GBSDSERPPlatformeastus2mrg"
$PrimaryFabricName = "asr-a2a-default-southcentralus"
$RecoveryFabricName = "asr-a2a-default-eastus2"
$StorageAccountRG = "rg-sc-NSP-PRD-azurestorage"
$StorageAccountName = "azstorscasr01"

$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultRG -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $Vault
    
$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $PrimaryFabricName
$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $RecoveryFabricName

## Get the details of Primary and Secondary Protection Containers

$PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name "PrimaryProtectionContainer"
    
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name "RecoveryProtectionContainer"


##Get resource group details
$ResourceGroup = Get-AzResourceGroup

$ResourceGroupNames = @($ResourceGroup.ResourceGroupName | select-string "PRD" | select-string $grp)
   
foreach ($SourceRG in $ResourceGroupNames) {
   
    $ServiceName = $SourceRG.Line.Split('-')[4]
   
    ## Replication for Application and Central servers
   
    if ($ServiceName -eq 'a' -OR $ServiceName -eq 'c' -OR $ServiceName -eq 's') {


        $VMs = Get-AzVm -ResourceGroupName $SourceRG
        $RecoveryRG = "rg-e2-SAP-PDR-$ServiceName-$grp"
        $RecoveryRGID = Get-AzResourceGroup -Name $RecoveryRG -Location $RecoveryRGLocation

        foreach ( $VM in $VMs ) {

            $VmName = $VM.Name

            $ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VmName  -ProtectionContainer $PrimaryProtContainer -ErrorAction SilentlyContinue
            if (!($?)) {

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
    }
}
