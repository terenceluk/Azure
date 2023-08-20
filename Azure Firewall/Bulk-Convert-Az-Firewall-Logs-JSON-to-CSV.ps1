# Install and import the Azure PowerShell module
Install-Module -Name Az.Storage -Force
Import-Module -Name Az.Storage

Connect-AzAccount

# Set the Azure Storage account details
$storageAccountName = "stcaclogafwprod" # Storage account where the Azure Firewall Logs are being sent to
$containerName = "insights-logs-azurefirewall" # Container name where the Azure Firewall Logs are stored
$subscription = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # The subscription ID of the Storage Account
$resourceGroup = "RG-CA-C-VNET-PROD" # The resource group of where the Azure Firewall resource is stored
$azureFirewallName = "AFW-CA-C-PROD" # The name of the Azure Firewall
$storageContainerFolderPath = "resourceId=/SUBSCRIPTIONS/" + $subscription + "/RESOURCEGROUPS/" + $resourceGroup + "/PROVIDERS/MICROSOFT.NETWORK/AZUREFIREWALLS/" + $azureFirewallName + "/"

# Define the year, month, start and end day to traverse
$year = "2023"
$month = "08"
$startDay = "01"
$endDay = "12"

# Create a storage context using the account name after authenticating with Connect-AzAccount
$context = New-AzStorageContext -StorageAccountName $storageAccountName

# Function that will take an input Json object and desired output file name to generate the CSV file from the Json data
Function Convert-JsonToCSV
{
    param (
      [Parameter(Mandatory = $true)]
      $inputJsonObject,
	  [Parameter(Mandatory = $true)]
      [string]$outputFile
  )

	# Add a open [ bracket after properties": 
	# Add a close ] bracket at the end of properties }
	# Add a comma after close } brace for each log entry but exclude last entry
	# Add a bracket at the beginning of the JSON
	# Add a bracket at the end of the JSON

	# Retrieve the daily generated JSON from from the Azure Storage Container "insights-logs-azurefirewall/resourceId/SUBSCRIPTIONS/<subscriptionID>/RESOURCEGROUPS/<resourceGroupName>/PROVIDERS/MICROSOFT.NETWORK/AZUREFIREWALLS/<firewallName>/<y=xxxx>/<m=xx>/<d=xx>/<h=xx>/<m=00>/PT1H.json"

	# Step #1 - Open the original Azure Firewall JSON (does not conform to RFC 8259) and add the missing [] for properties

    $badJson = $inputJsonObject

	# Define the regex pattern that will match the contents of properties to insert brackets
	$regexPattern = '(?<="properties": )([\s\S]*?})'

	# Add the matched properties blocks with brackets
	$fixedJson = [regex]::Replace($badJson, $regexPattern, { param($match) "[{0}]" -f $match.Value })

	# Step #2 - Continue to fix the missing comma between each log entry

	# Store the previous fixed JSON as bad JSON
	$badJson = $fixedJson

	# Define the regex pattern that will match the log entries not separated with commas
	$regexPattern = '(?="category": )([\s\S]*?}[\s\S]*?][\s\S]*?}\W)'

	# Add the missing comma into each log entry
	$fixedJson = [regex]::Replace($badJson, $regexPattern, { param($match) "{0}," -f $match.Value })

	# Step #3 - Add an open [ bracket to beginning and a close ] bracket to the end

	# Store the previous fixed JSON as bad JSON
	$badJson = $fixedJson

	# Define the regex pattern that will match the full content
	$regexPattern = '^([^$]+)'

	# Add the missing open and close brackets to the full content
	$fixedJson = [regex]::Replace($badJson, $regexPattern, { param($match) "[{0}]" -f $match.Value })

	# Begin parsing through RFC 8259 valid JSON to create CSV extract

	# Define output CSV file name and path
	$pathToOutputFile = $outputFile

	# Create Array
	$Properties = @()

	# Store fixed RFC 8259 JSON
	$fixedJson | ConvertFrom-Json | ForEach-Object {

	# Define first level fields
	$Category = $_.category
	[DateTime] $Time = $_.time
	#$ResourceId = $_.resourceId # Skip Resource ID
	$OperationName = $_.operationName # AzureFirewallDnsProxy

	# Parse through and store Properties fields
	$Properties += $_.Properties | ForEach-Object {
		[pscustomobject] @{
			'Category' = $Category
			'Time' = $Time
			#'resourceId' = $ResourceId # Skip Resource ID
			'OperationName' = $OperationName # AzureFirewallDnsProxy
			'SourceIp' = $_.SourceIp
			'SourcePort '= $_.SourcePort
			'QueryId' = $_.QueryId
			'QueryType' = $_.QueryType
			'QueryClass' = $_.QueryClass
			'QueryName' = $_.QueryName
			'Protocol' = $_.Protocol
			'DestinationIP' = $_.DestinationIP # AZFWNetworkRule
			'DestinationPort' = $_.DestinationPort # AZFWNetworkRule
			'Fqdn' = $_.Fqdn # AZFWApplicationRule
			'TargetUrl' = $_.TargetUrl # AZFWApplicationRule
			'Action' = $_.Action # AZFWNetworkRule
			'Policy' = $_.Policy # AZFWNetworkRule
			'RuleCollectionGroup' = $_.RuleCollectionGroup # AZFWNetworkRule
			'RuleCollection' = $_.RuleCollection # AZFWNetworkRule
			'Rule' = $_.Rule # AZFWNetworkRule
			'ActionReason' = $_.ActionReason # AZFWNetworkRule
			'IsTlsInspected' = $_.IsTlsInspected # AZFWApplicationRule
			'WebCategory' = $_.WebCategory # AZFWApplicationRule
			'IsExplicitProxyRequest' = $_.IsExplicitProxyRequest # AZFWApplicationRule
			'RequestSize' = $_.RequestSize
			'DnssecOkBit' = $_.DnssecOkBit
			'EDNS0BufferSize' = $_.EDNS0BufferSize
			'ResponseCode' = $_.ResponseCode
			'ResponseFlags' = $_.ResponseFlags
			'ResponseSize' = $_.ResponseSize
			'RequestDurationSecs' = $_.RequestDurationSecs
			'ErrorNumber' = $_.ErrorNumber
			'ErrorMessage' = $_.ErrorMessage
			'Msg' = $_.msg # AzureFirewallDnsProxy, AzureFirewallNetworkRule
			}
		}
	}

	# Export to CSV
	$Properties | Export-CSV $pathToOutputFile -NoTypeInformation
}

# Recursive function to traverse through folders in the storage account beginning with the folder path provided
function Traverse-Folders {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Folder
    )

    # List the files in the current folder
    $files = Get-AzStorageBlob -Container $containerName -Context $context -Prefix $Folder

    foreach ($file in $files) {
        # Check if the file is a JSON file
        if ($file.Name -match '\.json$') {
            Write-Host "Processing file: $($file.Name)"

			# Define the regex pattern that will locate the day by extracting the two digits after d=
			$regexPattern = '(?<=d=)(\d\d)'

			# Return the hour value
			$day = $($file.Name) -match $regexPattern
			#Write-Host "The file name variable is: " $($file.Name)
			#Write-Host "The day value is:" $matches[1]
            $day = $matches[1]
			
			# Define the regex pattern that will locate the hour by extracting the two digits after h=
			$regexPattern = '(?<=h=)(\d\d)'

			# Return the hour value
			$hour = $($file.Name) -match $regexPattern
			#Write-Host "The hour value is:" $matches[1]
            $hour = $matches[1]
			
            # Read the JSON content from the file
            $jsonContent = $file.ICloudBlob.DownloadText()

            # Process the JSON content as needed
            # Define the file name with the year, month, day parameter and add the hour to the file
            $outputFileName = "Firewall-Log-" + $year + "-" + $month + "-" + $day + "-Hour" + $hour + ".csv"
            Convert-JsonToCSV -inputJsonObject $jsonContent -outputFile $outputFileName
            
        }
    }
}

# Start traversing folders defined by start and end day

for ($folderDay = [int]$startDay; $folderDay -le [int]$endDay; $folderDay++ )
{
	# Output Troubleshooting
    # Write-Host "FolderDay is:" $folderDay

    # Handle the requirement for 0 for single digits
    if ($folderDay -lt 10) {
        # Add a 0 if the folder value is less than 10
        $folderPath = "0" + $folderDay
    } else {
        # If the folder value is less than 10 then we don't need to add a 0
        $folderPath = $folderDay
    }

    # Set the folder path depending on which day the loop is on
    $rootFolder = $storageContainerFolderPath + "y=$year/m=$month/d=$folderPath"
    # Execute Function and send path over
    Traverse-Folders -Folder $rootFolder
}
