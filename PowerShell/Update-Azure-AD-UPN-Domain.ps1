<# 
The purpose of this script is to update all the accounts in AAD with a defined source domain (in this case the default something.onmicrosoft.com) to a different domain (in this case a new custom domain)
This script will also exclude any Guest accounts and the admin account.

Refer to my blog post for more information: http://terenceluk.blogspot.com/2023/06/powershell-script-for-updating-domain.html
#>

Import-Module AzureAD -UseWindowsPowerShell
Connect-AzureAD

# Set the source and target domain variables
$sourceDomain = "@contoso.onmicrosoft.com"
$targetDomain = "@contoso.com"

# Get all Azure AD users with the specified source domain that are not a guest account and exclude the admin account
$users = Get-AzureADUser -All $true | Where-Object {$_.UserPrincipalName -like "*" + $sourceDomain -and $_.UserType -ne "Guest" -and $_.UserPrincipalName -ne "admin" + $sourceDomain}

foreach ($user in $users) {
    # Construct the new UPN value with the target domain and cast all characters to lower case
    $newUPN = $user.UserPrincipalName.Replace($sourceDomain, $targetDomain).ToLower()

    # Update the user's UPN (User Principal Name)
    Set-AzureADUser -ObjectId $user.ObjectId -UserPrincipalName $newUPN

    Write-Host "Updated UPN for user $($user.DisplayName) from $($user.UserPrincipalName) to $newUPN"
    # Uncomment pause to halt the update after every user to confirm the change is desired
    # Pause
}

Write-Host "The UPN update has completed for $($users.Count) users with the domain $sourceDomain (admin and guest accounts are excluded)"
