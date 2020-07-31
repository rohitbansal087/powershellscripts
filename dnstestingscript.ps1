$hostname = vas676-01.cloud.wal-mart.com
$ipaddress = 10.238.246.107
$username = "sapapiadm"
$password = "699rrCPu8"
$password = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential $username, $password
$username1 = "sapapiadm"
$password1 = "699rrCPu8"
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
$content
$content1
$content2
