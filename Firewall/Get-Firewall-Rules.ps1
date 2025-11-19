<#
.SYNOPSIS
    Exports Azure Firewall Policy rules with detailed IP group information
.DESCRIPTION
    This script extracts all firewall rules from an Azure Firewall Policy, including
    IP group names and their associated IP addresses, and exports them to CSV and JSON files.
.NOTES
    Version: 2.0
    Author: Terence Luk
    Requires: Az PowerShell module
#>

# Azure Resource Configuration
$subscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
$resourceGroup = "rg-us-eus-hub"
$azfwPolicyName = "afwp-us-eus-prod"

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

# Cache for IP groups to avoid redundant API calls
$ipGroupCache = @{}

<#
.SYNOPSIS
    Writes a section header to the console
#>
function Write-Section {
    param([string]$Message)
    Write-Host "`n" + ("=" * 80) -ForegroundColor $colors.Section
    Write-Host $Message -ForegroundColor $colors.Section
    Write-Host ("=" * 80) -ForegroundColor $colors.Section
}

<#
.SYNOPSIS
    Writes a subsection header to the console
#>
function Write-SubSection {
    param([string]$Message)
    Write-Host "`n" + ("-" * 60) -ForegroundColor $colors.Info
    Write-Host $Message -ForegroundColor $colors.Info
    Write-Host ("-" * 60) -ForegroundColor $colors.Info
}

<#
.SYNOPSIS
    Retrieves IP group information (name and addresses) with caching and subscription context handling
.PARAMETER resourceId
    The resource ID of the IP group
#>
function Get-IpGroupInfo {
    param ([string]$resourceId)
    
    # Return cached result if available
    if ($ipGroupCache.ContainsKey($resourceId)) {
        return $ipGroupCache[$resourceId]
    }
    
    # Extract subscription ID from resource ID
    $resourceSubscriptionId = ($resourceId -split '/')[2]
    $context = Get-AzContext
    $contextChanged = $false

    try {
        # Switch context if needed (IP group in different subscription)
        if ($context.Subscription.Id -ne $resourceSubscriptionId) {
            Write-Host "      Switching context to subscription: $resourceSubscriptionId" -ForegroundColor $colors.Warning
            $context = Set-AzContext -Subscription $resourceSubscriptionId -ErrorAction Stop
            $contextChanged = $true
        }
        
        # Retrieve IP group details
        $ipGroup = Get-AzIpGroup -ResourceId $resourceId -ErrorAction Stop
        
        # Create result object
        $result = [PSCustomObject]@{
            Name = $ipGroup.Name
            Addresses = ($ipGroup.IpAddresses -join ',')
            AddressCount = $ipGroup.IpAddresses.Count
        }
        
        # Cache the result for future use
        $ipGroupCache[$resourceId] = $result
        
        return $result
    }
    catch {
        Write-Host "      ERROR: Failed to retrieve IP group: $($_.Exception.Message)" -ForegroundColor $colors.Error
        # Return empty object on error
        return [PSCustomObject]@{
            Name = "Error: $($resourceId.Split('/')[-1])"
            Addresses = ""
            AddressCount = 0
        }
    }
    finally {
        # Restore original context if changed
        if ($contextChanged) {
            Set-AzContext -Context $context | Out-Null
        }
    }
}

<#
.SYNOPSIS
    Processes IP group arrays and returns formatted names and addresses
.PARAMETER ipGroupArray
    Array of IP group resource IDs
#>
function Process-IpGroups {
    param([array]$ipGroupArray)
    
    if (-not $ipGroupArray -or $ipGroupArray.Count -eq 0) {
        return @{ Names = ""; Addresses = "" }
    }
    
    $ipGroupInfo = $ipGroupArray | ForEach-Object { Get-IpGroupInfo $_ }
    
    return @{
        Names = ($ipGroupInfo.Name -join ',')
        Addresses = ($ipGroupInfo.Addresses -join ';')
    }
}

<#
.SYNOPSIS
    Creates a standardized rule object with common properties
.PARAMETER rule
    The firewall rule object
.PARAMETER ruleCollectionGroupName
    Name of the rule collection group
#>
function New-RuleObject {
    param($rule, $ruleCollectionGroupName)
    
    # Create base rule object with common properties
    $ruleObject = [PSCustomObject]@{
        RuleCollectionGroup = $ruleCollectionGroupName
        Name = $rule.Name
        RuleType = $rule.RuleType
        Description = $rule.Description
        Protocols = Format-Protocols $rule.protocols
        SourceAddresses = ($rule.SourceAddresses -join ',')
    }
    
    return $ruleObject
}

<#
.SYNOPSIS
    Formats protocol information for display
.PARAMETER protocols
    Protocols array from firewall rule
#>
function Format-Protocols {
    param($protocols)
    
    if (-not $protocols -or $protocols.Count -eq 0) {
        return ""
    }
    
    # Check if protocols are complex objects or simple strings
    if ($protocols[0].GetType().Name -ne "String") {
        return ($protocols | ForEach-Object { "{0}|{1}" -f $_.ProtocolType, $_.Port }) -join ','
    } else {
        return ($protocols -join ',')
    }
}

# Main script execution starts here
Write-Section "Starting Azure Firewall Policy Export"

try {
    # Set Azure context
    Write-Host "Setting Azure context..." -ForegroundColor $colors.Info
    $context = Set-AzContext -Subscription $subscriptionId -ErrorAction Stop
    if ($context) { 
        Write-Host "✓ Azure subscription context set to: $($context.Name)" -ForegroundColor $colors.Success 
    }

    # Initialize rule collections
    $networkRules = [System.Collections.Generic.List[object]]::new()
    $applicationRules = [System.Collections.Generic.List[object]]::new()
    $dnatRules = [System.Collections.Generic.List[object]]::new()

    # Retrieve Firewall Policy
    Write-SubSection "Retrieving Firewall Policy"
    Write-Host "Getting firewall policy: $azfwPolicyName" -ForegroundColor $colors.Info
    $policy = Get-AzFirewallPolicy -Name $azfwPolicyName -ResourceGroupName $resourceGroup -ErrorAction Stop
    Write-Host "✓ Firewall policy retrieved successfully" -ForegroundColor $colors.Success

    # Export policy to files
    Write-SubSection "Exporting Policy Files"
    
    # Export policy summary to CSV
    Write-Host "Exporting policy to CSV..." -ForegroundColor $colors.Progress
    $policyObject = [PSCustomObject]@{
        BasePolicyId = $policy.BasePolicy.Id
        DnsSettingsServers = $policy.DnsSettings.Servers
        DnsSettingsEnableProxy = $policy.DnsSettings.EnableProxy
        Etag = $policy.Etag
        IntrusionDetectionMode = $policy.IntrusionDetection.Mode
        IntrusionDetectionConfigurationPrivateRanges = $policy.IntrusionDetection.Configuration.PrivateRanges -join ','
        IntrusionDetectionConfigurationSignatureOverrides = ($policy.IntrusionDetection.Configuration.SignatureOverrides | 
            ForEach-Object { "{0}|{1}" -f $_.Id, $_.Mode }) -join ','
        Location = $policy.Location
        Name = $policy.Name
        PrivateRange = $policy.PrivateRange -join ','
        ProvisioningState = $policy.ProvisioningState
        ResourceGroupName = $policy.ResourceGroupName
        Size = $policy.Size
        Sku = $policy.Sku
        SnatPrivateRanges = $policy.Snat.PrivateRanges -join ','
        SnatAutoLearnPrivateRanges = $policy.Snat.AutoLearnPrivateRanges
        SqlSettingAllowSqlRedirect = $policy.SqlSetting.AllowSqlRedirect
        Tag = ($policy.Tag | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';'
        ThreatIntelMode = $policy.ThreatIntelMode
        ThreatIntelWhitelistFqdns = $policy.ThreatIntelWhitelist.FQDNs -join ','
        ThreatIntelWhitelistIpAddresses = $policy.ThreatIntelWhitelist.IpAddresses -join ','
        TlsInspection = ($null -ne $policy.TransportSecurity)
        TlsTransportSecurityCertificateAuthorityKeyVaultSecretId = $policy.TransportSecurity.CertificateAuthority.KeyVaultSecretId
        TlsTransportSecurityCertificateAuthorityKeyVaultName = $policy.TransportSecurity.CertificateAuthority.Name
        Type = $policy.Type
    }
    
    $policyObject | Export-Csv -Path "azfwpolicy-$($azfwPolicyName).csv" -NoTypeInformation
    Write-Host "✓ Policy CSV exported: azfwpolicy-$($azfwPolicyName).csv" -ForegroundColor $colors.Success

    # Export full policy to JSON
    Write-Host "Exporting policy to JSON..." -ForegroundColor $colors.Progress
    $policy | ConvertTo-Json -Depth 10 | Out-File -FilePath "azfwpolicy-$($azfwPolicyName).json"
    Write-Host "✓ Policy JSON exported: azfwpolicy-$($azfwPolicyName).json" -ForegroundColor $colors.Success

    # Process Rule Collection Groups
    Write-SubSection "Processing Rule Collection Groups"
    $ruleCollectionGroupCount = $policy.RuleCollectionGroups.Count
    Write-Host "Found $ruleCollectionGroupCount rule collection group(s) to process" -ForegroundColor $colors.Info

    $currentRcg = 0
    $totalRulesProcessed = 0

    foreach ($rcg in $policy.RuleCollectionGroups) {
        $currentRcg++
        
        # Get rule collection group details
        $resource = Get-AzResource -ResourceId $rcg.Id -ErrorAction Stop
        $azfwrulecollectiongroups = Get-AzFirewallPolicyRuleCollectionGroup -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -AzureFirewallPolicyName $azfwPolicyName -ErrorAction Stop
        
        $ruleCount = $azfwrulecollectiongroups.Properties.RuleCollection.Rules.Count
        Write-Host "`n[$currentRcg/$ruleCollectionGroupCount] Processing rule collection group: $($azfwrulecollectiongroups.Name)" -ForegroundColor $colors.Warning
        Write-Host "  Rules in collection: $ruleCount" -ForegroundColor $colors.Info

        # Export individual rule collection group to JSON
        $azfwrulecollectiongroups | ConvertTo-Json -Depth 10 | Out-File -FilePath "azfwpolicy-$($azfwPolicyName)-rcg-$($azfwrulecollectiongroups.Name).json"

        $currentRule = 0
        # Process each rule in the collection
        foreach ($rule in $azfwrulecollectiongroups.properties.RuleCollection.rules) {
            $currentRule++
            $totalRulesProcessed++
            
            Write-Host "  [$currentRule/$ruleCount] Processing rule: $($rule.Name) ($($rule.RuleType))" -ForegroundColor $colors.Progress
            
            # Create base rule object
            $ruleObject = New-RuleObject -rule $rule -ruleCollectionGroupName $azfwrulecollectiongroups.Name

            # Process IP groups for source (common to all rule types)
            $sourceIpGroups = Process-IpGroups $rule.SourceIpGroups
            $ruleObject | Add-Member -MemberType NoteProperty -Name SourceIpGroups -Value $sourceIpGroups.Names
            $ruleObject | Add-Member -MemberType NoteProperty -Name SourceIpGroupsAddresses -Value $sourceIpGroups.Addresses

            # Process rule based on type
            switch ($rule.RuleType) {
                "NetworkRule" {
                    $ruleObject | Add-Member -MemberType NoteProperty -Name DestinationAddresses -Value ($rule.DestinationAddresses -join ',')
                    
                    $destIpGroups = Process-IpGroups $rule.DestinationIpGroups
                    $ruleObject | Add-Member -MemberType NoteProperty -Name DestinationIpGroups -Value $destIpGroups.Names
                    
                    $ruleObject | Add-Member -MemberType NoteProperty -Name DestinationPorts -Value ($rule.DestinationPorts -join ',')
                    $ruleObject | Add-Member -MemberType NoteProperty -Name DestinationFqdns -Value ($rule.DestinationFqdns -join ',')
                    
                    $networkRules.Add($ruleObject)
                    Write-Host "    ✓ Network rule processed" -ForegroundColor $colors.Success
                }
                "ApplicationRule" {
                    $ruleObject | Add-Member -MemberType NoteProperty -Name TargetFqdns -Value ($rule.TargetFqdns -join ',')
                    $ruleObject | Add-Member -MemberType NoteProperty -Name FqdnTags -Value ($rule.FqdnTags -join ',')
                    $ruleObject | Add-Member -MemberType NoteProperty -Name TargetUrls -Value ($rule.TargetUrls -join ',')
                    $ruleObject | Add-Member -MemberType NoteProperty -Name TerminateTLS -Value $rule.TerminateTLS
                    $ruleObject | Add-Member -MemberType NoteProperty -Name HttpHeadersToInsert -Value ($rule.HttpHeadersToInsert -join ',')
                    $ruleObject | Add-Member -MemberType NoteProperty -Name WebCategories -Value ($rule.WebCategories -join ",")
                    
                    $applicationRules.Add($ruleObject)
                    Write-Host "    ✓ Application rule processed" -ForegroundColor $colors.Success
                }
                "NatRule" {
                    $ruleObject | Add-Member -MemberType NoteProperty -Name DestinationAddresses -Value ($rule.DestinationAddresses -join ',')
                    $ruleObject | Add-Member -MemberType NoteProperty -Name DestinationPorts -Value ($rule.DestinationPorts -join ',')
                    $ruleObject | Add-Member -MemberType NoteProperty -Name TranslatedAddress -Value $rule.TranslatedAddress
                    $ruleObject | Add-Member -MemberType NoteProperty -Name TranslatedPort -Value $rule.TranslatedPort
                    $ruleObject | Add-Member -MemberType NoteProperty -Name TranslatedFqdn -Value $rule.TranslatedFqdn
                    
                    $dnatRules.Add($ruleObject)
                    Write-Host "    ✓ NAT rule processed" -ForegroundColor $colors.Success
                }
                default {
                    Write-Host "    ⚠ Unknown rule type: $($rule.RuleType)" -ForegroundColor $colors.Warning
                }
            }
        }
    }

    # Export rules to CSV files
    Write-SubSection "Exporting Results to CSV"
    
    Write-Host "Exporting network rules..." -ForegroundColor $colors.Progress
    $networkRules | Export-Csv -Path "azfwnetworkrules.csv" -NoTypeInformation -Force
    Write-Host "✓ Network rules exported: $($networkRules.Count) rules" -ForegroundColor $colors.Success

    Write-Host "Exporting application rules..." -ForegroundColor $colors.Progress
    $applicationRules | Export-Csv -Path "azfwapplicationrules.csv" -NoTypeInformation -Force
    Write-Host "✓ Application rules exported: $($applicationRules.Count) rules" -ForegroundColor $colors.Success

    Write-Host "Exporting DNAT rules..." -ForegroundColor $colors.Progress
    $dnatRules | Export-Csv -Path "azfwdnatrules.csv" -NoTypeInformation -Force
    Write-Host "✓ DNAT rules exported: $($dnatRules.Count) rules" -ForegroundColor $colors.Success

    # Final summary
    Write-Section "Export Complete"
    Write-Host "✓ Firewall policy export completed successfully!" -ForegroundColor $colors.Success
    Write-Host "✓ Total rules processed: $totalRulesProcessed" -ForegroundColor $colors.Success
    Write-Host "✓ IP groups cached: $($ipGroupCache.Count)" -ForegroundColor $colors.Success
    Write-Host "✓ Files created:" -ForegroundColor $colors.Info
    Write-Host "  - azfwpolicy-$($azfwPolicyName).csv" -ForegroundColor $colors.Info
    Write-Host "  - azfwpolicy-$($azfwPolicyName).json" -ForegroundColor $colors.Info
    Write-Host "  - azfwnetworkrules.csv ($($networkRules.Count) rules)" -ForegroundColor $colors.Info
    Write-Host "  - azfwapplicationrules.csv ($($applicationRules.Count) rules)" -ForegroundColor $colors.Info
    Write-Host "  - azfwdnatrules.csv ($($dnatRules.Count) rules)" -ForegroundColor $colors.Info
}
catch {
    Write-Host "`n❌ Script execution failed: $($_.Exception.Message)" -ForegroundColor $colors.Error
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor $colors.Error
    exit 1
}
