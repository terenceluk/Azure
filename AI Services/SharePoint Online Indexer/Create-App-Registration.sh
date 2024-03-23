# Script to Create an App Registration with Azure CLI that will be granted application permissions Files.Read.All and Sites.Read.All, then grant admin consent

# Note that: There does not appear to be a way for Azure CLI to configure Platform configurations so you'll need to manually perform the following after the App Registration is created:

# 1. Naviagate to the Authentication tab of the App Registration
# 2. Set Allow public client flows to Yes then select Save.
# 3. Select + Add a platform, then Mobile and desktop applications, then check https://login.microsoftonline.com/common/oauth2/nativeclient, then Configure.

# Login to Azure account with Azure CLI
az login

# Create the app registration with the desired name
$displayName = "dev-aisearch-sp" # Update to desired name
$appRegistration = az ad app create --display-name $displayName | ConvertFrom-Json

# Get current tenant details
$tenantDetails = az account show | ConvertFrom-Json

# Define the Microsoft Graph API Id
$graphId = "00000003-0000-0000-c000-000000000000"

# Define the Application Permission Ids for Files.Read.All and Sites.Read.All
$filesPermissionId = "01d4889c-1287-42c6-ac1f-5d1e02578ef6" # Files.Read.All Permission Id
$sitesPermissionId = "332a536c-c7ef-4017-ab91-336970924f0d" # Sites.Read.All Permission Id

# Delegated permissions
# $filesPermissionId = "df85f4d6-205c-4ac5-a5ea-6bf408dba283" # Files.Read.All Permission Id
#$sitesPermissionId = "205e70e5-aba6-4c52-a976-6d2d46c48043" # Sites.Read.All Permission Id

# Add API permissions (Application Permissions) to the Entra ID App Registration
az ad app permission add --id $appRegistration.appId --api $graphId --api-permissions "$filesPermissionId=Role" "$sitesPermissionId=Role"

# Grant Admin Consent to both permissions
az ad app permission admin-consent --id $appRegistration.appId 

# Create a secret that has a 1 year expiry
$startDate = Get-Date
$endDate = $startDate.AddYears(1).ToString("yyyy-MM-dd")
$secret = az ad app credential reset --id $appRegistration.appId --end-date $endDate | ConvertFrom-Json

# Output the Application (client) ID, client secret, and tenant ID to console
Write-Output "Application (client) ID: $($appRegistration.appId)"
Write-Output "Client Secret: $($secret.password)"
Write-Output "Tenant ID: $($tenantDetails.tenantId)"
