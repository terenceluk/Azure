<#

Example Usage: 

.\Add-AppGatewayWafExclusions.ps1 `
-ResourceGroupName "rg-us-eus-app-dev" `
-PolicyName "waf-us-eus-app-dev" `
-RuleId "942100" `
-MatchVariable "RequestArgNames" `
-Selector "test" `
-Operator "Equals" `
-RuleSetVersion 3.2 `
-SkipLegacyWarning `
-SkipConfirmation

#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$PolicyName,
    
    [Parameter(Mandatory=$true)]
    [string]$RuleId,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet(
        # Headers
        "RequestHeaderKeys",      # Header names (CRS 3.2+ / DRS)
        "RequestHeaderNames",     # Header values (legacy - use for older rule sets)
        "RequestHeaderValues",    # Header values (modern - RECOMMENDED)
        
        # Cookies
        "RequestCookieKeys",      # Cookie names (CRS 3.2+ / DRS)
        "RequestCookieNames",     # Cookie values (legacy - use for older rule sets)
        "RequestCookieValues",    # Cookie values (modern - RECOMMENDED)
        
        # Query String / POST Args
        "RequestArgKeys",         # Arg names (CRS 3.2+ / DRS)
        "RequestArgNames",        # Arg values (legacy - use for older rule sets)
        "RequestArgValues",       # Arg values (modern - RECOMMENDED)
        
        # Request Body (special case)
        "RequestBodyPostArgNames" # POST form field names (all versions)
    )]
    [string]$MatchVariable,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Equals", "Contains", "StartsWith", "EndsWith", "EqualsAny")]
    [string]$Operator,
    
    [Parameter(Mandatory=$true)]
    [string]$Selector,
    
    [Parameter(Mandatory=$false)]
    [string]$CSVPath = ".\RuleIDs-Feb-18-2026.csv",
    
    [Parameter(Mandatory=$false)]
    [string]$RuleSetVersion = "2.2",  # Default to latest DRS
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipLegacyWarning,  # Skip legacy match variable warnings
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation,   # Skip "Proceed with creating this exclusion?" prompt
    
    [switch]$WhatIf
)

# Function to lookup rule information from CSV
function Get-RuleInfoFromCSV {
    param(
        [string]$ruleId,
        [string]$csvPath,
        [string]$ruleSetVersion
    )
    
    # Check if CSV file exists
    if (-not (Test-Path $csvPath)) {
        Write-Error "CSV file not found at: $csvPath"
        Write-Host "Please ensure the CSV file exists in the current directory." -ForegroundColor Yellow
        Write-Host "Default filename: waf_rules_complete.csv" -ForegroundColor Gray
        exit 1
    }
    
    # Import CSV and look for matching rule
    Write-Host "  Loading CSV file..." -ForegroundColor Gray
    $rules = Import-Csv $csvPath
    
    # First try to find exact match with specified version
    $matchingRules = $rules | Where-Object { 
        $_.RuleId -eq $ruleId -and $_.RuleSetVersion -eq $ruleSetVersion
    }
    
    if ($matchingRules.Count -eq 0) {
        # Try without version filter
        $matchingRules = $rules | Where-Object { $_.RuleId -eq $ruleId }
        
        if ($matchingRules.Count -eq 0) {
            Write-Error "Rule ID $ruleId not found in CSV file."
            Write-Host "`nAvailable Rule IDs in CSV (first 20):" -ForegroundColor Yellow
            $rules | Select-Object -Unique RuleId | Sort-Object RuleId | Select-Object -First 20 | Format-Table -AutoSize
            Write-Host "... and more. Please check the CSV for the complete list." -ForegroundColor Gray
            exit 1
        } else {
            Write-Host "`n⚠️  Found Rule ID $ruleId but with different RuleSetVersion. Available versions:" -ForegroundColor Yellow
            $matchingRules | Select-Object RuleSetVersion, RuleGroup, RuleSetType | Sort-Object RuleSetVersion | Format-Table -AutoSize
            
            # Ask user which version to use
            $selectedVersion = Read-Host "`nEnter the RuleSetVersion to use"
            $matchingRules = $rules | Where-Object { 
                $_.RuleId -eq $ruleId -and $_.RuleSetVersion -eq $selectedVersion
            }
            
            if ($matchingRules.Count -eq 0) {
                Write-Error "Invalid version selected."
                exit 1
            }
        }
    }
    
    # Return the first matching rule
    return $matchingRules[0]
}

# Function to validate match variable
function Test-MatchVariable {
    param([string]$variable)
    
    $validVariables = @(
        # Headers
        "RequestHeaderKeys",
        "RequestHeaderNames",
        "RequestHeaderValues",
        
        # Cookies
        "RequestCookieKeys",
        "RequestCookieNames",
        "RequestCookieValues",
        
        # Query String / POST Args
        "RequestArgKeys",
        "RequestArgNames",
        "RequestArgValues",
        
        # Request Body
        "RequestBodyPostArgNames"
    )
    
    return $variable -in $validVariables
}

# Function to get match variable description
function Get-MatchVariableDescription {
    param([string]$variable)
    
    switch -Wildcard ($variable) {
        "RequestHeaderKeys" { return "You are excluding the **NAME** of the Header" }
        "RequestHeaderNames" { return "You are excluding the **VALUE** of the Header (legacy mode)" }
        "RequestHeaderValues" { return "You are excluding the **VALUE** of the Header" }
        
        "RequestCookieKeys" { return "You are excluding the **NAME** of the Cookie" }
        "RequestCookieNames" { return "You are excluding the **VALUE** of the Cookie (legacy mode)" }
        "RequestCookieValues" { return "You are excluding the **VALUE** of the Cookie" }
        
        "RequestArgKeys" { return "You are excluding the **NAME** of the Query/Post Argument" }
        "RequestArgNames" { return "You are excluding the **VALUE** of the Query/Post Argument (legacy mode)" }
        "RequestArgValues" { return "You are excluding the **VALUE** of the Query/Post Argument" }
        
        "RequestBodyPostArgNames" { return "You are excluding POST form field NAMES" }
        default { return "Match variable: $variable" }
    }
}

# Function to show legacy warning (only if not skipped)
function Show-LegacyWarning {
    param(
        [string]$variable,
        [bool]$skipWarning
    )
    
    $legacyVars = @{
        "RequestHeaderNames" = "RequestHeaderValues"
        "RequestCookieNames" = "RequestCookieValues"  
        "RequestArgNames" = "RequestArgValues"
    }
    
    if ($skipWarning) {
        return $true  # Skip warning, continue automatically
    }
    
    if ($legacyVars.ContainsKey($variable)) {
        Write-Host "`n⚠️  WARNING: '$variable' is a LEGACY match variable." -ForegroundColor Yellow
        Write-Host "   For modern rule sets (DRS/CRS 3.2+), Microsoft recommends using '$($legacyVars[$variable])'" -ForegroundColor Yellow
        Write-Host "   The legacy version will still work, but consider updating for future compatibility.`n" -ForegroundColor Yellow
        
        $continue = Read-Host "Continue with legacy variable? (y/N)"
        return ($continue -eq 'y' -or $continue -eq 'Y')
    }
    
    return $true
}

try {
    # Display banner
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   WAF Exclusion Creator from CSV" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Look up rule information from CSV
    Write-Host "📖 Looking up Rule ID $RuleId in CSV..." -ForegroundColor Yellow
    $ruleInfo = Get-RuleInfoFromCSV -ruleId $RuleId -csvPath $CSVPath -ruleSetVersion $RuleSetVersion
    
    # Validate match variable
    if (-not (Test-MatchVariable -variable $MatchVariable)) {
        Write-Error "Invalid MatchVariable. Must be one of:" -ForegroundColor Red
        Write-Host "  Headers: RequestHeaderKeys, RequestHeaderNames, RequestHeaderValues" -ForegroundColor Gray
        Write-Host "  Cookies: RequestCookieKeys, RequestCookieNames, RequestCookieValues" -ForegroundColor Gray
        Write-Host "  Args: RequestArgKeys, RequestArgNames, RequestArgValues" -ForegroundColor Gray
        Write-Host "  Body: RequestBodyPostArgNames" -ForegroundColor Gray
        exit 1
    }
    
    # Show legacy warning if needed (and not skipped)
    $continueExecution = Show-LegacyWarning -variable $MatchVariable -skipWarning $SkipLegacyWarning
    if (-not $continueExecution) {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
    
    # Display found rule information
    Write-Host "`n✅ Found rule information:" -ForegroundColor Green
    Write-Host "  📌 Rule ID: $($ruleInfo.RuleId)" -ForegroundColor White
    Write-Host "  📁 Rule Group: $($ruleInfo.RuleGroup)" -ForegroundColor Cyan
    Write-Host "  🔧 Rule Set Type: $($ruleInfo.RuleSetType)" -ForegroundColor Cyan
    Write-Host "  📊 Rule Set Version: $($ruleInfo.RuleSetVersion)" -ForegroundColor Cyan
    Write-Host "  📝 Description: $($ruleInfo.Description)" -ForegroundColor Gray
    if ($ruleInfo.Severity) {
        Write-Host "  ⚠️  Severity: $($ruleInfo.Severity)" -ForegroundColor $(if ($ruleInfo.Severity -eq "Critical") { "Red" } else { "Yellow" })
    }
    if ($ruleInfo.ParanoiaLevel) {
        Write-Host "  🎚️  Paranoia Level: $($ruleInfo.ParanoiaLevel)" -ForegroundColor Magenta
    }
    if ($ruleInfo.Notes) {
        Write-Host "  💡 Notes: $($ruleInfo.Notes)" -ForegroundColor Yellow
    }
    
    # Show match variable interpretation
    Write-Host "`n📋 Match Variable Details:" -ForegroundColor Cyan
    Write-Host "  $(Get-MatchVariableDescription -variable $MatchVariable)" -ForegroundColor White
    Write-Host "  Selector: '$Selector' with operator '$Operator'" -ForegroundColor White
    
    # Confirm with user (skip if SkipConfirmation is set)
    if (-not $SkipConfirmation) {
        Write-Host "`n" -ForegroundColor Gray
        $confirm = Read-Host "Proceed with creating this exclusion? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Host "`n⏩ Skipping confirmation (automatically proceeding)..." -ForegroundColor Yellow
    }
    
    if ($WhatIf) {
        Write-Host "`n[WHAT-IF] Would create the following exclusion:" -ForegroundColor Yellow
        Write-Host "  📍 Resource Group: $ResourceGroupName" -ForegroundColor Gray
        Write-Host "  🎯 Policy Name: $PolicyName" -ForegroundColor Gray
        Write-Host "  🔢 Rule ID: $RuleId" -ForegroundColor Gray
        Write-Host "  📁 Rule Group: $($ruleInfo.RuleGroup)" -ForegroundColor Gray
        Write-Host "  🔧 Rule Set Type: $($ruleInfo.RuleSetType)" -ForegroundColor Gray
        Write-Host "  📊 Rule Set Version: $($ruleInfo.RuleSetVersion)" -ForegroundColor Gray
        Write-Host "  🔍 Match Variable: $MatchVariable" -ForegroundColor Gray
        Write-Host "  ⚙️ Operator: $Operator" -ForegroundColor Gray
        Write-Host "  🎯 Selector: $Selector" -ForegroundColor Gray
        exit 0
    }
    
    # Create the exclusion objects
    Write-Host "`n🔧 Creating rule-level exclusion..." -ForegroundColor Yellow
    
    # Create rule entry
    Write-Host "  - Creating managed rule..." -ForegroundColor Gray
    $ruleEntry = New-AzApplicationGatewayFirewallPolicyExclusionManagedRule -Rule $RuleId
    
    # Create rule group entry
    Write-Host "  - Creating rule group..." -ForegroundColor Gray
    $ruleGroupEntry = New-AzApplicationGatewayFirewallPolicyExclusionManagedRuleGroup `
        -RuleGroupName $ruleInfo.RuleGroup `
        -Rule $ruleEntry
    
    # Create managed rule set
    Write-Host "  - Creating managed rule set..." -ForegroundColor Gray
    $exclusionManagedRuleSet = New-AzApplicationGatewayFirewallPolicyExclusionManagedRuleSet `
        -RuleSetType $ruleInfo.RuleSetType `
        -RuleSetVersion $ruleInfo.RuleSetVersion `
        -RuleGroup $ruleGroupEntry
    
    # Create exclusion entry
    Write-Host "  - Creating exclusion entry..." -ForegroundColor Gray
    $exclusionEntry = New-AzApplicationGatewayFirewallPolicyExclusion `
        -MatchVariable $MatchVariable `
        -SelectorMatchOperator $Operator `
        -Selector $Selector `
        -ExclusionManagedRuleSet $exclusionManagedRuleSet
    
    # Get the existing WAF policy
    Write-Host "`n🔍 Retrieving WAF policy: $PolicyName..." -ForegroundColor Yellow
    $wafPolicy = Get-AzApplicationGatewayFirewallPolicy `
        -Name $PolicyName `
        -ResourceGroupName $ResourceGroupName
    
    if ($wafPolicy -eq $null) {
        Write-Error "WAF policy not found. Please check the resource group and policy name."
        exit 1
    }
    
    Write-Host "✅ Policy retrieved successfully" -ForegroundColor Green
    Write-Host "  Policy Location: $($wafPolicy.Location)" -ForegroundColor Gray
    Write-Host "  Policy Mode: $($wafPolicy.PolicySettings.Mode)" -ForegroundColor Gray
    Write-Host "  Current ETag: $($wafPolicy.Etag)" -ForegroundColor Gray
    
    # Check if exclusion already exists
    Write-Host "`n🔎 Checking for existing exclusions..." -ForegroundColor Yellow
    $existingExclusion = $wafPolicy.ManagedRules[0].Exclusions | Where-Object {
        $_.MatchVariable -eq $MatchVariable -and
        $_.SelectorMatchOperator -eq $Operator -and
        $_.Selector -eq $Selector -and
        $_.ExclusionManagedRuleSets.RuleSetType -eq $ruleInfo.RuleSetType -and
        $_.ExclusionManagedRuleSets.RuleGroups.RuleGroupName -eq $ruleInfo.RuleGroup -and
        ($_.ExclusionManagedRuleSets.RuleGroups.Rules.RuleId -contains $RuleId)
    }
    
    if ($existingExclusion) {
        Write-Host "⚠️ An identical exclusion already exists in the policy." -ForegroundColor Yellow
        $response = Read-Host "Do you want to add it anyway? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Host "✅ No duplicate exclusion found" -ForegroundColor Green
    }
    
    # Add exclusion to policy
    Write-Host "`n📝 Adding exclusion to policy..." -ForegroundColor Yellow
    $wafPolicy.ManagedRules[0].Exclusions.Add($exclusionEntry)
    Write-Host "  Current exclusion count: $($wafPolicy.ManagedRules[0].Exclusions.Count)" -ForegroundColor Gray
    
    # Update the policy
    Write-Host "🔄 Updating WAF policy in Azure..." -ForegroundColor Yellow
    $updatedPolicy = $wafPolicy | Set-AzApplicationGatewayFirewallPolicy
    
    # Success message
    Write-Host "`n✅ SUCCESS! Exclusion added to policy!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Policy ETag: $($updatedPolicy.Etag)" -ForegroundColor Cyan
    Write-Host "Policy Provisioning State: $($updatedPolicy.ProvisioningState)" -ForegroundColor Cyan
    Write-Host "New exclusion count: $($updatedPolicy.ManagedRules[0].Exclusions.Count)" -ForegroundColor Cyan
    
    # Display summary
    Write-Host "`n📋 Exclusion Summary:" -ForegroundColor Cyan
    Write-Host "  ┌─────────────────────────────────────" -ForegroundColor Gray
    Write-Host "  │ Rule: $RuleId" -ForegroundColor White
    Write-Host "  │ Group: $($ruleInfo.RuleGroup)" -ForegroundColor White
    Write-Host "  │ Type: $($ruleInfo.RuleSetType) v$($ruleInfo.RuleSetVersion)" -ForegroundColor White
    Write-Host "  │ Description: $($ruleInfo.Description)" -ForegroundColor White
    Write-Host "  │ Excluding: $MatchVariable where $Operator '$Selector'" -ForegroundColor White
    if ($ruleInfo.Notes) {
        Write-Host "  │" -ForegroundColor Gray
        Write-Host "  │ 💡 Note: $($ruleInfo.Notes)" -ForegroundColor Yellow
    }
    Write-Host "  └─────────────────────────────────────" -ForegroundColor Gray
    
} catch {
    Write-Error "❌ An error occurred: $_"
    Write-Host "Error details: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    # Provide helpful error message based on common issues
    if ($_.Exception.Message -like "*No registered resource provider*") {
        Write-Host "`n💡 Tip: Make sure the Az.Network module is installed:" -ForegroundColor Yellow
        Write-Host "  Install-Module -Name Az.Network -Force" -ForegroundColor Gray
    } elseif ($_.Exception.Message -like "*Authorization failed*") {
        Write-Host "`n💡 Tip: Make sure you're logged in with Connect-AzAccount and have the right permissions." -ForegroundColor Yellow
    } elseif ($_.Exception.Message -like "*not found*") {
        Write-Host "`n💡 Tip: Check that the resource group and policy name are correct." -ForegroundColor Yellow
    } elseif ($_.Exception.Message -like "*Invalid match variable*") {
        Write-Host "`n💡 Tip: The match variable '$MatchVariable' may not be supported with your rule set version." -ForegroundColor Yellow
        Write-Host "   Try using a legacy variant (e.g., RequestHeaderNames instead of RequestHeaderValues)" -ForegroundColor Gray
    }
    
    exit 1
}
