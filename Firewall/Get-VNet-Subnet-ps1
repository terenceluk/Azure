<#
.SYNOPSIS
    Exports all Azure Virtual Networks and Subnets to CSV
.DESCRIPTION
    This script retrieves all VNets from specified subscriptions and exports them with subnet details to a CSV file.
.NOTES
    Version: 1.2
    Author: Terence Luk
    Requires: Az PowerShell module
#>

# Configuration - UPDATE THESE VALUES
$targetSubscriptionIds = @(
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"#,
    #"subscription-id-2",
    #"subscription-id-3"
)

# Leave empty to process all accessible subscriptions
# $targetSubscriptionIds = @()

# Color scheme for console output
$colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Verbose = "Gray"
    Section = "Magenta"
    Progress = "Blue"
}

function Write-Section {
    param([string]$Message)
    Write-Host "`n" + ("=" * 80) -ForegroundColor $colors.Section
    Write-Host $Message -ForegroundColor $colors.Section
    Write-Host ("=" * 80) -ForegroundColor $colors.Section
}

function Write-SubSection {
    param([string]$Message)
    Write-Host "`n" + ("-" * 60) -ForegroundColor $colors.Info
    Write-Host $Message -ForegroundColor $colors.Info
    Write-Host ("-" * 60) -ForegroundColor $colors.Info
}

# Main script execution starts here
Write-Section "Starting Azure VNet and Subnet Export"

try {
    # Verify we're authenticated
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "❌ Not authenticated to Azure. Please run Connect-AzAccount first." -ForegroundColor $colors.Error
        exit 1
    }
    
    Write-Host "✓ Authenticated as: $($context.Account.Id)" -ForegroundColor $colors.Success

    # Get subscriptions based on configuration
    Write-SubSection "Retrieving Subscriptions"
    
    if ($targetSubscriptionIds.Count -gt 0) {
        Write-Host "Target subscriptions specified: $($targetSubscriptionIds.Count)" -ForegroundColor $colors.Info
        $subscriptions = Get-AzSubscription -ErrorAction Stop | Where-Object { $_.Id -in $targetSubscriptionIds }
        
        if ($subscriptions.Count -eq 0) {
            Write-Host "❌ No matching subscriptions found. Check your subscription IDs." -ForegroundColor $colors.Error
            exit 1
        }
        
        # Check if we found all specified subscriptions
        $foundIds = $subscriptions.Id
        $missingIds = $targetSubscriptionIds | Where-Object { $_ -notin $foundIds }
        
        if ($missingIds.Count -gt 0) {
            Write-Host "⚠ Warning: Could not find these subscriptions: $($missingIds -join ', ')" -ForegroundColor $colors.Warning
        }
    } else {
        Write-Host "No target subscriptions specified - processing all accessible subscriptions" -ForegroundColor $colors.Info
        $subscriptions = Get-AzSubscription -ErrorAction Stop
    }
    
    Write-Host "Found $($subscriptions.Count) subscription(s) to process" -ForegroundColor $colors.Success

    # Initialize collection for all VNets
    $allVnets = [System.Collections.Generic.List[object]]::new()
    $totalVnets = 0
    $totalSubnets = 0

    # Process each subscription
    $currentSub = 0
    foreach ($subscription in $subscriptions) {
        $currentSub++
        Write-Host "`n[$currentSub/$($subscriptions.Count)] Processing subscription: $($subscription.Name)" -ForegroundColor $colors.Warning
        
        try {
            # Set subscription context
            Set-AzContext -Subscription $subscription.Id -ErrorAction Stop | Out-Null
            
            # Get all VNets in this subscription
            $vnets = Get-AzVirtualNetwork -ErrorAction Stop
            
            Write-Host "  Found $($vnets.Count) VNet(s) in this subscription" -ForegroundColor $colors.Info
            
            # Process each VNet
            foreach ($vnet in $vnets) {
                $totalVnets++
                $subnetCount = $vnet.Subnets.Count
                $totalSubnets += $subnetCount
                
                Write-Host "  Processing VNet: $($vnet.Name)" -ForegroundColor $colors.Progress
                Write-Host "    Resource Group: $($vnet.ResourceGroupName)" -ForegroundColor $colors.Verbose
                Write-Host "    Location: $($vnet.Location)" -ForegroundColor $colors.Verbose
                Write-Host "    Subnets: $subnetCount" -ForegroundColor $colors.Verbose
                
                # If VNet has subnets, process them
                if ($vnet.Subnets.Count -gt 0) {
                    foreach ($subnet in $vnet.Subnets) {
                        # Handle subnet address prefixes (can be single string or array)
                        $subnetAddressPrefix = if ($subnet.AddressPrefix) {
                            $subnet.AddressPrefix
                        } elseif ($subnet.AddressPrefixes -and $subnet.AddressPrefixes.Count -gt 0) {
                            $subnet.AddressPrefixes -join ';'
                        } else {
                            ""
                        }
                        
                        # Create VNet-Subnet object
                        $vnetObject = [PSCustomObject]@{
                            SubscriptionName = $subscription.Name
                            SubscriptionId = $subscription.Id
                            ResourceGroupName = $vnet.ResourceGroupName
                            VNetName = $vnet.Name
                            VNetLocation = $vnet.Location
                            VNetAddressSpace = ($vnet.AddressSpace.AddressPrefixes -join ';')
                            SubnetName = $subnet.Name
                            SubnetAddressPrefix = $subnetAddressPrefix
                            SubnetAddressPrefixes = ($subnet.AddressPrefixes -join ';')  # Additional column for multiple prefixes
                            SubnetDelegations = ($subnet.Delegations | ForEach-Object { $_.ServiceName }) -join ';'
                            NetworkSecurityGroup = if ($subnet.NetworkSecurityGroup) { $subnet.NetworkSecurityGroup.Id.Split('/')[-1] } else { "" }
                            RouteTable = if ($subnet.RouteTable) { $subnet.RouteTable.Id.Split('/')[-1] } else { "" }
                            NatGateway = if ($subnet.NatGateway) { $subnet.NatGateway.Id.Split('/')[-1] } else { "" }
                            PrivateEndpointNetworkPolicies = $subnet.PrivateEndpointNetworkPolicies
                            PrivateLinkServiceNetworkPolicies = $subnet.PrivateLinkServiceNetworkPolicies
                            ProvisioningState = $subnet.ProvisioningState
                        }
                        
                        $allVnets.Add($vnetObject)
                    }
                } else {
                    # VNet with no subnets - create entry with empty subnet info
                    $vnetObject = [PSCustomObject]@{
                        SubscriptionName = $subscription.Name
                        SubscriptionId = $subscription.Id
                        ResourceGroupName = $vnet.ResourceGroupName
                        VNetName = $vnet.Name
                        VNetLocation = $vnet.Location
                        VNetAddressSpace = ($vnet.AddressSpace.AddressPrefixes -join ';')
                        SubnetName = ""
                        SubnetAddressPrefix = ""
                        SubnetAddressPrefixes = ""
                        SubnetDelegations = ""
                        NetworkSecurityGroup = ""
                        RouteTable = ""
                        NatGateway = ""
                        PrivateEndpointNetworkPolicies = ""
                        PrivateLinkServiceNetworkPolicies = ""
                        ProvisioningState = ""
                    }
                    
                    $allVnets.Add($vnetObject)
                }
                
                Write-Host "    ✓ VNet processed" -ForegroundColor $colors.Success
            }
        }
        catch {
            Write-Host "  ❌ Error processing subscription $($subscription.Name): $($_.Exception.Message)" -ForegroundColor $colors.Error
            continue
        }
    }

    # Export to CSV
    Write-SubSection "Exporting Results"
    
    if ($allVnets.Count -gt 0) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outputFile = "AzureVNets-Subnets-$timestamp.csv"
        
        Write-Host "Exporting $($allVnets.Count) VNet-subnet entries to CSV..." -ForegroundColor $colors.Progress
        $allVnets | Export-Csv -Path $outputFile -NoTypeInformation -Force
        Write-Host "✓ VNets and subnets exported to: $outputFile" -ForegroundColor $colors.Success
        
        # Display summary
        Write-SubSection "Export Summary"
        Write-Host "✓ Subscriptions processed: $($subscriptions.Count)" -ForegroundColor $colors.Success
        Write-Host "✓ Total VNets found: $totalVnets" -ForegroundColor $colors.Success
        Write-Host "✓ Total subnets found: $totalSubnets" -ForegroundColor $colors.Success
        Write-Host "✓ Total entries in CSV: $($allVnets.Count)" -ForegroundColor $colors.Success
        
        # Show sample of data
        Write-Host "`nSample of exported data:" -ForegroundColor $colors.Info
        $allVnets | Select-Object -First 3 | Format-Table -Property SubscriptionName, VNetName, SubnetName, SubnetAddressPrefix -AutoSize
    } else {
        Write-Host "❌ No VNets found to export." -ForegroundColor $colors.Error
    }
}
catch {
    Write-Host "`n❌ Script execution failed: $($_.Exception.Message)" -ForegroundColor $colors.Error
    exit 1
}

Write-Section "Export Complete"
