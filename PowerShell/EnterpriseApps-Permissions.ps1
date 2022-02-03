<#

Refer to the following documents for the source of where this script is derived from and the PowerShell cmdlets used:

Assign Users to Azure AD Application with PowerShell
https://lazyadmin.nl/powershell/add-users-to-azure-ad-application-with-powershell/

New-AzureADUserAppRoleAssignment
https://docs.microsoft.com/en-us/powershell/module/azuread/new-azureaduserapproleassignment?view=azureadps-2.0

Get-AzureADUser
https://docs.microsoft.com/en-us/powershell/module/azuread/get-azureaduser?view=azureadps-2.0

Get-AzureADGroupMember
https://docs.microsoft.com/en-us/powershell/module/azuread/get-azureadgroupmember?view=azureadps-2.0

#>

# Connect to Azure AD
Connect-AzureAD

$enterpriseAppName = "MetaCompliance User Provisioning"
$onPremiseADgroup = "All_Staff"

# Get the service principal for the Enterprise Application you want to assign the user to
$servicePrincipal = Get-AzureADServicePrincipal -Filter "Displayname eq '$enterpriseAppName'"

## Use this cmdlet to list the roles available for this Enterprise App: Get-AzureadApplication -SearchString $enterpriseAppName | select Approles | Fl
## Use this cmdlet to list the specific role $servicePrincipal.Approles[0].id

# Get all users that are already assigned to the application
$existingUsers = Get-AzureADServiceAppRoleAssignment -all $true -ObjectId $servicePrincipal.Objectid | select -ExpandProperty PrincipalId

# Get all users from on-prem AD group
$allUsers = Get-AzureADGroup -Filter "DisplayName eq '$onPremiseADgroup'" -All $true | Get-AzureADGroupMember -All $true | Select displayname,objectid

# Compare list of users from the on-premise AD group and list of users already assigned default permissions to the Enterprise Application
$newUsers = $allUsers | Where-Object { $_.ObjectId -notin $existingUsers }

ForEach ($user in $newUsers) {
  Try {
    ## Note that the Id parameter specifies app because this application has two defined roles
    New-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId -PrincipalId $user.ObjectId -ResourceId $servicePrincipal.ObjectId -Id $servicePrincipal.Approles[0].id -ErrorAction Stop
    [PSCustomObject]@{
        UserPrincipalName = $user.displayname
        AppliciationAssigned = $true
    }
  }
  catch {
    [PSCustomObject]@{
        UserPrincipalName = $user.displayname
        AppliciationAssigned = $false
    }
  }
}

