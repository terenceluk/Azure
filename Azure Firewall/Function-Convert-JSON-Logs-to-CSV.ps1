<# 
The purpose of this Function is convert the files generated by an Azure Firewall diagnostic settings configured to send logs to an Azure Storage Account Container that is written in JSON Line format.

Refer to my blog post for more information: http://terenceluk.blogspot.com/2023/07/converting-azure-firewall-logs-in-json.html
#>

Function Convert-JsonToCSV
{
    param (
      [Parameter(Mandatory = $true)]
      [string]$inputFile,
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

	$pathToJsonFile = $inputFile
	#$pathToJsonFile = "C:\Users\tluk\OneDrive - CCS Group\Documents\Scripts\Azure Firewall Logs\PT1H-1.json"
	$badJson = (Get-Content -Path $pathToJsonFile)

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
	#$pathToOutputFile = "C:\Users\tluk\OneDrive - CCS Group\Documents\Scripts\Azure Firewall Logs\PT1H-1.csv"

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

Convert-JsonToCSV -inputFile "PT1H-Aug-17.json" -outputFile "PT1H-Aug-17.csv"
