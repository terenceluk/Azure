<# 
The purpose of this script is to obtain a user's samAccountName and mobile number to:
1. Create a new generic smartphone in Duo
2. Get the Duo user object
3. Assign Duo user object with the generic smartphone in Duo
4. Send SMS activation to user

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
        
        # Retrieve PS Object items and convert to string to store in variable
        $username = $bodyData.samAccountName | out-string
        $mobile = $bodyData.mobile | out-string

        # Clean up mobile number by removing the "-" and trimming beginning and ending whitespace
        $mobile = $mobile -replace '-','' # remove the "-"
        $mobile.Trim() # remove starting and ending whitespace

        # Define platform type as a generic smartphone
        $platformType = "generic smartphone" # Set Platform Type for creating new phone

        # Create new unassociated phone
        $newPhone = duoCreatePhone -number $mobile -type mobile -platform $platformType

        # Get the user object with username
        $newUser = duoGetUser -username $username

        # Associated the new phone to new user
        duoAssocUserToPhone -user_id $newUser.user_id -phone_id $newPhone.phone_id

        # Send Duo SMS activation to phone via number
        duoSendSMSActivation -phone_id $newPhone.phone_id

        Return
    }

    # Retrieve JSON object passed and convert to PS Object                   
	$bodyData = ConvertFrom-Json -InputObject $WebHookData.RequestBody
    
    # Retrieve PS Object items and convert to string to store in variable
    $username = $bodyData.samAccountName | out-string
    $mobile = $bodyData.mobile | out-string

    # Clean up mobile number by removing the "-" and trimming beginning and ending whitespace
    $mobile = $mobile -replace '-','' # remove the "-"
    $mobile.Trim() # remove starting and ending whitespace

    # Define platform type as a generic smartphone
    $platformType = "generic smartphone" # Set Platform Type for creating new phone

    # Create new unassociated phone
    $newPhone = duoCreatePhone -number $mobile -type mobile -platform $platformType

    # Get the user object with username
    $newUser = duoGetUser -username $username

    # Associated the new phone to new user
    duoAssocUserToPhone -user_id $newUser.user_id -phone_id $newPhone.phone_id

    # Send Duo SMS activation to phone via number
    duoSendSMSActivation -phone_id $newPhone.phone_id
}
else {
    Write-Output 'No data received'
}

<# Test the Webhook
$uri = 'https://d36f1e53-eabe-33ee-82d1-34e3b90d5b52.webhook.eus.azure-automation.net/webhooks?token=x1WEKX%2f%2bL%2f%2fz2pX%2fBeSx3UqNii7GTUe3slxAVIhA0PU%3d'
$headerMessage = @{ message = "Testing Webhook"}
$data = @(
    @{ samAccountName="jsmith"},
    @{ mobile = "+14163243445"}
)
$body = ConvertTo-Json -InputObject $data
$response = Invoke-Webrequest -method Post -uri $uri -header $headerMessage -Body $body -UseBasicParsing 
$response
#>
