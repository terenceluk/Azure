# Connect to Azure
Connect-AzAccount

# Get the PrincipalId using your method
$principalId = (Get-AzResource -Name "logic-update-azfw-custom-vnet-subnet-table" -ResourceType "Microsoft.Logic/workflows").Identity.PrincipalId # Update with Logic App name

Write-Host "PrincipalId: $principalId" -ForegroundColor Green

if ([string]::IsNullOrEmpty($principalId)) {
    Write-Host "ERROR: PrincipalId is empty! Check if system-assigned identity is enabled on the Logic App." -ForegroundColor Red
    exit
}

# Get the service principal
$servicePrincipal = Get-AzADServicePrincipal -ObjectId $principalId

if ($null -eq $servicePrincipal) {
    Write-Host "ERROR: Could not find service principal with ObjectId: $principalId" -ForegroundColor Red
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Wait 2-3 minutes if identity was just enabled" -ForegroundColor Cyan
    Write-Host "2. Check service principals with: Get-AzADServicePrincipal | Where-Object DisplayName -like '*logic-update*'" -ForegroundColor Cyan
    exit
}

$objectId = $servicePrincipal.Id
Write-Host "Service Principal ObjectId for role assignment: $objectId" -ForegroundColor Green

# Get all subscriptions
$subscriptions = Get-AzSubscription

Write-Host "`nAssigning Reader role across $($subscriptions.Count) subscription(s)..." -ForegroundColor Yellow

foreach ($sub in $subscriptions) {
    Write-Host "`nProcessing: $($sub.Name) ($($sub.Id))" -ForegroundColor Cyan
    
    # Switch context
    Set-AzContext -Subscription $sub.Id -ErrorAction Stop
    
    # Check if assignment already exists
    $existingAssignment = Get-AzRoleAssignment -ObjectId $objectId -Scope "/subscriptions/$($sub.Id)" -RoleDefinitionName "Reader" -ErrorAction SilentlyContinue
    
    if ($existingAssignment) {
        Write-Host "  ✓ Reader role already assigned" -ForegroundColor Green
        continue
    }
    
    # Create new assignment
    try {
        $roleAssignment = New-AzRoleAssignment `
            -ObjectId $objectId `
            -RoleDefinitionName "Reader" ` # Assign reader role - change if required
            -Scope "/subscriptions/$($sub.Id)" `
            -ErrorAction Stop
            
        Write-Host "  ✓ Successfully assigned Reader role (Assignment: $($roleAssignment.RoleAssignmentId))" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Failed: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Script Complete ===" -ForegroundColor Green
