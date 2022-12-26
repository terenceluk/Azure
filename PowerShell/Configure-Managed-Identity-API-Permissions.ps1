<# 
The purpose of this script is to configure a Managed Identity with Graph API permissions

Refer to my blog post for more information and sample purpose: http://terenceluk.blogspot.com/2022/12/updated-create-automated-report-for.html
#>

$TenantID="xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"
$GraphAppId = "00000003-0000-0000-c000-000000000000"
$DisplayNameOfMSI="O365-License-HTML-Reporting"

$permissionsNames = @(
    'Directory.Read.All'
    'Directory.ReadWrite.All'
    'Organization.Read.All'
    'Organization.ReadWrite.All'
)

# Install the AzureAD module and connect to Azure tenant
Install-Module AzureAD
Import-Module AzureAd -UseWindowsPowerShell
Connect-AzureAD -TenantId $TenantID

# Get and store the Enterprise Application Service Principal using its display name
$MSI = (Get-AzureADServicePrincipal -Filter "displayName eq '$DisplayNameOfMSI'")

# Get and store the Graph API GUID 00000003-0000-0000-c000-000000000000 - Use this to get ObjectId
$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"

# Get and store the Microsoft Graph using the Graph API GUID 00000003-0000-0000-c000-000000000000 - Use this to get AppRole ID (this does not contain ObjectId)
$GraphServicePrincipalGraphAPI = Get-AzADServicePrincipal -Filter "appId eq '$GraphAppId'"

# Use a loop to read through the $permissionsNames array and assign each permisson
Foreach ($permission in $permissionsNames) {
    # Assign the $AppRole variable to store each permission to assign
    $AppRole = $GraphServicePrincipalGraphAPI.AppRole | Where-Object {($_.Value -in $permission) -and ($_.AllowedMemberType -contains "Application")}

    # Grant Enterprise Application the required permissions stored in the array
    New-AzureAdServiceAppRoleAssignment -ObjectId $MSI.ObjectId -PrincipalId $MSI.ObjectId `
    -ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole.Id
}
