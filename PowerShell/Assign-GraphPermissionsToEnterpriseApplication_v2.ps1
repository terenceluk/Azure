<#
.SYNOPSIS
    Assigns API permissions to a managed identity for any API (Microsoft Graph, Exchange Online, etc.)

.DESCRIPTION
    This script grants application permissions to an Azure Managed Identity for any API service principal.
    Pass either the API display name (e.g., "Microsoft Graph") or AppId (e.g., "00000002-0000-0ff1-ce00-000000000000" for Exchange Online)

.PARAMETER TenantId
    The Azure AD tenant ID where the managed identity and API are located

.PARAMETER ManagedIdentityObjectId
    The object ID of the managed identity (system-assigned or user-assigned)

.PARAMETER ApiIdentifier
    Either the display name (e.g., "Microsoft Graph") or AppId (e.g., "00000002-0000-0ff1-ce00-000000000000") of the API

.PARAMETER AppRoleNames
    Array of app role names to assign (e.g., "User.Read.All" for Graph, or "Exchange.ManageAsApp" for Exchange Online)

.EXAMPLE
    # Assign Microsoft Graph permissions
    .\Assign-AnyApiPermissions.ps1 -TenantId "12345678-..." -ManagedIdentityObjectId "87654321-..." -ApiIdentifier "Microsoft Graph" -AppRoleNames @("User.Read.All", "Mail.Read")

.EXAMPLE
    # Assign Exchange Online permissions
    .\Assign-AnyApiPermissions.ps1 -TenantId "12345678-..." -ManagedIdentityObjectId "87654321-..." -ApiIdentifier "00000002-0000-0ff1-ce00-000000000000" -AppRoleNames @("Exchange.ManageAsApp")
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityObjectId,
    
    [Parameter(Mandatory = $true)]
    [string]$ApiIdentifier,  # Can be displayName OR appId
    
    [Parameter(Mandatory = $true)]
    [string[]]$AppRoleNames
)

try {
    Import-Module Microsoft.Graph.Applications -ErrorAction Stop
    Write-Host "✅ Microsoft Graph module loaded" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to import Microsoft.Graph module. Install with: Install-Module Microsoft.Graph.Applications"
    exit 1
}

try {
    Write-Host "🔐 Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -TenantId $TenantId -Scopes 'Application.Read.All', 'AppRoleAssignment.ReadWrite.All' -ErrorAction Stop
    Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to connect: $($_.Exception.Message)"
    exit 1
}

try {
    # Find the API service principal by either displayName or appId
    Write-Host "🔍 Looking for API service principal: $ApiIdentifier" -ForegroundColor Yellow
    
    $apiServicePrincipal = $null
    
    # Check if ApiIdentifier looks like a GUID (appId)
    if ($ApiIdentifier -match '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$') {
        # It's an AppId
        $apiServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$ApiIdentifier'" -ErrorAction SilentlyContinue
    }
    else {
        # It's a display name
        $apiServicePrincipal = Get-MgServicePrincipal -Filter "displayName eq '$ApiIdentifier'" -ErrorAction SilentlyContinue
    }
    
    if (-not $apiServicePrincipal) {
        throw "API service principal not found for identifier: $ApiIdentifier"
    }
    
    Write-Host "✅ Found API: $($apiServicePrincipal.DisplayName) (AppId: $($apiServicePrincipal.AppId))" -ForegroundColor Green
    Write-Host "   Object ID: $($apiServicePrincipal.Id)" -ForegroundColor Gray
    
    # Display available roles for this API
    $availableRoles = $apiServicePrincipal.AppRoles | Where-Object { $_.Value } | Select-Object -ExpandProperty Value | Sort-Object
    Write-Host "`n📖 Available app roles for this API (showing first 10):" -ForegroundColor Gray
    $availableRoles | Select-Object -First 10 | ForEach-Object { Write-Host "   • $_" -ForegroundColor DarkGray }
    if ($availableRoles.Count -gt 10) {
        Write-Host "   ... and $($availableRoles.Count - 10) more" -ForegroundColor DarkGray
    }
}
catch {
    Write-Error "❌ Failed to retrieve API service principal: $($_.Exception.Message)"
    exit 1
}

# Verify managed identity exists
try {
    Write-Host "`n🔍 Verifying managed identity..." -ForegroundColor Yellow
    $managedIdentity = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction SilentlyContinue
    
    if (-not $managedIdentity) {
        throw "Managed identity with Object ID '$ManagedIdentityObjectId' not found"
    }
    
    Write-Host "✅ Found managed identity: $($managedIdentity.DisplayName)" -ForegroundColor Green
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
        # Find the app role in the API's roles
        $appRole = $apiServicePrincipal.AppRoles | Where-Object { $_.Value -eq $appRoleName }
        
        if (-not $appRole) {
            Write-Warning "⚠️ App role '$appRoleName' not found in this API."
            $failedCount++
            continue
        }

        # Check if assignment already exists
        $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId |
            Where-Object { $_.ResourceId -eq $apiServicePrincipal.Id -and $_.AppRoleId -eq $appRole.Id }
        
        if ($existingAssignment) {
            Write-Host "ℹ️  App role '$appRoleName' is already assigned" -ForegroundColor Cyan
            $assignedRoles += $appRoleName
            $successCount++
            continue
        }

        # Create the app role assignment
        Write-Host "   Assigning app role..." -ForegroundColor Gray
        $assignmentParams = @{
            ServicePrincipalId = $ManagedIdentityObjectId
            PrincipalId        = $ManagedIdentityObjectId
            ResourceId         = $apiServicePrincipal.Id
            AppRoleId          = $appRole.Id
        }
        
        $newAssignment = New-MgServicePrincipalAppRoleAssignment @assignmentParams -ErrorAction Stop
        Write-Host "✅ Successfully assigned app role '$appRoleName'" -ForegroundColor Green
        $assignedRoles += $appRoleName
        $successCount++
    }
    catch {
        Write-Error "❌ Failed to assign '$appRoleName': $($_.Exception.Message)"
        $failedCount++
    }
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "📊 ASSIGNMENT SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "API: $($apiServicePrincipal.DisplayName)" -ForegroundColor White
Write-Host "✅ Successful: $successCount" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "❌ Failed: $failedCount" -ForegroundColor Red
}

if ($assignedRoles) {
    Write-Host "`n🎯 Successfully assigned roles:" -ForegroundColor Green
    foreach ($role in $assignedRoles) {
        Write-Host "   • $role" -ForegroundColor White
    }
}
