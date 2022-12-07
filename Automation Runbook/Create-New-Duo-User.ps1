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
