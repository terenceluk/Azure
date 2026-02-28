<#

# Connect to Azure
Connect-AzAccount

# Confirm you are conneceted to the right subscription, with the right account
Get-AzContext

# Select a different subscription if required
Set-AzContext -Subscription "Your-Subscription-Name-or-ID"

Example Usage:

# Single exclusion from CSV lookup:
.\Add-AppGatewayWafExclusions.ps1 `
-ResourceGroupName "rg-us-eus-app-dev" `
-PolicyName "waf-us-eus-app-dev" `
-RuleId "942100" `
-MatchVariable "RequestArgValues" `
-Selector "test" `
-Operator "Equals" `
-RuleSetVersion 3.2 `
-SkipLegacyWarning `
-SkipConfirmation

# Single exclusion from CSV lookup for DRS 2.2:
.\Add-AppGatewayWafExclusions-CSV.ps1 `
-ResourceGroupName "rg-us-eus-app-dev" `
-PolicyName "waf-us-eus-app-dev" `
-RuleId "99031003" `
-MatchVariable "RequestArgValues" `
-Selector "data" `
-Operator "Equals" `
-RuleSetVersion 2.2 `
-RuleInfoCSVPath ".\RuleIDs-Feb-18-2026.csv" `
-SkipLegacyWarning `
-SkipConfirmation `
-WhatIf

# Multiple exclusions from CSV file:
.\Add-AppGatewayWafExclusions.ps1 `
-ResourceGroupName "rg-us-eus-app-dev" `
-PolicyName "waf-us-eus-app-dev" `
-CSVExclusionsPath ".\waf-exclusions.csv" `
-RuleInfoCSVPath ".\RuleIDs-Feb-18-2026.csv" `
-SkipLegacyWarning `
-SkipConfirmation

# CSV exclusions format example (waf-exclusions.csv):
# RuleId,MatchVariable,Operator,Selector,RuleSetVersion,Description
# 942100,RequestArgValues,Equals,test,3.2,"Exclude test parameter"
# 942110,RequestHeaderValues,Contains,Authorization,3.2,"Exclude auth header"
# 942120,RequestBodyPostArgNames,StartsWith,password,3.2,"Exclude password fields"

#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$PolicyName,
    
    # For single exclusion (original parameters)
    [Parameter(Mandatory=$false, ParameterSetName="SingleExclusion")]
    [string]$RuleId,
    
    [Parameter(Mandatory=$false, ParameterSetName="SingleExclusion")]
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
    
    [Parameter(Mandatory=$false, ParameterSetName="SingleExclusion")]
    [ValidateSet("Equals", "Contains", "StartsWith", "EndsWith", "EqualsAny")]
    [string]$Operator,
    
    [Parameter(Mandatory=$false, ParameterSetName="SingleExclusion")]
    [string]$Selector,
    
    # For multiple exclusions from CSV
    [Parameter(Mandatory=$false, ParameterSetName="MultipleExclusions")]
    [string]$CSVExclusionsPath,
    
    [Parameter(Mandatory=$false)]
    [string]$RuleInfoCSVPath = ".\RuleIDs-Feb-18-2026.csv",  # Default to your specific file
    
    [Parameter(Mandatory=$false)]
    [string]$RuleSetVersion = "3.2",  # Default to latest DRS
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipLegacyWarning,  # Skip legacy match variable warnings
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation,   # Skip "Proceed with creating this exclusion?" prompt
    
    [Parameter(Mandatory=$false)]
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
        Write-Error "Rule info CSV file not found at: $csvPath"
        Write-Host "Please ensure the CSV file exists with rule definitions." -ForegroundColor Yellow
        Write-Host "Expected file: RuleIDs-Feb-18-2026.csv" -ForegroundColor Gray
        return $null
    }
    
    # Import CSV and look for matching rule
    Write-Host "  Loading rule info CSV file..." -ForegroundColor Gray
    $rules = Import-Csv $csvPath
    
    # First try to find exact match with specified version
    $matchingRules = $rules | Where-Object { 
        $_.RuleId -eq $ruleId -and $_.RuleSetVersion -eq $ruleSetVersion
    }
    
    if ($matchingRules.Count -eq 0) {
        # Try without version filter
        $matchingRules = $rules | Where-Object { $_.RuleId -eq $ruleId }
        
        if ($matchingRules.Count -eq 0) {
            Write-Warning "Rule ID $ruleId not found in rule info CSV. Using minimal rule info."
            # Try to determine RuleSetType based on naming convention
            $ruleSetType = "OWASP"  # Default
            if ($ruleId -match "^990\d+") {
                $ruleSetType = "Microsoft_DefaultRuleSet"
            } elseif ($ruleId -match "^(BadBots|GoodBots|UnknownBots)") {
                $ruleSetType = "Microsoft_BotManagerRuleSet"
            }
            
            # Return a basic rule object
            return [PSCustomObject]@{
                RuleId = $ruleId
                RuleGroup = "Unknown"
                RuleSetType = $ruleSetType
                RuleSetVersion = $ruleSetVersion
                Description = "Rule ID $ruleId"
                Severity = "Unknown"
                ParanoiaLevel = "Unknown"
                Notes = "Rule info not found in CSV. Please verify RuleSetType and RuleGroup are correct."
            }
        } else {
            Write-Host "  ⚠️ Found Rule ID $ruleId but with different RuleSetVersion." -ForegroundColor Yellow
            Write-Host "     Available versions: $($matchingRules.RuleSetVersion -join ', ')" -ForegroundColor Gray
            
            # If we're in bulk mode with SkipConfirmation, use the first available version
            if ($SkipConfirmation) {
                Write-Host "     Using version: $($matchingRules[0].RuleSetVersion) (first available)" -ForegroundColor Yellow
                return $matchingRules[0]
            } else {
                # Ask user which version to use
                Write-Host "`nAvailable RuleSetVersions:" -ForegroundColor Yellow
                $versionOptions = $matchingRules | Select-Object RuleSetVersion -Unique | Sort-Object RuleSetVersion
                for ($i = 0; $i -lt $versionOptions.Count; $i++) {
                    Write-Host "  [$($i+1)] Version $($versionOptions[$i].RuleSetVersion)" -ForegroundColor Gray
                }
                
                $selection = Read-Host "`nSelect version number (1-$($versionOptions.Count))"
                if ($selection -match '^\d+$' -and [int]$selection -le $versionOptions.Count) {
                    $selectedVersion = $versionOptions[[int]$selection - 1].RuleSetVersion
                    return $matchingRules | Where-Object { $_.RuleSetVersion -eq $selectedVersion } | Select-Object -First 1
                } else {
                    Write-Warning "Invalid selection. Using first available version."
                    return $matchingRules[0]
                }
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
        "RequestHeaderKeys" { return "Excluding the **NAME** of the Header" }
        "RequestHeaderNames" { return "Excluding the **VALUE** of the Header (legacy mode)" }
        "RequestHeaderValues" { return "Excluding the **VALUE** of the Header" }
        
        "RequestCookieKeys" { return "Excluding the **NAME** of the Cookie" }
        "RequestCookieNames" { return "Excluding the **VALUE** of the Cookie (legacy mode)" }
        "RequestCookieValues" { return "Excluding the **VALUE** of the Cookie" }
        
        "RequestArgKeys" { return "Excluding the **NAME** of the Query/Post Argument" }
        "RequestArgNames" { return "Excluding the **VALUE** of the Query/Post Argument (legacy mode)" }
        "RequestArgValues" { return "Excluding the **VALUE** of the Query/Post Argument" }
        
        "RequestBodyPostArgNames" { return "Excluding POST form field NAMES" }
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

# Function to process a single exclusion
function Add-SingleExclusion {
    param(
        [object]$wafPolicy,
        [string]$ruleId,
        [string]$matchVariable,
        [string]$operator,
        [string]$selector,
        [string]$ruleSetVersion,
        [string]$ruleInfoCSVPath,
        [bool]$skipLegacyWarning,
        [bool]$skipConfirmation,
        [bool]$whatIf,
        [int]$exclusionNumber,
        [int]$totalExclusions
    )
    
    # Look up rule information from CSV
    if ($exclusionNumber -eq 0 -or $totalExclusions -eq 0) {
        Write-Host "📖 Looking up Rule ID $ruleId in rule info CSV..." -ForegroundColor Yellow
    } else {
        Write-Host "📖 [$exclusionNumber/$totalExclusions] Looking up Rule ID $ruleId in rule info CSV..." -ForegroundColor Yellow
    }
    $ruleInfo = Get-RuleInfoFromCSV -ruleId $ruleId -csvPath $ruleInfoCSVPath -ruleSetVersion $ruleSetVersion
    
    if ($ruleInfo -eq $null) {
        Write-Error "Failed to get rule info for Rule ID $ruleId. Skipping this exclusion."
        return $false
    }
    
    # Validate match variable
    if (-not (Test-MatchVariable -variable $matchVariable)) {
        Write-Error "Invalid MatchVariable '$matchVariable' for Rule ID $ruleId. Skipping this exclusion."
        return $false
    }
    
    # Show legacy warning if needed (and not skipped)
    $continueExecution = Show-LegacyWarning -variable $matchVariable -skipWarning $skipLegacyWarning
    if (-not $continueExecution) {
        Write-Host "Skipping exclusion for Rule ID $ruleId due to legacy warning." -ForegroundColor Yellow
        return $false
    }
    
    # Display found rule information
    if ($exclusionNumber -eq 0 -or $totalExclusions -eq 0) {
        Write-Host "`n✅ Found rule information:" -ForegroundColor Green
    } else {
        Write-Host "`n✅ [$exclusionNumber/$totalExclusions] Found rule information:" -ForegroundColor Green
    }
    Write-Host "  📌 Rule ID: $($ruleInfo.RuleId)" -ForegroundColor White
    Write-Host "  📁 Rule Group: $($ruleInfo.RuleGroup)" -ForegroundColor Cyan
    Write-Host "  🔧 Rule Set Type: $($ruleInfo.RuleSetType)" -ForegroundColor Cyan
    Write-Host "  📊 Rule Set Version: $($ruleInfo.RuleSetVersion)" -ForegroundColor Cyan
    Write-Host "  📝 Description: $($ruleInfo.Description)" -ForegroundColor Gray
    if ($ruleInfo.Severity -and $ruleInfo.Severity -ne "Unknown") {
        Write-Host "  ⚠️  Severity: $($ruleInfo.Severity)" -ForegroundColor $(if ($ruleInfo.Severity -eq "Critical") { "Red" } else { "Yellow" })
    }
    if ($ruleInfo.ParanoiaLevel -and $ruleInfo.ParanoiaLevel -ne "Unknown") {
        Write-Host "  🎚️  Paranoia Level: $($ruleInfo.ParanoiaLevel)" -ForegroundColor Magenta
    }
    
    # Show match variable interpretation
    Write-Host "`n📋 Match Variable Details:" -ForegroundColor Cyan
    Write-Host "  $(Get-MatchVariableDescription -variable $matchVariable)" -ForegroundColor White
    Write-Host "  Selector: '$selector' with operator '$operator'" -ForegroundColor White
    
    # Show notes if available
    if ($ruleInfo.Notes -and $ruleInfo.Notes -ne "") {
        Write-Host "`n💡 Notes: $($ruleInfo.Notes)" -ForegroundColor Yellow
    }
    
    if ($whatIf) {
        Write-Host "`n[WHAT-IF] Would create exclusion:" -ForegroundColor Yellow
        Write-Host "  🔢 Rule ID: $ruleId" -ForegroundColor Gray
        Write-Host "  📁 Rule Group: $($ruleInfo.RuleGroup)" -ForegroundColor Gray
        Write-Host "  🔧 Rule Set Type: $($ruleInfo.RuleSetType)" -ForegroundColor Gray
        Write-Host "  📊 Rule Set Version: $($ruleInfo.RuleSetVersion)" -ForegroundColor Gray
        Write-Host "  🔍 Match Variable: $matchVariable" -ForegroundColor Gray
        Write-Host "  ⚙️ Operator: $operator" -ForegroundColor Gray
        Write-Host "  🎯 Selector: $selector" -ForegroundColor Gray
        return $true
    }
    
    # Create the exclusion objects
    Write-Host "`n🔧 Creating rule-level exclusion..." -ForegroundColor Yellow
    
    # Create rule entry
    Write-Host "  - Creating managed rule..." -ForegroundColor Gray
    $ruleEntry = New-AzApplicationGatewayFirewallPolicyExclusionManagedRule -Rule $ruleId
    
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
        -MatchVariable $matchVariable `
        -SelectorMatchOperator $operator `
        -Selector $selector `
        -ExclusionManagedRuleSet $exclusionManagedRuleSet
    
    # Check if exclusion already exists
    Write-Host "  🔎 Checking for existing exclusions..." -ForegroundColor Yellow
    $existingExclusion = $wafPolicy.ManagedRules[0].Exclusions | Where-Object {
        $_.MatchVariable -eq $matchVariable -and
        $_.SelectorMatchOperator -eq $operator -and
        $_.Selector -eq $selector -and
        $_.ExclusionManagedRuleSets.RuleSetType -eq $ruleInfo.RuleSetType -and
        $_.ExclusionManagedRuleSets.RuleGroups.RuleGroupName -eq $ruleInfo.RuleGroup -and
        ($_.ExclusionManagedRuleSets.RuleGroups.Rules.RuleId -contains $ruleId)
    }
    
    if ($existingExclusion) {
        Write-Host "  ⚠️ An identical exclusion already exists in the policy." -ForegroundColor Yellow
        if (-not $skipConfirmation) {
            $response = Read-Host "  Do you want to add it anyway? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "  Skipping this exclusion." -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "  Adding duplicate exclusion anyway (SkipConfirmation enabled)." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✅ No duplicate exclusion found" -ForegroundColor Green
    }
    
    # Add exclusion to policy
    Write-Host "  📝 Adding exclusion to policy..." -ForegroundColor Yellow
    $wafPolicy.ManagedRules[0].Exclusions.Add($exclusionEntry)
    
    return $true
}

# Function to load exclusions from CSV
function Get-ExclusionsFromCSV {
    param([string]$csvPath)
    
    if (-not (Test-Path $csvPath)) {
        Write-Error "Exclusions CSV file not found at: $csvPath"
        Write-Host "Please ensure the CSV file exists with the following format:" -ForegroundColor Yellow
        Write-Host "RuleId,MatchVariable,Operator,Selector,RuleSetVersion,Description" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "Loading exclusions from CSV: $csvPath" -ForegroundColor Yellow
    $exclusions = Import-Csv $csvPath
    
    # Validate required columns
    $requiredColumns = @("RuleId", "MatchVariable", "Operator", "Selector")
    $missingColumns = $requiredColumns | Where-Object { $_ -notin ($exclusions[0].PSObject.Properties.Name) }
    
    if ($missingColumns.Count -gt 0) {
        Write-Error "CSV is missing required columns: $($missingColumns -join ', ')"
        Write-Host "Required columns: RuleId, MatchVariable, Operator, Selector" -ForegroundColor Yellow
        Write-Host "Optional columns: RuleSetVersion, Description" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "Found $($exclusions.Count) exclusions in CSV file" -ForegroundColor Green
    return $exclusions
}

# Main script execution
try {
    # Display banner
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   WAF Exclusion Creator (Single or Bulk from CSV)" -ForegroundColor Cyan
    Write-Host "================================================`n" -ForegroundColor Cyan
    
    # Check which parameter set is being used
    $isBulkMode = $PSCmdlet.ParameterSetName -eq "MultipleExclusions"
    
    if ($isBulkMode) {
        Write-Host "📋 BULK MODE: Adding multiple exclusions from CSV" -ForegroundColor Green
    } else {
        Write-Host "📋 SINGLE MODE: Adding one exclusion" -ForegroundColor Green
    }
    
    # Get the existing WAF policy once (shared for both modes)
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
    Write-Host "  Current exclusion count: $($wafPolicy.ManagedRules[0].Exclusions.Count)" -ForegroundColor Gray
    
    # Process exclusions based on mode
    $exclusionsAdded = 0
    $exclusionsSkipped = 0
    
    if ($isBulkMode) {
        # Bulk mode: Load exclusions from CSV
        $exclusions = Get-ExclusionsFromCSV -csvPath $CSVExclusionsPath
        $totalExclusions = $exclusions.Count
        
        if (-not $SkipConfirmation) {
            Write-Host "`n" -ForegroundColor Gray
            $confirm = Read-Host "Proceed with adding $totalExclusions exclusions? (y/N)"
            if ($confirm -ne 'y' -and $confirm -ne 'Y') {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
                exit 0
            }
        } else {
            Write-Host "`n⏩ Skipping confirmation (automatically proceeding with $totalExclusions exclusions)..." -ForegroundColor Yellow
        }
        
        $counter = 0
        foreach ($exclusion in $exclusions) {
            $counter++
            Write-Host "`n$('='*50)" -ForegroundColor Cyan
            Write-Host "Processing exclusion $counter of $totalExclusions" -ForegroundColor Cyan
            Write-Host "$('='*50)" -ForegroundColor Cyan
            
            $ruleSetVer = if ($exclusion.RuleSetVersion) { $exclusion.RuleSetVersion } else { $RuleSetVersion }
            
            $result = Add-SingleExclusion `
                -wafPolicy $wafPolicy `
                -ruleId $exclusion.RuleId `
                -matchVariable $exclusion.MatchVariable `
                -operator $exclusion.Operator `
                -selector $exclusion.Selector `
                -ruleSetVersion $ruleSetVer `
                -ruleInfoCSVPath $RuleInfoCSVPath `
                -skipLegacyWarning $SkipLegacyWarning `
                -skipConfirmation $SkipConfirmation `
                -whatIf $WhatIf `
                -exclusionNumber $counter `
                -totalExclusions $totalExclusions
            
            if ($result) {
                $exclusionsAdded++
            } else {
                $exclusionsSkipped++
            }
        }
    } else {
        # Single mode: Use parameters
        if (-not $RuleId -or -not $MatchVariable -or -not $Operator -or -not $Selector) {
            Write-Error "For single exclusion mode, all parameters (RuleId, MatchVariable, Operator, Selector) are required."
            exit 1
        }
        
        $result = Add-SingleExclusion `
            -wafPolicy $wafPolicy `
            -ruleId $RuleId `
            -matchVariable $MatchVariable `
            -operator $Operator `
            -selector $Selector `
            -ruleSetVersion $RuleSetVersion `
            -ruleInfoCSVPath $RuleInfoCSVPath `
            -skipLegacyWarning $SkipLegacyWarning `
            -skipConfirmation $SkipConfirmation `
            -whatIf $WhatIf
        
        if ($result) {
            $exclusionsAdded = 1
        } else {
            $exclusionsSkipped = 1
        }
    }
    
    # Update the policy if changes were made and not in WhatIf mode
    if ($exclusionsAdded -gt 0 -and -not $WhatIf) {
        Write-Host "`n🔄 Updating WAF policy in Azure with $exclusionsAdded new exclusions..." -ForegroundColor Yellow
        $updatedPolicy = $wafPolicy | Set-AzApplicationGatewayFirewallPolicy
        
        # Success message
        Write-Host "`n✅ SUCCESS! Policy updated successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Policy ETag: $($updatedPolicy.Etag)" -ForegroundColor Cyan
        Write-Host "Policy Provisioning State: $($updatedPolicy.ProvisioningState)" -ForegroundColor Cyan
        Write-Host "Exclusions added: $exclusionsAdded" -ForegroundColor Green
        if ($exclusionsSkipped -gt 0) {
            Write-Host "Exclusions skipped: $exclusionsSkipped" -ForegroundColor Yellow
        }
        Write-Host "New total exclusion count: $($updatedPolicy.ManagedRules[0].Exclusions.Count)" -ForegroundColor Cyan
    } elseif ($WhatIf) {
        Write-Host "`n[WHAT-IF] Would have added $exclusionsAdded exclusions to the policy." -ForegroundColor Yellow
    } else {
        Write-Host "`nNo exclusions were added to the policy." -ForegroundColor Yellow
    }
    
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
        Write-Host "`n💡 Tip: The match variable may not be supported with your rule set version." -ForegroundColor Yellow
        Write-Host "   Try using a legacy variant (e.g., RequestHeaderNames instead of RequestHeaderValues)" -ForegroundColor Gray
    }
    
    exit 1
}
