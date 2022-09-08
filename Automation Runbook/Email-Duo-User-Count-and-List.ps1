<# 
The purpose of this script is retrieve all the users in a Duo tenant, and send a HTML report with the user count and list of users to an email address with SendGrid
The SendGrid API key will be retrieved from an Azure Key Vault
Refer to my blog post for more information: http://terenceluk.blogspot.com/2022/09/using-azure-automation-account-runbook.html
#>

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

# Store the Azure Key Vault name that contains our SendGrid API key in a variable
$VaultName = "kv-Production" # Azure Key Vault Name

# Define the address for report to send to, the from address, and the email subject
$destEmailAddress = "tluk@contoso.com" # From address
$fromEmailAddress = "duoreport@contoso.com" # To address
$subject = "Duo User Report" # Email Subject

# Get Duo information with Duo-PSModule https://github.com/mbegan/Duo-PSModule
$user = duoGetUser
$userCount = $user.Count.toString()

# Convert Duo user to HTML format
$htmlUsers = $user | Select-Object @{Name = "First Name"; Expression = {$_.firstname}},@{Name = "Last Name"; Expression = {$_.lastname}},@{Name = "Email Address"; Expression = {$_.email}},@{Name = "Is Enrolled"; Expression = {$_.is_enrolled}},@{Name = "Full Name"; Expression = {$_.realname}},@{Name = "Status"; Expression = {$_.status}},@{Name = "Username"; Expression = {$_.username}} | ConvertTo-Html

# Set table style and insert Duo user information in table layout
$content = @"
<html><head>
<style>
BODY {font-family:Calibri;}
table {border-collapse: collapse; font-family: Calibri, sans-serif;}
table td {padding: 5px;}
table th {background-color: #6ac154; color: #ffffff; font-weight: bold;	border: 1px solid #54585d; padding: 5px;}
table tbody td {color: #636363;	border: 1px solid #dddfe1;}
table tbody tr {background-color: #e2efd9;}
table tbody tr:nth-child(odd) {background-color: #ffffff;}
</style>
</head>
<title>Duo Usage Report</title>
<h1>Duo Usage Report</h1>
<h2>Client: Contoso Limited</h2>
<h3>The current Duo user count for this tenant is: $userCount <h3>
$htmlUsers
</html>
"@

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext 

# Retrieve SendGrid API secret from Azure Key Vault
$SENDGRID_API_KEY = Get-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name "SendGridAPIKey" `
    -AsPlainText -DefaultProfile $AzureContext

# Configure header with authentication information and content type
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer " + $SENDGRID_API_KEY)
$headers.Add("Content-Type", "application/json")

# Create email
$body = @{
personalizations = @(
    @{
        to = @(
                @{
                    email = $destEmailAddress
                }
        )
    }
)
from = @{
    email = $fromEmailAddress
}

# Set email type as HTML and insert content created earlier that is stored in the $content variable
subject = $subject
content = @(
    @{
        type = "text/html"
        value = $content
    }
)
}

$bodyJson = $body | ConvertTo-Json -Depth 4

$response = Invoke-RestMethod -Uri https://api.sendgrid.com/v3/mail/send -Method Post -Headers $headers -Body $bodyJson