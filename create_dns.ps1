param (
    [Parameter(Mandatory=$true)][string]$infobloxpwd,
    [Parameter(Mandatory=$true)][string]$infobloxpwd1,
    [Parameter(Mandatory=$true)][string]$dns,
    [Parameter(Mandatory=$true)][string]$env,
    [Parameter(Mandatory=$true)][string]$Hostname,
    [Parameter(Mandatory=$true)][string]$IPAddress


)

$fqdn = ".cloud.wal-mart.com"
#check is it a DR VM
If ($env -eq "PDR"){
    $fqdn = "-DR.cloud.wal-mart.com"
}

#$filePath = './_Robin-AzureInfraTasksBuild/Robin-AzureInfraTasksBuild/DNS/vmhostnames.txt'
#$hostnames = Get-Content $filePath 

$hostnamestemp = $Hostname.split(':')
$iptemp = $IPAddress.split(':')
$hostnamecount=$hostnamestemp.count

#Foreach ($hostname in $hostnamestemp) {
For ($i=0; $i -lt $hostnamecount; $i++) {

    # $rg = Get-AzVM -Name $hostname
    # $ipaddress = Get-AzNetworkInterface -ResourceGroupName $rg.ResourceGroupName | where-object {$_.Name -match $hostname}
    # $ipaddress = $ipaddress.IpConfigurations[0].PrivateIpAddress
    $hostname = $hostnamestemp[$i]
    $ipaddress = $iptemp[$i]
    $username = "sapapiadm"
    $password = $infobloxpwd
    $password = ConvertTo-SecureString -String $password -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential $username, $password
    $username1 = "sap-api"
    $password1 = $infobloxpwd1
    $password1 = ConvertTo-SecureString -String $password1 -AsPlainText -Force
    $creds1 = New-Object System.Management.Automation.PSCredential $username1, $password1
    $baseuri = "https://infoblox-api.wal-mart.com/wapi/v2.5"
    $baseuri1 = "https://azure-infoblox-api.us.walmart.net/wapi/v2.5"
    $checkuri = "$baseuri/record:a?ipv4addr=$ipaddress"
    $checkuri1 = "$baseuri/record:a?name=$hostname$fqdn"
    $adduri = "$baseuri/record:a?_return_fields%2B=name,ipv4addr&_return_as_object=1"
    $ptrcheckuri = "$baseuri1/record:ptr?ipv4addr=$ipaddress"
    $ptruri = "$baseuri1/record:ptr?_return_fields%2B=ptrdname,ipv4addr&_return_as_object=1"
    $content = Invoke-WebRequest -Uri $checkuri -Method GET -Credential $creds -ContentType "application/json" -SkipCertificateCheck -Verbose
    $content1 = Invoke-WebRequest -Uri $ptrcheckuri -Method GET -Credential $creds1 -ContentType "application/json" -SkipCertificateCheck -Verbose
    $content2 = Invoke-WebRequest -Uri $checkuri1 -Method GET -Credential $creds -ContentType "application/json" -SkipCertificateCheck -Verbose
    If ($content.content -eq "[]" -and $content1.content -eq "[]" -and $content2.content -eq "[]") {
        $data = @" 
            {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress"
            }
"@
        $data1 = @" 
           {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress",
                "ptrdname": "$hostname$fqdn"
            }
"@
            Invoke-WebRequest -Uri $adduri -Method POST -Credential $creds -ContentType "application/json" -Body $data -SkipCertificateCheck -Verbose
            Invoke-WebRequest -Uri $ptruri -Method POST -Credential $creds1 -ContentType "application/json" -Body $data1 -SkipCertificateCheck -Verbose
        }
        ElseIf ($content.content -ne "[]" -and $content1.content -eq "[]") {
            $ipdns=$content.Content | ConvertFrom-Json
            $ipdns=$ipdns._ref
            ForEach ($ip in $ipdns) {
                $updateuri = "$baseuri/$ip"
                Invoke-WebRequest -Uri $updateuri -Method DELETE -Credential $creds -ContentType "application/json" -SkipCertificateCheck -Verbose
            }
        $data = @" 
            {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress"
            }
"@
        $data1 = @" 
            {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress",
                "ptrdname": "$hostname$fqdn"
            }
"@
            Invoke-WebRequest -Uri $ptruri -Method POST -Credential $creds1 -ContentType "application/json" -Body $data1 -SkipCertificateCheck -Verbose
            Invoke-WebRequest -Uri $adduri -Method POST -Credential $creds -ContentType "application/json" -Body $data -SkipCertificateCheck -Verbose
        }
        ElseIf ($content.content -ne "[]" -and $content1.content -eq "[]" -and $content2.content -ne "[]") {
            $ipdns=$content.Content | ConvertFrom-Json
            $ipdns=$ipdns._ref
            ForEach ($ip in $ipdns) {
                $updateuri = "$baseuri/$ip"
                Invoke-WebRequest -Uri $updateuri -Method DELETE -Credential $creds -ContentType "application/json" -SkipCertificateCheck -Verbose
            }
            $ipdns2=$content2.Content | ConvertFrom-Json
            $ipdns2=$ipdns2._ref
            ForEach ($ip2 in $ipdns2) {
                $updateuri = "$baseuri/$ip2"
                Invoke-WebRequest -Uri $updateuri -Method DELETE -Credential $creds -ContentType "application/json" -SkipCertificateCheck -Verbose
            }
            $data = @" 
                {
                    "name": "$hostname$fqdn",
                    "ipv4addr": "$ipaddress"
                }
"@
            $data1 = @" 
            {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress",
                "ptrdname": "$hostname$fqdn"
            }
"@
            Invoke-WebRequest -Uri $ptruri -Method POST -Credential $creds1 -ContentType "application/json" -Body $data1 -SkipCertificateCheck -Verbose
            Invoke-WebRequest -Uri $adduri -Method POST -Credential $creds -ContentType "application/json" -Body $data -SkipCertificateCheck -Verbose
        }
        ElseIf ($content.content -eq "[]" -and $content1.content -ne "[]") {
            $ipdns1=$content1.Content | ConvertFrom-Json
            $ipdns1=$ipdns1._ref
            $ipdns1
            ForEach ($ip1 in $ipdns1) {
                $ptrupdateuri = "$baseuri1/$ip1"
                Invoke-WebRequest -Uri $ptrupdateuri -Method DELETE -Credential $creds -ContentType "application/json" -SkipCertificateCheck -Verbose
            }
            $data = @" 
            {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress"
            }
"@
            $data1 = @" 
            {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress",
                "ptrdname": "$hostname$fqdn"
            }
"@
            Invoke-WebRequest -Uri $adduri -Method POST -Credential $creds -ContentType "application/json" -Body $data -SkipCertificateCheck -Verbose
            Invoke-WebRequest -Uri $ptruri -Method POST -Credential $creds1 -ContentType "application/json" -Body $data1 -SkipCertificateCheck -Verbose
        }
        ElseIf ($content.content -ne "[]" -and $content1.content -ne "[]") {
            $ipdns1=$content1.Content | ConvertFrom-Json
            $ipdns1=$ipdns1._ref
            $ipdns1
            ForEach ($ip1 in $ipdns1) {
                $ptrupdateuri = "$baseuri1/$ip1"
                Invoke-WebRequest -Uri $ptrupdateuri -Method DELETE -Credential $creds -ContentType "application/json" -SkipCertificateCheck -Verbose
            }
            $ipdns=$content.Content | ConvertFrom-Json
            $ipdns=$ipdns._ref
            ForEach ($ip in $ipdns) {
                $updateuri = "$baseuri/$ip"
                Invoke-WebRequest -Uri $updateuri -Method DELETE -Credential $creds -ContentType "application/json" -SkipCertificateCheck -Verbose
            }
            $data = @" 
            {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress"
            }
"@
            $data1 = @" 
            {
                "name": "$hostname$fqdn",
                "ipv4addr": "$ipaddress",
                "ptrdname": "$hostname$fqdn"
            }
"@
            Invoke-WebRequest -Uri $adduri -Method POST -Credential $creds -ContentType "application/json" -Body $data -SkipCertificateCheck -Verbose
            Invoke-WebRequest -Uri $ptruri -Method POST -Credential $creds1 -ContentType "application/json" -Body $data1 -SkipCertificateCheck -Verbose
        }
    }
