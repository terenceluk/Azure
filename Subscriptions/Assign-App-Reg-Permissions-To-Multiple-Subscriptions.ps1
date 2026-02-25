<#
.SYNOPSIS
    Assigns Azure roles to an app registration (service principal) across multiple subscriptions

.DESCRIPTION
    This script assigns specified roles to a service principal across multiple Azure subscriptions using your own credentials via Connect-AzAccount.

.PARAMETER AppId
    The Application (Client) ID of the app registration (required)

.PARAMETER RoleName
    The role to assign. Common roles include:
    - Reader: Read-only access
    - Contributor: Full access except role assignments
    - Owner: Full access including role assignments
    - User Access Administrator: Manage user access
    - Key Vault Reader: Read Key Vault secrets/keys/certificates
    - Key Vault Contributor: Full Key Vault management
    - Storage Blob Data Reader: Read blob storage data
    - Storage Blob Data Contributor: Read/write/delete blob storage data

.PARAMETER SubscriptionIds
    Array of subscription IDs to assign the role to

.PARAMETER SkipExisting
    Switch to skip role assignment if it already exists on the subscription

.PARAMETER WhatIf
    Switch to preview changes without actually assigning roles

.EXAMPLE
    # Basic example - Assign Reader role to a single subscription
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Reader" `
                      -SubscriptionIds @("sub1-id")

.EXAMPLE
    # Assign Reader role to multiple subscriptions
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Reader" `
                      -SubscriptionIds @("sub1-id", "sub2-id", "sub3-id")

.EXAMPLE
    # Assign different roles based on environment
    # Reader for production, Contributor for development
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Reader" `
                      -SubscriptionIds @("prod-sub-id")
    
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Contributor" `
                      -SubscriptionIds @("dev-sub-id", "test-sub-id")

.EXAMPLE
    # Assign Owner role to a subscription (use with caution!)
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Owner" `
                      -SubscriptionIds @("sub1-id")

.EXAMPLE
    # Preview mode - See what would happen without actually assigning
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Contributor" `
                      -SubscriptionIds @("sub1-id", "sub2-id") `
                      -WhatIf

.EXAMPLE
    # Skip existing assignments - Only assign if role not already present
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Reader" `
                      -SubscriptionIds @("sub1-id", "sub2-id") `
                      -SkipExisting

.EXAMPLE
    # Using with variables for better script management
    $config = @{
        AppId = "12345678-1234-1234-1234-123456789012"
        RoleName = "Reader"
        Subscriptions = @("sub1", "sub2", "sub3")
    }
    
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId $config.AppId `
                      -RoleName $config.RoleName `
                      -SubscriptionIds $config.Subscriptions

.EXAMPLE
    # Read subscriptions from a file
    $subscriptions = Get-Content -Path ".\subscriptions.txt"
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Reader" `
                      -SubscriptionIds $subscriptions

.EXAMPLE
    # Bulk assignment across multiple tenants (requires appropriate permissions)
    # First connect to tenant 1
    Connect-AzAccount -Tenant "tenant1-id"
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Reader" `
                      -SubscriptionIds @("sub1-tenant1", "sub2-tenant1")
    
    # Then connect to tenant 2
    Connect-AzAccount -Tenant "tenant2-id"
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                      -RoleName "Reader" `
                      -SubscriptionIds @("sub1-tenant2", "sub2-tenant2")

.EXAMPLE
    # Assign with error handling and logging
    $results = .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "12345678-1234-1234-1234-123456789012" `
                                  -RoleName "Reader" `
                                  -SubscriptionIds @("sub1-id", "sub2-id") 6>*> "assignment_log.txt"

.EXAMPLE
    # Your specific use case - Assign Reader to your App ID across multiple subscriptions
    $subscriptions = @(
        "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # Sub1
        "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # Sub2
        "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Sub3
    )
    
    .\Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1 -AppId "1932409b-c6e5-4cae-a32b-d4d5869a7372" `
                      -RoleName "Reader" `
                      -SubscriptionIds $subscriptions

.EXAMPLE
    # Verify assignments after running
    $subscriptions = @(
        "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    )
    foreach ($subId in $subscriptions) {
        Write-Host "`nChecking subscription: $subId" -ForegroundColor Cyan
        Get-AzRoleAssignment -ServicePrincipalName "1932409b-c6e5-4cae-a32b-d4d5869a7372" `
                             -Scope "/subscriptions/$subId" | 
        Where-Object { $_.RoleDefinitionName -eq "Reader" }
    }

.NOTES
    File Name      : Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1
    Author         : [Your Name]
    Prerequisite   : Azure PowerShell module (Az)
    Version        : 2.0
    
    REQUIREMENTS:
    - Azure PowerShell module (Install-Module -Name Az)
    - Your account needs User Access Administrator or Owner permissions on the subscriptions
    - The app registration must exist in Azure AD before running
    
    TIPS:
    - Use -WhatIf first to preview changes
    - Role assignments may take a few minutes to propagate
    - Check Azure RBAC documentation for available roles
    
.LINK
    https://docs.microsoft.com/en-us/azure/role-based-access-control/
    https://docs.microsoft.com/en-us/powershell/azure/
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    
    [Parameter(Mandatory=$true)]
    [string]$RoleName,
    
    [Parameter(Mandatory=$true)]
    [string[]]$SubscriptionIds,
    
    [switch]$SkipExisting,
    
    [switch]$WhatIf
)

# Function to write colored output with error handling
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    # Validate that the color is a valid ConsoleColor
    $validColors = [System.Enum]::GetNames([System.ConsoleColor])
    
    if ($validColors -contains $Color) {
        Write-Host $Message -ForegroundColor $Color
    }
    else {
        # If invalid color, just write without color
        Write-Host $Message
        Write-Warning "Invalid color '$Color' specified in script. Please check the code."
    }
}

# Function to assign role to a specific scope
function Assign-RoleToScope {
    param(
        [string]$Scope,
        [string]$ScopeType,
        [string]$ScopeName
    )

    try {
        # Check if role assignment already exists
        if ($SkipExisting) {
            $existingAssignment = Get-AzRoleAssignment -ObjectId $servicePrincipalId `
                                                       -RoleDefinitionName $RoleName `
                                                       -Scope $Scope `
                                                       -ErrorAction SilentlyContinue

            if ($existingAssignment) {
                Write-ColorOutput "  ⚠ Role '$RoleName' already assigned to $($ScopeType): $ScopeName" "Yellow"
                return $true
            }
        }

        if ($WhatIf) {
            Write-ColorOutput "  🔍 [WHAT IF] Would assign '$RoleName' role to $($ScopeType): $ScopeName" "Cyan"
            return $true
        }

        # Assign the role
        $roleAssignment = New-AzRoleAssignment -ObjectId $servicePrincipalId `
                                               -RoleDefinitionName $RoleName `
                                               -Scope $Scope `
                                               -ErrorAction Stop

        Write-ColorOutput "  ✅ Successfully assigned '$RoleName' role to $($ScopeType): $ScopeName" "Green"
        return $true
    }
    catch {
        if ($_.Exception.Message -like "*does not exist*") {
            Write-ColorOutput "  ❌ $($ScopeType) '$ScopeName' does not exist or you don't have access" "Red"
        }
        elseif ($_.Exception.Message -like "*does not have authorization*") {
            Write-ColorOutput "  ❌ You don't have permission to assign roles in $($ScopeType): $ScopeName" "Red"
        }
        else {
            Write-ColorOutput "  ❌ Failed to assign role to $($ScopeType) '$ScopeName': $_" "Red"
        }
        return $false
    }
}

# MAIN EXECUTION STARTS HERE
Write-ColorOutput "`n🚀 Azure Role Assignment Script" "Magenta"
Write-ColorOutput ("=" * 50) "Magenta"

# Connect to Azure if not already connected
try {
    $context = Get-AzContext
    if (-not $context -or -not $context.Account) {
        Write-ColorOutput "🔑 Please sign in to Azure..." "Yellow"
        Connect-AzAccount -ErrorAction Stop
    }
    else {
        Write-ColorOutput "✅ Already connected as: $($context.Account.Id)" "Green"
        Write-ColorOutput "📌 Current subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" "Cyan"
    }
}
catch {
    Write-ColorOutput "❌ Failed to connect to Azure: $_" "Red"
    exit 1
}

# Get the service principal
try {
    Write-ColorOutput "`n🔍 Looking up service principal with App ID: $AppId..." "Yellow"
    $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $AppId
    
    if (-not $servicePrincipal) {
        Write-ColorOutput "❌ Service principal with App ID $AppId not found" "Red"
        Write-ColorOutput "   Tip: Make sure the app registration exists in Azure AD" "Yellow"
        exit 1
    }
    
    $servicePrincipalId = $servicePrincipal.Id
    Write-ColorOutput "✅ Found service principal: $($servicePrincipal.DisplayName)" "Green"
    Write-ColorOutput "   Object ID: $servicePrincipalId" "Cyan"
}
catch {
    Write-ColorOutput "❌ Error finding service principal: $_" "Red"
    exit 1
}

# Track results
$successCount = 0
$failureCount = 0
$totalScopes = $SubscriptionIds.Count

Write-ColorOutput "`n📋 Processing $totalScopes subscription(s)..." "Cyan"
Write-ColorOutput ("-" * 50) "Cyan"

# Process each subscription
foreach ($subId in $SubscriptionIds) {
    $scope = "/subscriptions/$subId"
    
    # Get subscription name for better output
    try {
        $subName = (Get-AzSubscription -SubscriptionId $subId -ErrorAction SilentlyContinue).Name
        $displayName = if ($subName) { "$subName ($subId)" } else { $subId }
    }
    catch {
        $displayName = $subId
    }
    
    Write-ColorOutput "`n📁 Processing: $displayName" "White"
    
    # Set the subscription context
    Set-AzContext -SubscriptionId $subId -ErrorAction SilentlyContinue | Out-Null
    
    # Call the assignment function
    if (Assign-RoleToScope -Scope $scope -ScopeType "Subscription" -ScopeName $displayName) {
        $successCount++
    }
    else {
        $failureCount++
    }
}

# Summary
Write-ColorOutput "`n" + ("=" * 50) "Magenta"
Write-ColorOutput "📊 Assignment Summary" "Magenta"
Write-ColorOutput ("=" * 50) "Magenta"
Write-ColorOutput "App ID: $AppId" "White"
Write-ColorOutput "Role: $RoleName" "White"
Write-ColorOutput "Total Subscriptions: $totalScopes" "White"
Write-ColorOutput "✅ Successful: $successCount" "Green"
if ($failureCount -gt 0) {
    Write-ColorOutput "❌ Failed: $failureCount" "Red"
}

if ($WhatIf) {
    Write-ColorOutput "`n⚠ This was a WHAT IF operation - no actual changes were made" "Yellow"
}

Write-ColorOutput "`n✨ Script completed!" "Magenta"
