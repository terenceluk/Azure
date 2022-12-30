<# 
The purpose of this script is to manually initiate a Directory Sync from Duo Admin to retrieve a user that was added to an Azure AD group for Duo MFA
Refer to my blog post for more information: 
#>

param (
    [Parameter (Mandatory = $false)]
    [object] $WebHookData
)

if ($WebHookData){

	$duoIntegrationKey = Get-AutomationVariable -Name MyDuoIntegrationKey
	$duoSecretKey = Get-AutomationVariable -Name MyDuoSecretKey
	$duoApiHostname = Get-AutomationVariable -Name MyDuoAPIHostname
	$duoDirectorID = Get-AutomationVariable -Name MyDuoDirectoryID

	[string]$DuoDefaultOrg = "prod"

	[Hashtable]$DuoOrgs = @{
                        prod = [Hashtable]@{
                                iKey  = [string]$duoIntegrationKey
                                sKey = [string]$duoSecretKey
                                apiHost = [string]$duoApiHostname
                                directory_key = [string]$duoDirectorID
                               }
                       }
  
    # If section for testing where webhook data is provided in the Azure portal's "Test pane"
    if (-Not $WebhookData.RequestBody) {
        Write-Output 'No request body from test pane, input object supplied from Azure Portal'
        $WebhookData = (ConvertFrom-JSON -InputObject $WebhookData)

        Write-Output "WebhookData = $WebhookData"
        $bodyData = (ConvertFrom-JSON -InputObject $WebhookData.RequestBody)
        $emailAddress = $($bodyData.emailAddress)
        duoSyncUser -username $emailAddress

        Return
    }

    # Retrieve JSON object passed and convert to PS Object                   
	  $bodyData = ConvertFrom-Json -InputObject $WebHookData.RequestBody
    
    # Retrieve user email address passed to web hook                   
	  $emailAddress = $bodyData.emailAddress | out-string

    # Sync newly created user that was added to the Azure AD Duo MFA Sync group synced from on-premise AD Group
    duoSyncUser -username $emailAddress
}
else {
    Write-Output 'No data received'
}

<# Test the Webhook
$uri = 'https://4dfd44f2-53ba-3333-85fa-aeeeedc77efa.webhook.yq.azure-automation.net/webhooks?token=ffToKssZDTwdqHzgdb7wecDz2XFHLX%2fl5ZjHk5xyhrA%3d'
$headerMessage = @{ message = "Testing Webhook"}
# Format details https://learn.microsoft.com/en-us/azure/automation/automation-webhooks?tabs=portal#use-a-webhook
$data = (@{emailAddress="tluk@bcontoso"})
$body = ConvertTo-Json -InputObject $data
$response = Invoke-Webrequest -method Post -uri $uri -header $headerMessage -Body $body -UseBasicParsing 
$response
#>

<# Use the following in the "Test pane" for testing via the Azure Portal
{
    "WebhookName": "Duo Sync Web Hook",
    "RequestBody": "{\"emailAddress\": \"tluk@contoso.com\" }"
}
#>
