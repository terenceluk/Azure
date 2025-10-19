<#
.SYNOPSIS
    Checks user passwords for expiration and sends warnings for expiring passwords.

.DESCRIPTION
    This script connects to Microsoft Graph, retrieves all enabled users, and checks their password expiration status based on the configured maximum password age. It can optionally exclude specific email addresses from the check.

.PARAMETER PasswordMaxAgeDays
    The maximum password age in days. Default is 90 days.

.PARAMETER WarningDays
    The number of days before expiration to start warning. Default is 14 days.

.PARAMETER ExcludeEmails
    Optional array of email addresses to exclude from password expiration checks.

.EXAMPLE
    # Default usage (no exclusions)
    .\PasswordExpirationCheck.ps1

.EXAMPLE
    # Exclude specific email addresses
    .\PasswordExpirationCheck.ps1 -ExcludeEmails @("admin@company.com", "service.account@company.com")

.EXAMPLE
    # Exclude single email address
    .\PasswordExpirationCheck.ps1 -ExcludeEmails "test.user@company.com"

.EXAMPLE
    # Combine with other parameters
    .\PasswordExpirationCheck.ps1 -PasswordMaxAgeDays 60 -WarningDays 7 -ExcludeEmails @("user1@company.com", "user2@company.com")

.EXAMPLE
    # Exclude multiple emails and use different password age
    .\PasswordExpirationCheck.ps1 -PasswordMaxAgeDays 45 -WarningDays 10 -ExcludeEmails @("service@company.com", "admin@company.com", "noreply@company.com")

.EXAMPLE
    # Use the following format when testing in a Automation Account Runbook
    ["john.smith@contoso.com","mary.jane@contoso.com"]
#>

param(
    [int]$PasswordMaxAgeDays = 90,
    [int]$WarningDays = 14,
    [string[]]$ExcludeEmails = @()
)

Import-Module -Name Microsoft.Graph.Authentication
Import-Module -Name Microsoft.Graph.Users

Connect-MgGraph -Identity -NoWelcome

try {
    $allUsers = Get-MgUser -Filter "accountEnabled eq true" -All -Property "Id,DisplayName,Mail,UserPrincipalName,LastPasswordChangeDateTime"
    
    $internalUsers = $allUsers | Where-Object { 
        $_.UserPrincipalName -notlike "*#EXT#*" -and 
        $_.Mail -and 
        $_.LastPasswordChangeDateTime
    }
    
    # Filter out excluded emails if any are provided
    if ($ExcludeEmails.Count -gt 0) {
        $internalUsers = $internalUsers | Where-Object { 
            $_.Mail -notin $ExcludeEmails -and 
            $_.UserPrincipalName -notin $ExcludeEmails
        }
    }
    
    $usersToWarn = @()
    $expiredCount = 0
    $expiringSoonCount = 0
    
    foreach ($user in $internalUsers) {
        $expiryDate = $user.LastPasswordChangeDateTime.AddDays($PasswordMaxAgeDays)
        $daysUntilExpiry = [math]::Floor(($expiryDate - (Get-Date)).TotalDays)
        
        if ($daysUntilExpiry -le $WarningDays) {
            $userObj = [PSCustomObject]@{
                Id = $user.Id
                DisplayName = $user.DisplayName
                Mail = $user.Mail
                UserPrincipalName = $user.UserPrincipalName
                LastPasswordChange = $user.LastPasswordChangeDateTime
                ExpiryDate = $expiryDate
                DaysUntilExpiry = $daysUntilExpiry
                Status = if ($daysUntilExpiry -lt 0) { "Expired" } elseif ($daysUntilExpiry -eq 0) { "Expires Today" } else { "Expiring Soon" }
            }
            $usersToWarn += $userObj
            
            if ($daysUntilExpiry -lt 0) {
                $expiredCount++
            } else {
                $expiringSoonCount++
            }
        }
    }

    # Create a clean summary object
    $summary = [PSCustomObject]@{
        Summary = [PSCustomObject]@{
            TotalUsersProcessed = $allUsers.Count
            InternalUsers = $internalUsers.Count
            UsersToWarnCount = $usersToWarn.Count
            ExpiredCount = $expiredCount
            ExpiringSoonCount = $expiringSoonCount
            ExcludedEmailsCount = $ExcludeEmails.Count
            Timestamp = Get-Date
        }
        UsersToWarnList = $usersToWarn
    }

    # CSV Export for troubleshooting
    # $usersToWarn | Export-Csv -Path "$env:TEMP\PasswordWarnings_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation

    # Convert to JSON with proper formatting
    $summary | ConvertTo-Json -Depth 10
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    throw
}
