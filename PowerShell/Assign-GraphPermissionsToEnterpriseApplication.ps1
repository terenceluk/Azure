<#
.SYNOPSIS
    Assigns Microsoft Graph API permissions to a managed identity

.DESCRIPTION
    This script grants application permissions to an Azure Managed Identity for Microsoft Graph API access.
    Application permissions (app roles) allow the managed identity to access data without user context.

.PARAMETER TenantId
    The Azure AD tenant ID where the managed identity and Microsoft Graph are located

.PARAMETER ManagedIdentityObjectId
    The object ID of the managed identity (system-assigned or user-assigned)

.PARAMETER AppRoleNames
    Array of Microsoft Graph app role names to assign. See examples below.

.EXAMPLE
    # Assign basic read permissions for users and calendars
    .\Assign-GraphPermissions.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -ManagedIdentityObjectId "87654321-4321-4321-4321-210987654321" -AppRoleNames @("User.Read.All", "Calendars.ReadWrite")

.EXAMPLE
    # Assign permissions for a mail-processing application
    .\Assign-GraphPermissions.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -ManagedIdentityObjectId "87654321-4321-4321-4321-210987654321" -AppRoleNames @("Mail.Read", "Mail.ReadWrite", "Mail.Send")

.EXAMPLE
    # Assign permissions for a comprehensive HR application
    .\Assign-GraphPermissions.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -ManagedIdentityObjectId "87654321-4321-4321-4321-210987654321" -AppRoleNames @("User.Read.All", "Group.Read.All", "Directory.Read.All")

.EXAMPLE
    # Assign permissions for a Teams bot or integration
    .\Assign-GraphPermissions.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -ManagedIdentityObjectId "87654321-4321-4321-4321-210987654321" -AppRoleNames @("Team.ReadBasic.All", "Channel.Read.All", "Chat.ReadWrite")

.EXAMPLE
    # Assign permissions for a security monitoring tool
    .\Assign-GraphPermissions.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -ManagedIdentityObjectId "87654321-4321-4321-4321-210987654321" -AppRoleNames @("SecurityEvents.ReadWrite.All", "ThreatIndicators.ReadWrite.OwnedBy")

.NOTES
    COMMON MICROSOFT GRAPH APP ROLE NAMES BY CATEGORY:

    👤 USER MANAGEMENT:
      - User.Read.All                    - Read all users' full profiles
      - User.ReadWrite.All               - Read and write all users' full profiles
      - User.Invite.All                  - Guest user invitation
      - User.Export.All                  - Export user data
      - User.ManageIdentities.All        - Manage user identities

    👥 GROUP MANAGEMENT:
      - Group.Read.All                   - Read all groups
      - Group.ReadWrite.All              - Read and write all groups
      - GroupMember.Read.All             - Read group memberships
      - GroupMember.ReadWrite.All        - Add/remove group members

    📧 MAIL AND CALENDAR:
      - Mail.Read                        - Read mail in all mailboxes
      - Mail.ReadWrite                   - Read and write mail in all mailboxes
      - Mail.Send                        - Send mail as any user
      - MailboxSettings.ReadWrite        - Manage mailbox settings
      - Calendars.Read                   - Read all calendars
      - Calendars.ReadWrite              - Read and write all calendars
      - Contacts.Read                    - Read all contacts
      - Contacts.ReadWrite               - Read and write all contacts

    🏢 DIRECTORY AND ORGANIZATION:
      - Directory.Read.All               - Read directory data
      - Directory.ReadWrite.All          - Read and write directory data
      - Organization.Read.All            - Read organization information
      - Policy.Read.All                  - Read organization policies

    💬 TEAMS AND COLLABORATION:
      - Team.ReadBasic.All               - Read basic team information
      - Team.Read.All                    - Read all teams
      - Team.ReadWrite.All               - Read and write all teams
      - Channel.Read.All                 - Read all channels
      - Channel.ReadWrite.All            - Read and write all channels
      - Chat.Read                        - Read chats
      - Chat.ReadWrite                   - Read and write chats
      - Calls.JoinGroupCall.All          - Join group calls

    📊 REPORTS AND ANALYTICS:
      - Reports.Read.All                 - Read all usage reports
      - ServiceHealth.Read.All           - Read service health information
      - ServiceMessage.Read.All          - Read service messages

    🔐 SECURITY AND COMPLIANCE:
      - SecurityEvents.Read.All          - Read security events
      - SecurityEvents.ReadWrite.All     - Read and write security events
      - ThreatIndicators.ReadWrite.OwnedBy - Manage threat indicators
      - AuditLog.Read.All                - Read audit logs

    📁 FILES AND CONTENT:
      - Files.Read.All                   - Read all files
      - Files.ReadWrite.All              - Read and write all files
      - Sites.Read.All                   - Read all SharePoint sites
      - Sites.ReadWrite.All              - Read and write all SharePoint sites

    📋 TASKS AND PLANNER:
      - Tasks.Read.All                   - Read all tasks
      - Tasks.ReadWrite.All              - Read and write all tasks
      - Planner.Read.All                 - Read all Planner plans
      - Planner.ReadWrite.All            - Read and write all Planner plans

    ⚙️ DEVICE MANAGEMENT:
      - Device.Read.All                  - Read all devices
      - Device.ReadWrite.All             - Read and write all devices
      - DeviceManagementApps.Read.All    - Read device management apps
      - DeviceManagementConfiguration.ReadWrite.All - Manage device configuration

    IMPORTANT:
    - Application permissions are highly privileged - only assign what's needed
    - Some permissions may require admin consent
    - Review the principle of least privilege when assigning permissions
    - Test permissions in a non-production environment first
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityObjectId,
    
    [Parameter(Mandatory = $true)]
    [string[]]$AppRoleNames = @("User.Read.All", "Calendars.ReadWrite")
)

# Display selected permissions for confirmation
Write-Host "🎯 Selected App Roles:" -ForegroundColor Cyan
foreach ($role in $AppRoleNames) {
    Write-Host "   • $role" -ForegroundColor White
}
Write-Host ""

try {
    # Import required modules
    Import-Module Microsoft.Graph.Applications -ErrorAction Stop
    Write-Host "✅ Microsoft Graph module loaded successfully" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to import Microsoft.Graph module. Please install with: Install-Module Microsoft.Graph.Applications"
    exit 1
}

try {
    # Connect to Microsoft Graph
    Write-Host "🔐 Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -TenantId $TenantId -Scopes 'Application.Read.All', 'AppRoleAssignment.ReadWrite.All' -ErrorAction Stop
    Write-Host "✅ Successfully connected to Microsoft Graph" -ForegroundColor Green
    
    # Get current context to verify connection
    $context = Get-MgContext
    Write-Host "   Connected as: $($context.Account)" -ForegroundColor Cyan
    Write-Host "   Tenant ID: $($context.TenantId)" -ForegroundColor Cyan
}
catch {
    Write-Error "❌ Failed to connect to Microsoft Graph: $($_.Exception.Message)"
    exit 1
}

try {
    # Get Microsoft Graph service principal
    Write-Host "📋 Retrieving Microsoft Graph service principal..." -ForegroundColor Yellow
    $serverServicePrincipal = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'" -ErrorAction Stop
    
    if (-not $serverServicePrincipal) {
        throw "Microsoft Graph service principal not found"
    }
    
    Write-Host "✅ Found Microsoft Graph (Object ID: $($serverServicePrincipal.Id))" -ForegroundColor Green
    
    # Display available roles for reference (first 10)
    $availableRoles = $serverServicePrincipal.AppRoles.Value | Sort-Object
    Write-Host "📖 Available app roles in Microsoft Graph (showing first 10):" -ForegroundColor Gray
    $availableRoles | Select-Object -First 10 | ForEach-Object { Write-Host "   • $_" -ForegroundColor DarkGray }
    if ($availableRoles.Count -gt 10) {
        Write-Host "   ... and $($availableRoles.Count - 10) more" -ForegroundColor DarkGray
    }
}
catch {
    Write-Error "❌ Failed to retrieve Microsoft Graph service principal: $($_.Exception.Message)"
    exit 1
}

# Verify managed identity exists
try {
    Write-Host "🔍 Verifying managed identity..." -ForegroundColor Yellow
    $managedIdentity = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction SilentlyContinue
    
    if (-not $managedIdentity) {
        throw "Managed identity with Object ID '$ManagedIdentityObjectId' not found"
    }
    
    Write-Host "✅ Found managed identity: $($managedIdentity.DisplayName)" -ForegroundColor Green
    Write-Host "   Object ID: $ManagedIdentityObjectId" -ForegroundColor Gray
}
catch {
    Write-Error "❌ Managed identity verification failed: $($_.Exception.Message)"
    exit 1
}

# Process each app role
$successCount = 0
$failedCount = 0
$assignedRoles = @()

foreach ($appRoleName in $AppRoleNames) {
    Write-Host "`n🔄 Processing app role: $appRoleName" -ForegroundColor Yellow
    
    try {
        # Find the app role
        $appRole = $serverServicePrincipal.AppRoles | Where-Object { $_.Value -eq $appRoleName }
        
        if (-not $appRole) {
            Write-Warning "⚠️ App role '$appRoleName' not found in Microsoft Graph."
            $failedCount++
            continue
        }

        # Check if assignment already exists
        $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId |
            Where-Object { $_.ResourceId -eq $serverServicePrincipal.Id -and $_.AppRoleId -eq $appRole.Id }
        
        if ($existingAssignment) {
            Write-Host "ℹ️  App role '$appRoleName' is already assigned to the managed identity" -ForegroundColor Cyan
            $assignedRoles += $appRoleName
            $successCount++
            continue
        }

        # Create the app role assignment
        Write-Host "   Assigning app role..." -ForegroundColor Gray
        $assignmentParams = @{
            ServicePrincipalId = $ManagedIdentityObjectId
            PrincipalId        = $ManagedIdentityObjectId
            ResourceId         = $serverServicePrincipal.Id
            AppRoleId          = $appRole.Id
        }
        
        $newAssignment = New-MgServicePrincipalAppRoleAssignment @assignmentParams -ErrorAction Stop
        Write-Host "✅ Successfully assigned app role '$appRoleName'" -ForegroundColor Green
        $assignedRoles += $appRoleName
        $successCount++
    }
    catch {
        Write-Error "❌ Failed to assign app role '$appRoleName': $($_.Exception.Message)"
        $failedCount++
    }
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "📊 ASSIGNMENT SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "✅ Successful assignments: $successCount" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "❌ Failed assignments: $failedCount" -ForegroundColor Red
}
Write-Host "📋 Total roles processed: $($AppRoleNames.Count)" -ForegroundColor Cyan

if ($assignedRoles) {
    Write-Host "`n🎯 Successfully assigned roles:" -ForegroundColor Green
    foreach ($role in $assignedRoles) {
        Write-Host "   • $role" -ForegroundColor White
    }
}

if ($failedCount -eq 0 -and $successCount -gt 0) {
    Write-Host "`n🎉 All app roles assigned successfully!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Some assignments may have failed. Please review the errors above." -ForegroundColor Yellow
}

# Disconnect (optional)
Write-Host "`n🔓 You can disconnect with: Disconnect-MgGraph" -ForegroundColor Gray
