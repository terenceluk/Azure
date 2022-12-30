<# 
The purpose of this script is to obtain a user's samAccountName, email address, and full name to manually create an account the Duo via the Admin API
This code will ignore any accounts passed with a number beginning with "+1555" and "+555"
Refer to my blog post for more information: http://terenceluk.blogspot.com/2022/12/adding-new-user-in-duo-with-azure.html
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
        
        # Using variable to store whether the mobile number key exists or assigned a ficticous # in the hashtable
        $mobileExists = $bodyData.mobile -ne $null -and $bodydata.mobile -notlike "+1555*" -and $bodydata.mobile -notlike "+555*"

        # Retrieve PS Object items and convert to string to store in variable
        $samAccountName = $bodyData.samAccountName | out-string
        $email = $bodyData.email | out-string
        $fullname = $bodyData.fullname | out-string

        # Only attempt to convert the mobile number to string if it a exists
        If ($mobileExists) { $mobile = $bodyData.mobile | out-string }
        $platformType = "generic smartphone" # Set Platform Type for creating new phone

        # Create new user
        $newUser = duoCreateUser -username $samAccountName -email $email -realname $fullname -status active

        If ($mobileExists) {
        # Create new unassociated phone
        $newPhone = duoCreatePhone -number $mobile -type mobile -platform $platformType

        # Associated new phone to new user
        duoAssocUserToPhone -user_id $newUser.user_id -phone_id $newPhone.phone_id

        # Send Duo SMS activation to phone via number
        duoCreateActivationCode -phone_id $newPhone.phone_id
        } else {
            Write-Host "No phone number recieved so no phone is created."
        }

        Return
    }

    # Retrieve JSON object passed and convert to PS Object                   
	$bodyData = ConvertFrom-Json -InputObject $WebHookData.RequestBody
    
    # Using variable to store whether the mobile number key exists or assigned a ficticous # in the hashtable
    $mobileExists = $bodyData.mobile -ne $null -and $bodydata.mobile -notlike "+1555*" -and $bodydata.mobile -notlike "+555*"

    # Retrieve PS Object items and convert to string to store in variable
    $samAccountName = $bodyData.samAccountName | out-string
    $email = $bodyData.email | out-string
    $fullname = $bodyData.fullname | out-string

    # Only attempt to convert the mobile number to string if it a exists
    If ($mobileExists) { $mobile = $bodyData.mobile | out-string }
    $platformType = "generic smartphone" # Set Platform Type for creating new phone

    # Create new user
    $newUser = duoCreateUser -username $samAccountName -email $email -realname $fullname -status active

    If ($mobileExists) {
    # Create new unassociated phone
    $newPhone = duoCreatePhone -number $mobile -type mobile -platform $platformType

    # Associated new phone to new user
    duoAssocUserToPhone -user_id $newUser.user_id -phone_id $newPhone.phone_id

    # Send Duo SMS activation to phone via number
    duoCreateActivationCode -phone_id $newPhone.phone_id
    } else {
        Write-Host "No phone number recieved so no phone is created."
    }
}
else {
    Write-Output 'No data received'
}

<# Test the Webhook
$uri = 'https://d36f1e53-eabe-4b85-82d1-4710b90d5b52.webhook.eus.azure-automation.net/webhooks?token=x1WEKX%2f%2bL%2f%2fz2pX%2fBcJx3UqNii7GTU3T8lxAVIhA0PU%3d'
$headerMessage = @{ message = "Testing Webhook"}
$data = @(
    @{ samAccountName="jsmith"},
    @{ email = "jsmith@bma.bm"},
    @{ fullname = "John Smith"},
    @{ mobile = "+14413243445"}
)
$body = ConvertTo-Json -InputObject $data
$response = Invoke-Webrequest -method Post -uri $uri -header $headerMessage -Body $body -UseBasicParsing 
$response
#>
