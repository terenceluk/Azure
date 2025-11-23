# Requires Az.Accounts & Az.Network
# Connect-AzAccount (if you aren’t already)

$ruleSets = Get-AzApplicationGatewayAvailableWafRuleSets

# Helper: try to resolve a CRS 3.2 object from any input shape
function Get-Crs32FromRuleSets {
    param(
        [Parameter(Mandatory=$true)] $InputRuleSets
    )

    # 1) Try native shape (top-level properties)
    $native = $InputRuleSets | Where-Object {
        $_.RuleSetType -eq 'OWASP' -and $_.RuleSetVersion -eq '3.2'
    }
    if ($native) { return $native }

    # 2) Some builds expose "ValueText" JSON (string) on one or more entries
    $withJson = $InputRuleSets | Where-Object { $_.PSObject.Properties.Name -contains 'ValueText' -and $_.ValueText }

    foreach ($entry in $withJson) {
        try {
            $parsed = $entry.ValueText | ConvertFrom-Json

            # If ValueText is an array of ruleset objects, select the OWASP 3.2 one
            if ($parsed -is [System.Collections.IEnumerable]) {
                $candidate = $parsed | Where-Object {
                    $_.RuleSetType -eq 'OWASP' -and $_.RuleSetVersion -eq '3.2'
                }
                if ($candidate) { return $candidate }
            }
            else {
                # ValueText was a single object
                if ($parsed.RuleSetType -eq 'OWASP' -and $parsed.RuleSetVersion -eq '3.2') {
                    return $parsed
                }
            }
        }
        catch {
            Write-Warning ("Failed to parse ValueText JSON: {0}" -f $_.Exception.Message)
        }
    }

    # 3) Last resort: look at Name/Value lists to find "OWASP_3.2" and re-parse its ValueText
    $named = $InputRuleSets | Where-Object {
        ($_.PSObject.Properties.Name -contains 'Name' -and $_.Name -eq 'OWASP_3.2') -or
        ($_.PSObject.Properties.Name -contains 'Value' -and ($_.Value -is [System.Array]) -and ($_.Value -contains 'OWASP_3.2'))
    }
    foreach ($entry in $named) {
        if ($entry.ValueText) {
            try {
                $parsed = $entry.ValueText | ConvertFrom-Json
                $candidate = $parsed | Where-Object {
                    $_.RuleSetType -eq 'OWASP' -and $_.RuleSetVersion -eq '3.2'
                }
                if ($candidate) { return $candidate }
            }
            catch {
                Write-Warning ("Failed to parse ValueText JSON in fallback: {0}" -f $_.Exception.Message)
            }
        }
    }

    return $null
}

$crs32 = Get-Crs32FromRuleSets -InputRuleSets $ruleSets

if (-not $crs32) {
    Write-Error "Could not resolve OWASP_3.2 ruleset from Get-AzApplicationGatewayAvailableWafRuleSets."
    # For diagnostics, dump shapes:
    $ruleSets | Select-Object -First 1 | Format-List *
    return
}

# Flatten RuleGroups -> Rules to CSV rows
$rows = foreach ($rg in ($crs32.RuleGroups | Where-Object { $_ })) {
    foreach ($rule in ($rg.Rules | Where-Object { $_ })) {
        [PSCustomObject]@{
            RuleId        = $rule.RuleId
            Description   = $rule.Description
            RuleGroupName = $rg.RuleGroupName
            State         = $rule.State
            Action        = $rule.Action
        }
    }
}

# Write CSV
$csvPath = "OWASP_3_2_rules.csv"
$rows | Sort-Object RuleGroupName, RuleId | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($rows.Count) rules to $csvPath"
