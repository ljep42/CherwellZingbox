# ============================================================================================
#
#Import-Module SqlServer
# sqlps is legacy but installed on server
Import-Module sqlps

# ============================================================================================
# SQL Server Credentials
$SQLserver = ""
$SQLdatabase = ""
$SQLuser = ""
$PasswordFile = ""
$KeyFile = ""
$key = Get-Content $KeyFile
$SecurePassword = Get-Content $PasswordFile | ConvertTo-SecureString -Key $key 
$SQLPassword = (New-Object PSCredential $SQLuser,$SecurePassword).GetNetworkCredential().Password
# ============================================================================================

# Truncate the Table
$SQLTruncate="TRUNCATE TABLE [].[];"
Invoke-SQLcmd -query $SQLTruncate -ServerInstance $SQLserver -Database $SQLdatabase -Username $SQLuser -Password $SQLPassword

# Setup web request
$key_id = ""
$pagelength = 100000
$offset=1
$key = ""

$url = "https://lifebridgehealth.zingbox.com/pub/v4.0/device/list?customerid=lifebridgehealth"
$uri = $url+"&key_id=$key_id&access_key=$key&detail=true&pagelength=$pagelength&offset=$offset"

# added tls 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# send request for device list
#$resp = Invoke-RestMethod -Method Get -Uri $uri
$resp = Invoke-WebRequest -Method Get -Uri $uri -UseBasicParsing

#rename field since there are two fields 'source' and 'Source' that causes issue
$obj = $resp.Content.Replace("Source","Source2") | ConvertFrom-Json

	# iterate through objects
	foreach($device in $obj.devices) {
		
		if(($device.profile_type -eq 'IoT') -and ($device.profile_vertical -eq 'Medical')) {

			$val01 = $device.profile_type
			$val02 = $device.profile_vertical
			$val03 = $device.profile
			$val04 = $device.site_name
			$val05 = $device.hostname
			$val06 = $device.ip_address
			$val07 = $device.mac_address
			$val08 = $device.category
			$val09 = $device.vendor
			$val10 = $device.os_group
			$val11 = $device.'os/firmware_version'
			$val12 = $device.wire_or_wireless
			$val13 = $device.first_seen_date
			$val14 = $device.last_activity
			$val15 = $device.Switch_Name
			$val16 = $device.Switch_IP
			$val17 = $device.Switch_Port
			$val18 = $device.Source2
			$val19 = $device.source

			# Build SQL Insert Query
			$SQLinsertquery="
					INSERT INTO [Cherwell].[Zingbox]
						([Profile_Type]
						,[Profile_Vertical]
						,[Profile]
						,[Site_Name]
						,[Hostname]
						,[IP_Address]
						,[MAC_Address]
						,[Category]
						,[Vendor]
						,[OS_Group]
						,[OS_Firmware_Version]
						,[Wire_Or_Wireless]
						,[First_Seen_Date]
						,[Last_Activity]
						,[Switch_Name]
						,[Switch_IP]
						,[Switch_Port]
						,[Mon_Disc]
						,[Source])

				VALUES ('$val01'
						,'$val02'
						,'$val03'
						,'$val04'
						,'$val05'
						,'$val06'
						,'$val07'
						,'$val08'
						,'$val09'
						,'$val10'
						,'$val11'
						,'$val12'
						,CAST('$val13' AS DATETIME)
						,CAST('$val14' AS DATETIME)
						,'$val15'
						,'$val16'
						,'$val17'
						,'$val18'
						,'$val19')"

			# execute query
			Invoke-SQLcmd -query $SQLinsertquery -ServerInstance $SQLserver -Database $SQLdatabase -Username $SQLuser -Password $SQLPassword

			# clean up variables
			Clear-Variable -Name "val*"
		
		}
	}
