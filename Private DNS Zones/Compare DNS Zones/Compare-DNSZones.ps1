<#
.SYNOPSIS
    Compares Private DNS zones between two Azure tenants with enhanced reporting

.DESCRIPTION
    This script compares Private DNS zones between two Azure tenants to identify discrepancies,
    missing records, and configuration differences. It generates comprehensive reports in 
    HTML, CSV, and JSON formats with detailed comparison results.

.PARAMETER TenantAConfig
    PSCustomObject containing configuration for Tenant A (usually Production)

.PARAMETER TenantBConfig
    PSCustomObject containing configuration for Tenant B (usually DR/Secondary)

.PARAMETER ZoneMappings
    Array of zone mapping objects specifying which zones to compare and their resource groups

.PARAMETER ExcludeZones
    Array of zone names to exclude from comparison

.PARAMETER IncludeOnlyZones
    Array of zone names to include (if specified, only these zones will be processed)

.PARAMETER SendEmail
    Switch to enable email sending (requires additional email configuration)

.PARAMETER OutputPath
    Path where report files will be saved (default: ".\DNSReports")

.PARAMETER GenerateHtmlFile
    Switch to force HTML report generation even if not specified in OutputFormats

.PARAMETER OutputFormats
    Array of output formats: "Console", "HTML", "CSV", "JSON" (default: all formats)

.EXAMPLE
    # METHOD 1: Basic usage with config file (Recommended for production)
    $config = Get-Content -Path "config.json" | ConvertFrom-Json
    .\Compare-DNSZones.ps1 -TenantAConfig $config.TenantAConfig -TenantBConfig $config.TenantBConfig -ZoneMappings $config.ZoneMappings

.EXAMPLE
    # METHOD 2: Define variables directly in PowerShell
    $tenantA = @{
        TenantId       = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
        SubscriptionId = "sub-tenant-a-12345"
        ClientId       = "app-registration-id-a"
        ClientSecret   = "client-secret-for-tenant-a"
        DisplayName    = "Production Tenant"
    }
    $tenantB = @{
        TenantId       = "z9y8x7w6-v5u4-3210-zyxw-vu9876543210"
        SubscriptionId = "sub-tenant-b-67890"
        ClientId       = "app-registration-id-b"
        ClientSecret   = "client-secret-for-tenant-b"
        DisplayName    = "DR Tenant"
    }
    $zones = @(
        @{ZoneName="privatelink.azurewebsites.net"; TenantAResourceGroup="rg-dns-a"; TenantBResourceGroup="rg-dns-b"}
    )
    .\Compare-DNSZones.ps1 -TenantAConfig $tenantA -TenantBConfig $tenantB -ZoneMappings $zones

.EXAMPLE
    # METHOD 3: Use PowerShell splatting for cleaner syntax
    $params = @{
        TenantAConfig = @{
            TenantId       = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
            SubscriptionId = "sub-tenant-a-12345"
            ClientId       = "app-registration-id-a"
            ClientSecret   = "client-secret-for-tenant-a"
            DisplayName    = "Production Tenant"
        }
        TenantBConfig = @{
            TenantId       = "z9y8x7w6-v5u4-3210-zyxw-vu9876543210"
            SubscriptionId = "sub-tenant-b-67890"
            ClientId       = "app-registration-id-b"
            ClientSecret   = "client-secret-for-tenant-b"
            DisplayName    = "DR Tenant"
        }
        ZoneMappings = @(
            @{ZoneName="privatelink.database.windows.net"; TenantAResourceGroup="rg-dbs-a"; TenantBResourceGroup="rg-dbs-b"}
        )
        OutputFormats = @("HTML", "CSV")
        OutputPath    = "C:\Reports\DNS"
    }
    .\Compare-DNSZones.ps1 @params

.EXAMPLE
    # METHOD 4: Prompt for secrets securely (no hardcoded secrets)
    $tenantA = @{
        TenantId       = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
        SubscriptionId = "sub-tenant-a-12345"
        ClientId       = "app-registration-id-a"
        ClientSecret   = (Read-Host -Prompt "Enter Tenant A Client Secret" -AsSecureString | ConvertFrom-SecureString -AsPlainText)
        DisplayName    = "Production Tenant"
    }
    # ... define tenantB and zones similarly
    .\Compare-DNSZones.ps1 -TenantAConfig $tenantA -TenantBConfig $tenantB -ZoneMappings $zones

.EXAMPLE
    # With specific output formats and custom path
    .\Compare-DNSZones.ps1 -TenantAConfig $tenantA -TenantBConfig $tenantB -ZoneMappings $zones `
        -OutputFormats @("HTML", "CSV") -OutputPath "C:\Reports\DNS"

.EXAMPLE
    # Filter specific zones only
    .\Compare-DNSZones.ps1 -TenantAConfig $tenantA -TenantBConfig $tenantB -ZoneMappings $zones `
        -IncludeOnlyZones @("privatelink.database.windows.net", "privatelink.blob.core.windows.net")

.EXAMPLE
    # Exclude specific zones
    .\Compare-DNSZones.ps1 -TenantAConfig $tenantA -TenantBConfig $tenantB -ZoneMappings $zones `
        -ExcludeZones @("privatelink.servicebus.windows.net")

.NOTES
    PREREQUISITES:
    
    REQUIRED POWERSHELL MODULES:
    - Az.Accounts: For authentication and context management
    - Az.PrivateDns: For DNS zone and record operations
    
    INSTALLATION COMMANDS (Run as Administrator):
    # Install for current user
    Install-Module -Name Az.Accounts -Force -AllowClobber -Scope CurrentUser
    Install-Module -Name Az.PrivateDns -Force -AllowClobber -Scope CurrentUser
    
    # Install for all users (requires admin privileges)
    Install-Module -Name Az.Accounts -Force -AllowClobber -Scope AllUsers
    Install-Module -Name Az.PrivateDns -Force -AllowClobber -Scope AllUsers
    
    # Update existing modules
    Update-Module -Name Az.Accounts
    Update-Module -Name Az.PrivateDns
    
    # Import modules (usually auto-imported, but can be explicit)
    Import-Module Az.Accounts
    Import-Module Az.PrivateDns

    REQUIRED PERMISSIONS:
    - App Registrations in both tenants need DNS Reader role on the resource groups
    - Service Principal must have access to read Private DNS zones

    CONFIGURATION OPTIONS:

    Option 1: config.json file
    {
        "TenantAConfig": {
            "TenantId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "SubscriptionId": "sub-tenant-a-12345",
            "ClientId": "app-registration-id-a",
            "ClientSecret": "client-secret-for-tenant-a",
            "DisplayName": "Production Tenant"
        },
        "TenantBConfig": {
            "TenantId": "z9y8x7w6-v5u4-3210-zyxw-vu9876543210",
            "SubscriptionId": "sub-tenant-b-67890",
            "ClientId": "app-registration-id-b",
            "ClientSecret": "client-secret-for-tenant-b",
            "DisplayName": "DR Tenant"
        },
        "ZoneMappings": [
            {
                "ZoneName": "privatelink.azurewebsites.net",
                "TenantAResourceGroup": "rg-dns-core-services-a",
                "TenantBResourceGroup": "rg-dns-core-services-b"
            }
        ]
    }

    Option 2: PowerShell variables (Quick testing)
    - Define $tenantA, $tenantB, and $zones as hashtables in your PowerShell session
    - Useful for development and one-off executions

    Option 3: Secure secret management (Production)
    - Use PowerShell SecretManagement module for secure secret storage
    - Use Azure Key Vault for enterprise environments
    - Use CI/CD pipeline variables for automated execution

    TROUBLESHOOTING:
    - If you get "Connect-AzAccount not recognized": Install Az.Accounts module
    - If you get "Get-AzPrivateDnsZone not recognized": Install Az.PrivateDns module
    - If authentication fails: Verify ClientSecret and permissions
    - If access denied: Check if service principal has DNS Reader role on resource groups

    SECURITY NOTES:
    - TenantId, SubscriptionId, and ClientId are NOT secrets and can be stored safely
    - ClientSecret is HIGHLY SENSITIVE and should be stored securely
    - Never commit ClientSecret to source control
    - Use secure methods like Key Vault, SecretManagement, or environment variables for secrets

    OUTPUT FILES GENERATED:
    - DNS_Comparison_Report_{timestamp}.html: Interactive HTML report with collapsible sections
    - DNS_Comparison_Report_{timestamp}.csv: Detailed CSV with discrepancy information
    - DNS_Comparison_Report_{timestamp}.json: Machine-readable JSON format
    - Complete_DNS_Records_{timestamp}.csv: Complete dump of all DNS records from both tenants

    FEATURES:
    - Compares A, CNAME, AAAA, MX, TXT, SRV, PTR, SOA, and NS records
    - Identifies missing records, mismatched TTLs, and data discrepancies
    - Handles zones that exist in one tenant but not the other
    - Generates executive summary with statistics
    - Provides detailed per-zone breakdowns
    - Supports multiple output formats simultaneously

.VERSION
    1.0.0

.AUTHOR
    Terence Luk

.LINK
    Project Repository: https://github.com/terenceluk/Azure/
    Az.Accounts Module: https://docs.microsoft.com/powershell/module/az.accounts
    Az.PrivateDns Module: https://docs.microsoft.com/powershell/module/az.privatedns

#>

param(
    [Parameter(Mandatory = $true)]
    [PSCustomObject]$TenantAConfig,
    
    [Parameter(Mandatory = $true)]
    [PSCustomObject]$TenantBConfig,
    
    [Parameter(Mandatory = $false)]
    [PSCustomObject[]]$ZoneMappings = @(),
    
    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeZones = @(),
    
    [Parameter(Mandatory = $false)]
    [string[]]$IncludeOnlyZones = @(),
    
    [Parameter(Mandatory = $false)]
    [switch]$SendEmail,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\DNSReports",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHtmlFile,
    
    [Parameter(Mandatory = $false)]
    [string[]]$OutputFormats = @("Console", "HTML", "CSV", "JSON")
)

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Set display names for tenants
$TenantAName = if ($TenantAConfig.DisplayName) { $TenantAConfig.DisplayName } else { "Tenant A" }
$TenantBName = if ($TenantBConfig.DisplayName) { $TenantBConfig.DisplayName } else { "Tenant B" }

class DnsComparisonResult {
    [string]$ZoneName
    [string]$TenantAResourceGroup
    [string]$TenantBResourceGroup
    [array]$MissingInTenantA
    [array]$MissingInTenantB
    [array]$MismatchedRecords
    [datetime]$ComparisonTime
    [bool]$HasErrors
    [string]$ErrorMessage
    [bool]$ZoneExistsInTenantA
    [bool]$ZoneExistsInTenantB
    [int]$TotalDiscrepancies
}

class DnsDiscrepancy {
    [string]$RecordName
    [string]$RecordType
    [string]$TenantAData
    [string]$TenantBData
    [int]$TenantATTL
    [int]$TenantBTTL
    [string]$DiscrepancyType
}

function Get-DnsZoneRecords {
    param(
        [string]$ZoneName,
        [string]$ResourceGroupName,
        [PSCustomObject]$TenantConfig,
        [string]$TenantName
    )
    
    try {
        Write-Host "Getting records for $ZoneName from Resource Group '$ResourceGroupName' in $TenantName..."
        
        # Connect to tenant if not already connected
        $context = Get-AzContext
        if ($context -eq $null -or $context.Tenant.Id -ne $TenantConfig.TenantId) {
            $securePassword = ConvertTo-SecureString $TenantConfig.ClientSecret -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential($TenantConfig.ClientId, $securePassword)
            
            Connect-AzAccount -Credential $credential -Tenant $TenantConfig.TenantId -ServicePrincipal -WarningAction SilentlyContinue | Out-Null
        }
        
        # Set subscription context
        Set-AzContext -SubscriptionId $TenantConfig.SubscriptionId -WarningAction SilentlyContinue | Out-Null
        
        # Check if zone exists first
        $zone = Get-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName -ErrorAction SilentlyContinue
        
        if (-not $zone) {
            return @{
                Success    = $true
                Records    = @()
                ZoneExists = $false
                Error      = $null
            }
        }
        
        # Get all record sets
        $recordSets = Get-AzPrivateDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName
        
        return @{
            Success    = $true
            Records    = $recordSets
            ZoneExists = $true
            Error      = $null
        }
    }
    catch {
        return @{
            Success    = $false
            Records    = $null
            ZoneExists = $false
            Error      = $_.Exception.Message
        }
    }
}

function Compare-DnsRecords {
    param(
        [array]$TenantARecords,
        [array]$TenantBRecords,
        [string]$ZoneName,
        [string]$TenantAResourceGroup,
        [string]$TenantBResourceGroup,
        [bool]$ZoneExistsInTenantA,
        [bool]$ZoneExistsInTenantB
    )
    
    $result = [DnsComparisonResult]::new()
    $result.ZoneName = $ZoneName
    $result.TenantAResourceGroup = $TenantAResourceGroup
    $result.TenantBResourceGroup = $TenantBResourceGroup
    $result.ComparisonTime = Get-Date
    $result.ZoneExistsInTenantA = $ZoneExistsInTenantA
    $result.ZoneExistsInTenantB = $ZoneExistsInTenantB
    $result.MissingInTenantA = @()
    $result.MissingInTenantB = @()
    $result.MismatchedRecords = @()
    
    # Handle cases where zones don't exist
    if (-not $ZoneExistsInTenantA -and -not $ZoneExistsInTenantB) {
        $result.HasErrors = $false
        return $result
    }
    
    if (-not $ZoneExistsInTenantA) {
        $result.HasErrors = $true
        $result.ErrorMessage = "Zone does not exist in Tenant A (Resource Group: $TenantAResourceGroup)"
        return $result
    }
    
    if (-not $ZoneExistsInTenantB) {
        $result.HasErrors = $true
        $result.ErrorMessage = "Zone does not exist in Tenant B (Resource Group: $TenantBResourceGroup)"
        return $result
    }
    
    # Create hashtables for quick lookup
    $tenantALookup = @{}
    $tenantBLookup = @{}
    
    # Populate Tenant A lookup
    foreach ($record in $TenantARecords) {
        $key = "$($record.Name)|$($record.RecordType)"
        $tenantALookup[$key] = $record
    }
    
    # Populate Tenant B lookup  
    foreach ($record in $TenantBRecords) {
        $key = "$($record.Name)|$($record.RecordType)"
        $tenantBLookup[$key] = $record
    }
    
    # Find records missing in Tenant A
    foreach ($key in $tenantBLookup.Keys) {
        if (-not $tenantALookup.ContainsKey($key)) {
            $discrepancy = [DnsDiscrepancy]::new()
            $discrepancy.RecordName = $tenantBLookup[$key].Name
            $discrepancy.RecordType = $tenantBLookup[$key].RecordType
            $discrepancy.TenantBData = Get-RecordData -RecordSet $tenantBLookup[$key]
            $discrepancy.TenantBTTL = $tenantBLookup[$key].Ttl
            $discrepancy.DiscrepancyType = "MissingInTenantA"
            
            $result.MissingInTenantA += $discrepancy
        }
    }
    
    # Find records missing in Tenant B
    foreach ($key in $tenantALookup.Keys) {
        if (-not $tenantBLookup.ContainsKey($key)) {
            $discrepancy = [DnsDiscrepancy]::new()
            $discrepancy.RecordName = $tenantALookup[$key].Name
            $discrepancy.RecordType = $tenantALookup[$key].RecordType
            $discrepancy.TenantAData = Get-RecordData -RecordSet $tenantALookup[$key]
            $discrepancy.TenantATTL = $tenantALookup[$key].Ttl
            $discrepancy.DiscrepancyType = "MissingInTenantB"
            
            $result.MissingInTenantB += $discrepancy
        }
    }
    
    # Find mismatched records (exist in both but different data/TTL)
    foreach ($key in $tenantALookup.Keys) {
        if ($tenantBLookup.ContainsKey($key)) {
            $recordA = $tenantALookup[$key]
            $recordB = $tenantBLookup[$key]
            
            $dataA = Get-RecordData -RecordSet $recordA
            $dataB = Get-RecordData -RecordSet $recordB
            
            if ($dataA -ne $dataB -or $recordA.Ttl -ne $recordB.Ttl) {
                $discrepancy = [DnsDiscrepancy]::new()
                $discrepancy.RecordName = $recordA.Name
                $discrepancy.RecordType = $recordA.RecordType
                $discrepancy.TenantAData = $dataA
                $discrepancy.TenantBData = $dataB
                $discrepancy.TenantATTL = $recordA.Ttl
                $discrepancy.TenantBTTL = $recordB.Ttl
                $discrepancy.DiscrepancyType = "MismatchedRecord"
                
                $result.MismatchedRecords += $discrepancy
            }
        }
    }
    
    $result.TotalDiscrepancies = $result.MissingInTenantA.Count + $result.MissingInTenantB.Count + $result.MismatchedRecords.Count
    return $result
}

function Get-RecordData {
    param($RecordSet)
    
    switch ($RecordSet.RecordType) {
        "A" { 
            if ($RecordSet.Records -and $RecordSet.Records.Ipv4Address) {
                return ($RecordSet.Records.Ipv4Address -join ", ")
            }
            return "No A records"
        }
        "AAAA" { 
            if ($RecordSet.Records -and $RecordSet.Records.Ipv6Address) {
                return ($RecordSet.Records.Ipv6Address -join ", ")
            }
            return "No AAAA records"
        }
        "CNAME" { 
            if ($RecordSet.Records -and $RecordSet.Records.Cname) {
                return $RecordSet.Records.Cname
            }
            return "No CNAME record"
        }
        "MX" { 
            if ($RecordSet.Records -and $RecordSet.Records.Exchange) {
                $mxRecords = foreach ($mx in $RecordSet.Records) {
                    "Preference: $($mx.Preference), Exchange: $($mx.Exchange)"
                }
                return ($mxRecords -join " | ")
            }
            return "No MX records"
        }
        "TXT" { 
            if ($RecordSet.Records -and $RecordSet.Records.Value) {
                return ($RecordSet.Records.Value -join ", ")
            }
            return "No TXT records"
        }
        "SRV" { 
            if ($RecordSet.Records) {
                $srvRecords = foreach ($srv in $RecordSet.Records) {
                    "Priority: $($srv.Priority), Weight: $($srv.Weight), Port: $($srv.Port), Target: $($srv.Target)"
                }
                return ($srvRecords -join " | ")
            }
            return "No SRV records"
        }
        "PTR" { 
            if ($RecordSet.Records -and $RecordSet.Records.Ptrdname) {
                return ($RecordSet.Records.Ptrdname -join ", ")
            }
            return "No PTR records"
        }
        "SOA" { 
            if ($RecordSet.Records) {
                $soa = $RecordSet.Records
                return "Host: $($soa.Host), Email: $($soa.Email), Serial: $($soa.SerialNumber), Refresh: $($soa.RefreshTime), Retry: $($soa.RetryTime), Expire: $($soa.ExpireTime), MinTTL: $($soa.MinimumTtl)"
            }
            return "No SOA record"
        }
        "NS" { 
            if ($RecordSet.Records -and $RecordSet.Records.Nsdname) {
                return ($RecordSet.Records.Nsdname -join ", ")
            }
            return "No NS records"
        }
        default { 
            return "Unsupported record type: $($RecordSet.RecordType)"
        }
    }
}

function Export-AllDnsRecords {
    param(
        [array]$ZoneMappings,
        [PSCustomObject]$TenantAConfig,
        [PSCustomObject]$TenantBConfig,
        [string]$FilePath,
        [string]$TenantAName,
        [string]$TenantBName
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $fullPath = Join-Path $FilePath "Complete_DNS_Records_$timestamp.csv"
    
    $allRecords = @()
    
    Write-Host "`nExporting complete DNS records from both tenants..." -ForegroundColor Cyan
    
    foreach ($zoneMapping in $ZoneMappings) {
        $zoneName = $zoneMapping.ZoneName
        $tenantARG = $zoneMapping.TenantAResourceGroup
        $tenantBRG = $zoneMapping.TenantBResourceGroup
        
        Write-Host "Processing zone: $zoneName" -ForegroundColor Yellow
        
        # Get records from Tenant A
        $tenantAResult = Get-DnsZoneRecords -ZoneName $zoneName -ResourceGroupName $tenantARG -TenantConfig $TenantAConfig -TenantName $TenantAName
        
        if ($tenantAResult.Success -and $tenantAResult.ZoneExists) {
            foreach ($record in $tenantAResult.Records) {
                $recordData = Get-RecordData -RecordSet $record
                $allRecords += [PSCustomObject]@{
                    ZoneName = $zoneName
                    Tenant = $TenantAName
                    ResourceGroup = $tenantARG
                    RecordName = $record.Name
                    RecordType = $record.RecordType
                    RecordData = $recordData
                    TTL = $record.Ttl
                    RecordCount = if ($record.Records) { $record.Records.Count } else { 0 }
                    Etag = $record.Etag
                    Status = "Exists"
                }
            }
            Write-Host "  ✓ ${TenantAName}: $($tenantAResult.Records.Count) records found" -ForegroundColor Green
        } else {
            $allRecords += [PSCustomObject]@{
                ZoneName = $zoneName
                Tenant = $TenantAName
                ResourceGroup = $tenantARG
                RecordName = "N/A"
                RecordType = "N/A"
                RecordData = "Zone not found or error accessing zone"
                TTL = 0
                RecordCount = 0
                Etag = "N/A"
                Status = "Error"
            }
            Write-Host "  ⚠ ${TenantAName}: Zone not found or error" -ForegroundColor Yellow
        }
        
        # Get records from Tenant B
        $tenantBResult = Get-DnsZoneRecords -ZoneName $zoneName -ResourceGroupName $tenantBRG -TenantConfig $TenantBConfig -TenantName $TenantBName
        
        if ($tenantBResult.Success -and $tenantBResult.ZoneExists) {
            foreach ($record in $tenantBResult.Records) {
                $recordData = Get-RecordData -RecordSet $record
                $allRecords += [PSCustomObject]@{
                    ZoneName = $zoneName
                    Tenant = $TenantBName
                    ResourceGroup = $tenantBRG
                    RecordName = $record.Name
                    RecordType = $record.RecordType
                    RecordData = $recordData
                    TTL = $record.Ttl
                    RecordCount = if ($record.Records) { $record.Records.Count } else { 0 }
                    Etag = $record.Etag
                    Status = "Exists"
                }
            }
            Write-Host "  ✓ ${TenantBName}: $($tenantBResult.Records.Count) records found" -ForegroundColor Green
        } else {
            $allRecords += [PSCustomObject]@{
                ZoneName = $zoneName
                Tenant = $TenantBName
                ResourceGroup = $tenantBRG
                RecordName = "N/A"
                RecordType = "N/A"
                RecordData = "Zone not found or error accessing zone"
                TTL = 0
                RecordCount = 0
                Etag = "N/A"
                Status = "Error"
            }
            Write-Host "  ⚠ ${TenantBName}: Zone not found or error" -ForegroundColor Yellow
        }
    }
    
    try {
        $allRecords | Export-Csv -Path $fullPath -NoTypeInformation
        Write-Host "✅ Complete DNS records export saved: $fullPath" -ForegroundColor Green
        return $fullPath
    }
    catch {
        Write-Error "Failed to save complete DNS records export: $($_.Exception.Message)"
        return $null
    }
}

function Show-RecordSummary {
    param(
        [array]$AllRecords,
        [string]$TenantAName,
        [string]$TenantBName
    )
    
    $tenantARecords = $AllRecords | Where-Object { $_.Tenant -eq $TenantAName -and $_.Status -eq "Exists" }
    $tenantBRecords = $AllRecords | Where-Object { $_.Tenant -eq $TenantBName -and $_.Status -eq "Exists" }
    
    $uniqueZones = $AllRecords | Select-Object ZoneName -Unique
    
    Write-Host "`n" + "="*60 -ForegroundColor Magenta
    Write-Host "COMPLETE DNS RECORDS SUMMARY" -ForegroundColor Magenta
    Write-Host "="*60 -ForegroundColor Magenta
    Write-Host "Total Zones Processed: $($uniqueZones.Count)" -ForegroundColor White
    Write-Host "$TenantAName Total Records: $($tenantARecords.Count)" -ForegroundColor Green
    Write-Host "$TenantBName Total Records: $($tenantBRecords.Count)" -ForegroundColor Green
    
    # Show record types breakdown
    Write-Host "`nRecord Type Breakdown:" -ForegroundColor Yellow
    $allExistingRecords = $AllRecords | Where-Object { $_.Status -eq "Exists" }
    $allExistingRecords | Group-Object RecordType | Sort-Object Count -Descending | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count) records" -ForegroundColor Gray
    }
}

function New-HtmlReport {
    param(
        [array]$Results,
        [string]$FilePath,
        [string]$TenantAName,
        [string]$TenantBName,
        [PSCustomObject]$TenantAConfig,
        [PSCustomObject]$TenantBConfig
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $fullPath = Join-Path $FilePath "DNS_Comparison_Report_$timestamp.html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>DNS Zone Comparison Report</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #0078D4 0%, #106EBE 100%);
            color: white;
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        .zone { 
            margin-bottom: 15px; 
            border: 1px solid #e0e0e0; 
            border-radius: 8px;
            background: #fafafa;
            overflow: hidden;
        }
        .zone-header {
            padding: 20px;
            background: white;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: background-color 0.3s;
        }
        .zone-header:hover {
            background-color: #f0f0f0;
        }
        .zone-content {
            padding: 0 20px;
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease-out, padding 0.3s ease-out;
        }
        .zone.expanded .zone-content {
            padding: 20px;
            max-height: 5000px;
        }
        .discrepancy { 
            background-color: #FFF4CE; 
            padding: 12px; 
            margin: 8px 0; 
            border-left: 4px solid #FFC107;
            border-radius: 4px;
        }
        .error { 
            background-color: #FED9D9; 
            padding: 15px; 
            margin: 10px 0; 
            border-left: 4px solid #DC3545;
            border-radius: 4px;
        }
        .summary { 
            background-color: #E8F4FD; 
            padding: 25px; 
            margin: 25px 0; 
            border-radius: 8px;
            border-left: 4px solid #0078D4;
        }
        .warning { 
            background-color: #FFF3CD; 
            padding: 15px; 
            margin: 10px 0; 
            border-left: 4px solid #FFC107;
            border-radius: 4px;
        }
        .success { 
            background-color: #D4EDDA; 
            padding: 15px; 
            margin: 10px 0; 
            border-left: 4px solid #28A745;
            border-radius: 4px;
        }
        .zone-title {
            font-size: 1.3em;
            font-weight: 600;
            color: #0078D4;
        }
        .zone-status {
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
        }
        .status-ok { background: #D4EDDA; color: #155724; }
        .status-warning { background: #FFF3CD; color: #856404; }
        .status-error { background: #F8D7DA; color: #721C24; }
        .toggle-icon {
            font-size: 1.2em;
            transition: transform 0.3s;
        }
        .zone.expanded .toggle-icon {
            transform: rotate(90deg);
        }
        .tenant-badge {
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 0.8em;
            font-weight: 600;
            margin: 0 5px;
        }
        .tenant-a { background: #E3F2FD; color: #1565C0; }
        .tenant-b { background: #F3E5F5; color: #7B1FA2; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔄 DNS Zone Comparison Report</h1>
            <p>Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
            <p><span class="tenant-badge tenant-a">$($TenantAName)</span> vs <span class="tenant-badge tenant-b">$($TenantBName)</span></p>
        </div>
"@

    $totalDiscrepancies = 0
    $zonesWithErrors = @()
    $zonesProcessed = 0
    $successfulComparisons = 0
    
    # Metrics summary
    foreach ($result in $Results) {
        $zonesProcessed++
        $discrepancyCount = $result.MissingInTenantA.Count + $result.MissingInTenantB.Count + $result.MismatchedRecords.Count
        $totalDiscrepancies += $discrepancyCount
        
        if (-not $result.HasErrors -and $result.ZoneExistsInTenantA -and $result.ZoneExistsInTenantB) {
            $successfulComparisons++
        }
        
        if ($result.HasErrors) {
            $zonesWithErrors += $result.ZoneName
        }
    }

    $html += @"
        <div style="margin: 20px 0; text-align: center;">
            <button onclick="expandAll()" style="margin: 5px; padding: 8px 15px; background: #0078D4; color: white; border: none; border-radius: 4px; cursor: pointer;">Expand All</button>
            <button onclick="collapseAll()" style="margin: 5px; padding: 8px 15px; background: #6c757d; color: white; border: none; border-radius: 4px; cursor: pointer;">Collapse All</button>
        </div>
"@

    # Detailed results with collapsible sections
    $zoneIndex = 0
    foreach ($result in $Results) {
        $discrepancyCount = $result.MissingInTenantA.Count + $result.MissingInTenantB.Count + $result.MismatchedRecords.Count
        
        $html += "<div class='zone' id='zone-$zoneIndex'>"
        $html += "<div class='zone-header' onclick='toggleZone($zoneIndex)'>"
        $html += "<div style='display: flex; align-items: center;'>"
        $html += "<span class='toggle-icon'>></span>"
        $html += "<div class='zone-title' style='margin-left: 10px;'>Zone: $($result.ZoneName)</div>"
        $html += "</div>"
        
        # Status badge
        if ($result.HasErrors) {
            $html += "<span class='zone-status status-error'>ERROR</span>"
        }
        elseif (-not $result.ZoneExistsInTenantA -or -not $result.ZoneExistsInTenantB) {
            $html += "<span class='zone-status status-warning'>MISSING ZONE</span>"
        }
        elseif ($discrepancyCount -eq 0) {
            $html += "<span class='zone-status status-ok'>OK</span>"
        }
        else {
            $html += "<span class='zone-status status-warning'>$discrepancyCount DISCREPANCIES</span>"
        }
        
        $html += "</div>" # zone-header
        
        $html += "<div class='zone-content'>"
        $html += @"
<table style="width: 100%; border-collapse: collapse; margin: 15px 0;">
    <tr>
        <td style="width: 50%; vertical-align: top; padding: 10px; border-right: 1px solid #e0e0e0;">
            <strong>Tenant Name:</strong> $TenantAName<br>
            <strong>Tenant RG:</strong> $($result.TenantAResourceGroup)<br>
            <strong>Tenant Subscription ID:</strong> $($TenantAConfig.SubscriptionId)
        </td>
        <td style="width: 50%; vertical-align: top; padding: 10px;">
            <strong>Tenant Name:</strong> $TenantBName<br>
            <strong>Tenant RG:</strong> $($result.TenantBResourceGroup)<br>
            <strong>Tenant Subscription ID:</strong> $($TenantBConfig.SubscriptionId)
        </td>
    </tr>
</table>
"@
        
        if ($result.HasErrors) {
            $html += "<div class='error'><strong>Error:</strong> $($result.ErrorMessage)</div>"
        }
        elseif (-not $result.ZoneExistsInTenantA -and -not $result.ZoneExistsInTenantB) {
            $html += "<div class='warning'>⚠️ Zone does not exist in either tenant</div>"
        }
        elseif (-not $result.ZoneExistsInTenantA) {
            $html += "<div class='error'>❌ Zone missing in $($TenantAName) (RG: $($result.TenantAResourceGroup))</div>"
        }
        elseif (-not $result.ZoneExistsInTenantB) {
            $html += "<div class='error'>❌ Zone missing in $($TenantBName) (RG: $($result.TenantBResourceGroup))</div>"
        }
        else {
            if ($discrepancyCount -eq 0) {
                $html += "<div class='success'>✅ No discrepancies found</div>"
            }
            else {
                $html += "<p><strong>Discrepancies found:</strong> $discrepancyCount</p>"
                
                if ($result.MissingInTenantA.Count -gt 0) {
                    $html += "<h4>📥 Missing in $($TenantAName):</h4>"
                    foreach ($disc in $result.MissingInTenantA) {
                        $html += "<div class='discrepancy'><strong>$($disc.RecordName)</strong> ($($disc.RecordType)) → $($disc.TenantBData) [TTL: $($disc.TenantBTTL)]</div>"
                    }
                }
                
                if ($result.MissingInTenantB.Count -gt 0) {
                    $html += "<h4>📤 Missing in $($TenantBName):</h4>"
                    foreach ($disc in $result.MissingInTenantB) {
                        $html += "<div class='discrepancy'><strong>$($disc.RecordName)</strong> ($($disc.RecordType)) → $($disc.TenantAData) [TTL: $($disc.TenantATTL)]</div>"
                    }
                }
                
                if ($result.MismatchedRecords.Count -gt 0) {
                    $html += "<h4>⚡ Mismatched Records:</h4>"
                    foreach ($disc in $result.MismatchedRecords) {
                        $html += "<div class='discrepancy'>"
                        $html += "<strong>$($disc.RecordName)</strong> ($($disc.RecordType))<br>"
                        $html += "👤 $($TenantAName): $($disc.TenantAData) [TTL: $($disc.TenantATTL)]<br>"
                        $html += "👥 $($TenantBName): $($disc.TenantBData) [TTL: $($disc.TenantBTTL)]"
                        $html += "</div>"
                    }
                }
            }
        }
        
        $html += "</div>" # zone-content
        $html += "</div>" # zone
        
        $zoneIndex++
    }
    
    $html += @"
        <div class="summary">
            <h3>📊 Executive Summary</h3>
            <p><strong>Total Zones Processed:</strong> $zonesProcessed</p>
            <p><strong>Successful Comparisons:</strong> $successfulComparisons</p>
            <p><strong>Total Discrepancies:</strong> $totalDiscrepancies</p>
            <p><strong>Zones with Errors:</strong> $($zonesWithErrors.Count)</p>
            
            <div style="margin-top: 15px;">
                <strong>Zones with errors:</strong> 
                $($zonesWithErrors.Count -eq 0 ? 'None' : ($zonesWithErrors -join ', '))
            </div>
        </div>

        <script>
            function toggleZone(index) {
                const zone = document.getElementById('zone-' + index);
                zone.classList.toggle('expanded');
            }
            
            function expandAll() {
                const zones = document.querySelectorAll('.zone');
                zones.forEach(zone => zone.classList.add('expanded'));
            }
            
            function collapseAll() {
                const zones = document.querySelectorAll('.zone');
                zones.forEach(zone => zone.classList.remove('expanded'));
            }
            
            // Auto-expand zones with errors or discrepancies
            document.addEventListener('DOMContentLoaded', function() {
                const zones = document.querySelectorAll('.zone');
                zones.forEach(zone => {
                    if (zone.querySelector('.status-error') || zone.querySelector('.status-warning')) {
                        zone.classList.add('expanded');
                    }
                });
            });
        </script>
    </div>
</body>
</html>
"@

    try {
        $html | Out-File -FilePath $fullPath -Encoding UTF8
        Write-Host "✅ HTML report saved: $fullPath" -ForegroundColor Green
        return $fullPath
    }
    catch {
        Write-Error "Failed to save HTML report: $($_.Exception.Message)"
        return $null
    }
}

function Export-CsvReport {
    param(
        [array]$Results,
        [string]$FilePath,
        [string]$TenantAName,
        [string]$TenantBName
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $fullPath = Join-Path $FilePath "DNS_Comparison_Report_$timestamp.csv"
    
    $csvData = @()
    
    foreach ($result in $Results) {
        $discrepancyCount = $result.MissingInTenantA.Count + $result.MissingInTenantB.Count + $result.MismatchedRecords.Count
        
        # Zone summary
        $csvData += [PSCustomObject]@{
            ZoneName              = $result.ZoneName
            "$($TenantAName)RG"   = $result.TenantAResourceGroup
            "$($TenantBName)RG"   = $result.TenantBResourceGroup
            RecordType            = "ZONE_SUMMARY"
            RecordName            = ""
            DiscrepancyType       = "SUMMARY"
            "$($TenantAName)Data" = ""
            "$($TenantBName)Data" = ""
            "$($TenantAName)TTL"  = ""
            "$($TenantBName)TTL"  = ""
            DiscrepancyCount      = $discrepancyCount
            HasErrors             = $result.HasErrors
            ErrorMessage          = $result.ErrorMessage
        }
        
        # Individual discrepancies
        foreach ($disc in $result.MissingInTenantA) {
            $csvData += [PSCustomObject]@{
                ZoneName              = $result.ZoneName
                "$($TenantAName)RG"   = $result.TenantAResourceGroup
                "$($TenantBName)RG"   = $result.TenantBResourceGroup
                RecordType            = $disc.RecordType
                RecordName            = $disc.RecordName
                DiscrepancyType       = "MISSING_IN_$($TenantAName.ToUpper().Replace(' ', '_'))"
                "$($TenantAName)Data" = ""
                "$($TenantBName)Data" = $disc.TenantBData
                "$($TenantAName)TTL"  = ""
                "$($TenantBName)TTL"  = $disc.TenantBTTL
                DiscrepancyCount      = ""
                HasErrors             = ""
                ErrorMessage          = ""
            }
        }
        
        foreach ($disc in $result.MissingInTenantB) {
            $csvData += [PSCustomObject]@{
                ZoneName              = $result.ZoneName
                "$($TenantAName)RG"   = $result.TenantAResourceGroup
                "$($TenantBName)RG"   = $result.TenantBResourceGroup
                RecordType            = $disc.RecordType
                RecordName            = $disc.RecordName
                DiscrepancyType       = "MISSING_IN_$($TenantBName.ToUpper().Replace(' ', '_'))"
                "$($TenantAName)Data" = $disc.TenantAData
                "$($TenantBName)Data" = ""
                "$($TenantAName)TTL"  = $disc.TenantATTL
                "$($TenantBName)TTL"  = ""
                DiscrepancyCount      = ""
                HasErrors             = ""
                ErrorMessage          = ""
            }
        }
        
        foreach ($disc in $result.MismatchedRecords) {
            $csvData += [PSCustomObject]@{
                ZoneName              = $result.ZoneName
                "$($TenantAName)RG"   = $result.TenantAResourceGroup
                "$($TenantBName)RG"   = $result.TenantBResourceGroup
                RecordType            = $disc.RecordType
                RecordName            = $disc.RecordName
                DiscrepancyType       = "MISMATCHED_RECORD"
                "$($TenantAName)Data" = $disc.TenantAData
                "$($TenantBName)Data" = $disc.TenantBData
                "$($TenantAName)TTL"  = $disc.TenantATTL
                "$($TenantBName)TTL"  = $disc.TenantBTTL
                DiscrepancyCount      = ""
                HasErrors             = ""
                ErrorMessage          = ""
            }
        }
    }
    
    try {
        $csvData | Export-Csv -Path $fullPath -NoTypeInformation
        Write-Host "✅ CSV report saved: $fullPath" -ForegroundColor Green
        return $fullPath
    }
    catch {
        Write-Error "Failed to save CSV report: $($_.Exception.Message)"
        return $null
    }
}

function Export-JsonReport {
    param(
        [array]$Results,
        [string]$FilePath,
        [string]$TenantAName,
        [string]$TenantBName
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $fullPath = Join-Path $FilePath "DNS_Comparison_Report_$timestamp.json"
    
    try {
        $report = @{
            Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Summary   = @{
                TotalZones         = $Results.Count
                TotalDiscrepancies = ($Results | Measure-Object -Property TotalDiscrepancies -Sum).Sum
                ZonesWithErrors    = ($Results | Where-Object HasErrors).Count
            }
            TenantA   = @{
                Name = $TenantAName
                SubscriptionId = $TenantAConfig.SubscriptionId
            }
            TenantB   = @{
                Name = $TenantBName
                SubscriptionId = $TenantBConfig.SubscriptionId
            }
            Results   = $Results
        }
        
        $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $fullPath -Encoding UTF8
        Write-Host "✅ JSON report saved: $fullPath" -ForegroundColor Green
        return $fullPath
    }
    catch {
        Write-Error "Failed to save JSON report: $($_.Exception.Message)"
        return $null
    }
}

# Main execution
try {
    Write-Host "Starting DNS zone comparison..." -ForegroundColor Green
    Write-Host "Comparing: $TenantAName vs $TenantBName" -ForegroundColor Cyan
    
    # Apply filters
    if ($IncludeOnlyZones.Count -gt 0) {
        $ZoneMappings = $ZoneMappings | Where-Object { $_.ZoneName -in $IncludeOnlyZones }
    }
    if ($ExcludeZones.Count -gt 0) {
        $ZoneMappings = $ZoneMappings | Where-Object { $_.ZoneName -notin $ExcludeZones }
    }
    
    Write-Host "Zones to compare: $($ZoneMappings.ZoneName -join ', ')" -ForegroundColor Cyan
    Write-Host "Output formats: $($OutputFormats -join ', ')" -ForegroundColor Cyan
    
    $allResults = @()
    
    # Process zones
    foreach ($zoneMapping in $ZoneMappings) {
        $zoneName = $zoneMapping.ZoneName
        $tenantARG = $zoneMapping.TenantAResourceGroup
        $tenantBRG = $zoneMapping.TenantBResourceGroup
        
        Write-Host "`nProcessing zone: $zoneName" -ForegroundColor Yellow
        Write-Host "  $TenantAName RG: $tenantARG" -ForegroundColor Gray
        Write-Host "  $TenantBName RG: $tenantBRG" -ForegroundColor Gray
        
        $result = [DnsComparisonResult]::new()
        $result.ZoneName = $zoneName
        $result.TenantAResourceGroup = $tenantARG
        $result.TenantBResourceGroup = $tenantBRG
        
        try {
            # Get records from Tenant A
            $tenantAResult = Get-DnsZoneRecords -ZoneName $zoneName -ResourceGroupName $tenantARG -TenantConfig $TenantAConfig -TenantName $TenantAName
            
            if (-not $tenantAResult.Success) {
                throw "Failed to get records from $TenantAName -> $($tenantAResult.Error)"
            }
            
            # Get records from Tenant B  
            $tenantBResult = Get-DnsZoneRecords -ZoneName $zoneName -ResourceGroupName $tenantBRG -TenantConfig $TenantBConfig -TenantName $TenantBName
            
            if (-not $tenantBResult.Success) {
                throw "Failed to get records from $TenantBName -> $($tenantBResult.Error)"
            }
            
            # Compare records
            $comparisonResult = Compare-DnsRecords -TenantARecords $tenantAResult.Records -TenantBRecords $tenantBResult.Records -ZoneName $zoneName -TenantAResourceGroup $tenantARG -TenantBResourceGroup $tenantBRG -ZoneExistsInTenantA $tenantAResult.ZoneExists -ZoneExistsInTenantB $tenantBResult.ZoneExists
            $allResults += $comparisonResult
            
            Write-Host "  ✓ Comparison completed - $($comparisonResult.TotalDiscrepancies) discrepancies found" -ForegroundColor Green
            
        }
        catch {
            $result.HasErrors = $true
            $result.ErrorMessage = $_.Exception.Message
            $allResults += $result
            Write-Warning "Error processing zone $zoneName : $($_.Exception.Message)"
        }
    }
    
    # Generate outputs based on selected formats
    $generatedFiles = @()
    
    if ($OutputFormats -contains "HTML" -or $GenerateHtmlFile -or $SendEmail) {
        $htmlFile = New-HtmlReport -Results $allResults -FilePath $OutputPath -TenantAName $TenantAName -TenantBName $TenantBName -TenantAConfig $TenantAConfig -TenantBConfig $TenantBConfig
        if ($htmlFile) { $generatedFiles += $htmlFile }
    }
    
    if ($OutputFormats -contains "CSV") {
        $csvFile = Export-CsvReport -Results $allResults -FilePath $OutputPath -TenantAName $TenantAName -TenantBName $TenantBName
        if ($csvFile) { $generatedFiles += $csvFile }
    }
    
    if ($OutputFormats -contains "JSON") {
        $jsonFile = Export-JsonReport -Results $allResults -FilePath $OutputPath -TenantAName $TenantAName -TenantBName $TenantBName
        if ($jsonFile) { $generatedFiles += $jsonFile }
    }
    
    # NEW: Always export complete DNS records (regardless of output format selection)
    $completeRecordsFile = Export-AllDnsRecords -ZoneMappings $ZoneMappings -TenantAConfig $TenantAConfig -TenantBConfig $TenantBConfig -FilePath $OutputPath -TenantAName $TenantAName -TenantBName $TenantBName
    if ($completeRecordsFile) { 
        $generatedFiles += $completeRecordsFile
        
        # NEW: Show summary statistics after exporting complete records
        try {
            $completeRecords = Import-Csv $completeRecordsFile
            Show-RecordSummary -AllRecords $completeRecords -TenantAName $TenantAName -TenantBName $TenantBName
        }
        catch {
            Write-Warning "Could not generate summary statistics: $($_.Exception.Message)"
        }
        
        Write-Host "📊 Complete DNS records export generated automatically" -ForegroundColor Cyan
    }
    
    if ($OutputFormats -contains "Console") {
        # Console output
        Write-Host "`n" + "="*60 -ForegroundColor Cyan
        Write-Host "COMPARISON SUMMARY" -ForegroundColor Cyan
        Write-Host "="*60 -ForegroundColor Cyan
        
        $allResults | ForEach-Object {
            $status = if ($_.HasErrors) { "ERROR" } elseif ($_.TotalDiscrepancies -eq 0) { "OK" } else { "DISCREPANCIES" }
            $color = if ($_.HasErrors) { "Red" } elseif ($_.TotalDiscrepancies -eq 0) { "Green" } else { "Yellow" }
            
            Write-Host ("{0} | $($TenantAName) RG: {1} | $($TenantBName) RG: {2} | Status: {3}" -f 
                $_.ZoneName.PadRight(35),
                $_.TenantAResourceGroup.PadRight(20),
                $_.TenantBResourceGroup.PadRight(20),
                $status) -ForegroundColor $color
        }
    }
    
    # Summary of generated files
    if ($generatedFiles.Count -gt 0) {
        Write-Host "`n" + "="*60 -ForegroundColor Green
        Write-Host "GENERATED FILES" -ForegroundColor Green
        Write-Host "="*60 -ForegroundColor Green
        $generatedFiles | ForEach-Object { Write-Host "📄 $_" -ForegroundColor White }
    }
    
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
