# The following function builds the signature used to authorization header that sends a request to the Azure Monitor HTTP Data Collector API
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}

# The following function will create and post the request using the signature created by the Build-Signature function for authorization
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

# Connect to Azure with App Registration Service Principal Secret

# Replace with the App Registration App ID
$servicePrincipalAppID = "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx" 

# Replace with the App Registration secret
$spPassword = "xxxxxxxx-xxxxxxxx_mxxxxxxxxxxx"

# Replace with the Azure AD tenant ID
$tenantID = "xxxxxxb-xxxx-xxxx-xxxx-xxxxxxxxxxx"

# Convert the Service Principal secret to secure string
$password = ConvertTo-SecureString $spPassword -AsPlainText -Force

# Create a new credentials object containing the application ID and password that will be used to authenticate
$psCredentials = New-Object System.Management.Automation.PSCredential ($servicePrincipalAppID, $password)

# Authenticate with the credentials object
Connect-AzAccount -ServicePrincipal -Credential $psCredentials -Tenant $tenantId

# Replace with your Workspace ID
$customerId = "b0d472a3-8c13-4cec-8abb-76051843545f"

# Replace with your Workspace Primary Key
$sharedKey = "D3s71+X0M+Q3cGTHC5I6H6l23xRNAKvjA+yb8JzMQQd3ntxeFZLmMWIMm7Ih/LPMOji9zkXDwavAJLX1xEe/4g=="

# Specify the name of the record type that you'll be creating (this is what will be displayed under Log Analytics > Logs > Custom Logs)
$LogType = "AppRegistrationExpiration"

# Optional name of a field that includes the timestamp for the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
$TimeStampField = ""

# Get the full list of Azure AD App Registrations
$applications = Get-AzADApplication

# Get the full list of Azure AD Enterprise Applications (Service Principals)
$servicePrincipals = Get-AzADServicePrincipal

# Create an array named appWithCredentials
$appWithCredentials = @()

# Populate the array with app registrations that have credentials

# Retrieve the list of applications and sort them by DisplayName
$appWithCredentials += $applications | Sort-Object -Property DisplayName | % {

  # Assign the variable application with the follow list of properties
    $application = $_

    # Retrieve the list of Enterprise Applications (Service Principals) and match the ApplicationID of the SP to the App Registration
    $sp = $servicePrincipals | ? ApplicationId -eq $application.ApplicationId
    Write-Verbose ('Fetching information for application {0}' -f $application.DisplayName)

    # Use the Get-AzADAppCredential cmdlet to get the Certificates & secrets configured (this returns StartDate, EndDate, KeyID, Type, Usage, CustomKeyIdentifier)
    # Populate the array with the DisplayName, ObjectId, ApplicationId, KeyId, Type, StartDate and EndDate of each Certificates & secrets for each App Registration
    $application | Get-AzADAppCredential -ErrorAction SilentlyContinue | Select-Object `
    -Property @{Name='DisplayName'; Expression={$application.DisplayName}}, `
    @{Name='ObjectId'; Expression={$application.ObjectId}}, `
    @{Name='ApplicationId'; Expression={$application.ApplicationId}}, `
    @{Name='KeyId'; Expression={$_.KeyId}}, `
    @{Name='Type'; Expression={$_.Type}},`
    @{Name='StartDate'; Expression={$_.StartDate -as [datetime]}},`
    @{Name='EndDate'; Expression={$_.EndDate -as [datetime]}}
  }

# With the $application array populated with the Certificates & secrets and its App Registration, proceed to calculate and add the fields to each record in the array:
# Expiration of the certificate or secret - Valid or Expired
# Add the timestamp used to calculate the validity
# The days until the certificate or secret expires

Write-output 'Validating expiration data...'
$timeStamp = Get-Date -format o
$today = (Get-Date).ToUniversalTime()
$appWithCredentials | Sort-Object EndDate | % {
  # First if catches certificates & secrets that are expired
        if($_.EndDate -lt $today) {
            $days= ($_.EndDate-$Today).Days
            $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Expired'
            $_ | Add-Member -MemberType NoteProperty -Name 'TimeStamp' -Value "$timestamp"
            $_ | Add-Member -MemberType NoteProperty -Name 'DaysToExpiration' -Value $days
            # Second if catches certificates & secrets that are still valid
        }  else {
            $days= ($_.EndDate-$Today).Days
            $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Valid'
            $_ | Add-Member -MemberType NoteProperty -Name 'TimeStamp' -Value "$timestamp"
            $_ | Add-Member -MemberType NoteProperty -Name 'DaysToExpiration' -Value $days
        }
}

  # Convert the list of each Certificates & secrets for each App Registration into JSON format so we can send it to Log Analytics
  $appWithCredentialsJSON = $appWithCredentials | convertto-json
 
## The following commented lines is a sample JSON that can be used to test sending data to Log Analytics

<# 
$json = @"
[{
    "DisplayName": "Vulcan O365 Audit Logs",
    "ObjectId": "058f1297-ba80-4b9e-8f9c-15febdf85df0",
    "ApplicationId": {
      "value": "ac28a30a-6e5f-4c2d-9384-17bbb0809d57",
      "Guid": "ac28a30a-6e5f-4c2d-9384-17bbb0809d57"
    },
    "KeyId": "2ea30e24-e2ad-44ff-865a-df07199f26a5",
    "Type": "AsymmetricX509Cert",
    "StartDate": "2021-05-29T18:26:46",
    "EndDate": "2022-05-29T18:46:46"
  },
  {
    "DisplayName": "Vulcan O365 Audit Logs",
    "ObjectId": "058f1297-ba80-4b9e-8f9c-15febdf85df0",
    "ApplicationId": {
      "value": "ac28a30a-6e5f-4c2d-9384-17bbb0809d57",
      "Guid": "ac28a30a-6e5f-4c2d-9384-17bbb0809d57"
    },
    "KeyId": "259dbc4d-cdde-4007-a9ed-887437560b15",
    "Type": "AsymmetricX509Cert",
    "StartDate": "2021-05-29T17:46:22",
    "EndDate": "2022-05-29T18:06:22"
  }]
"@
#>

# Submit the data to the API endpoint
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($appWithCredentialsJSON)) -logType $logType  