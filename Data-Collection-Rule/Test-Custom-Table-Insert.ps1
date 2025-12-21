# ===== COMPLETELY CLEAN SCRIPT =====
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DCR DATA INGESTION - CLEAN TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# ===== 1. SET CORRECT CONTEXT =====
Write-Host "[1/5] Setting Context..." -ForegroundColor Yellow
Set-AzContext -SubscriptionId "12345678-1234-1234-1234-123456789abc" | Out-Null # Update with Subscripotion containing DCE
$ctx = Get-AzContext
Write-Host "✓ Subscription: $($ctx.Subscription.Name)" -ForegroundColor Green
Write-Host ""

# ===== 2. GET ACCESS TOKEN =====
Write-Host "[2/5] Getting Token..." -ForegroundColor Yellow
try {
    $token = (Get-AzAccessToken -ResourceUrl "https://monitor.azure.com").Token
    
    # Handle SecureString
    if ($token -is [System.Security.SecureString]) {
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
        $accessToken = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    } else {
        $accessToken = $token.ToString()
    }
    
    Write-Host "✓ Token: $($accessToken.Substring(0, [Math]::Min(20, $accessToken.Length)))..." -ForegroundColor Green
} catch {
    Write-Host "❌ Token error: $_" -ForegroundColor Red
    exit
}
Write-Host ""

# ===== 3. VERIFY URI COMPONENTS =====
Write-Host "[3/5] Building URI..." -ForegroundColor Yellow

# Hardcode EVERYTHING - no variables for stream name
$DCE_HOST = "dce-subnet-mapping-xxx.canadacentral-1.ingest.monitor.azure.com" # Update to DCR "Logs Ingestion" without https://
$DCR_ID = "dcr-4234234e8dads82342492e397d4f542342384" # Update to DCR "Immutable ID"

# Test different stream name formats
$streamTest1 = "Custom-SubnetMap_CL"
$streamTest2 = [string]"Custom-SubnetMap_CL"
$streamTest3 = "Custom-SubnetMap_CL".Trim()

Write-Host "Testing stream names:" -ForegroundColor Gray
Write-Host "  Test 1: '$streamTest1' (length: $($streamTest1.Length))" -ForegroundColor Gray
Write-Host "  Test 2: '$streamTest2' (length: $($streamTest2.Length))" -ForegroundColor Gray
Write-Host "  Test 3: '$streamTest3' (length: $($streamTest3.Length))" -ForegroundColor Gray

# Use the simplest one
$streamName = $streamTest3

# Build URI step by step to debug
$uriBase = "https://$DCE_HOST/dataCollectionRules/$DCR_ID/streams/"
$uriFull = $uriBase + $streamName + "?api-version=2023-01-01"

Write-Host ""
Write-Host "✓ URI Components:" -ForegroundColor Green
Write-Host "  Base: $uriBase" -ForegroundColor Gray
Write-Host "  Stream: $streamName" -ForegroundColor Gray
Write-Host "  Full: $uriFull" -ForegroundColor Gray

# Display raw characters
Write-Host ""
Write-Host "Debug - Stream name characters:" -ForegroundColor Cyan
$streamName.ToCharArray() | ForEach-Object {
    $charCode = [int]$_
    Write-Host "  '$($_)' = ASCII $charCode" -ForegroundColor Gray
}
Write-Host ""

# ===== 4. PREPARE BODY =====
Write-Host "[4/5] Preparing Body..." -ForegroundColor Yellow
$body = @"
[
  {
    "TimeGenerated": "$([DateTime]::UtcNow.ToString("o"))",
    "aztenantId": "12345678-1234-1234-1234-123456789abc",
    "subscriptionId": "ABCDEFGH-1234-1234-1234-123456789abc",
    "resourceGroup": "dev-valora-network-rg",
    "vnetName": "dev-valora-vm-vnet",
    "vnetAddressPrefixes": ["10.0.0.0/16", "192.168.0.0"],
    "region": "canadacentral",
    "subnetName": "dev-valora-jumpbox-snet",
    "subnetAddressPrefixes": ["10.224.20.16/28"]
  },
  {
    "TimeGenerated": "$([DateTime]::UtcNow.ToString("o"))",
    "aztenantId": "12345678-1234-1234-1234-123456789abc",
    "subscriptionId": "ABCDEFGH-1234-1234-1234-123456789abc",
    "resourceGroup": "dev-test-network-rg",
    "vnetName": "dev-test-vm-vnet",
    "vnetAddressPrefixes": ["10.0.0.0/16", "192.168.0.0/24"],
    "region": "canadacentral",
    "subnetName": "dev-test-jumpbox-snet",
    "subnetAddressPrefixes": ["10.224.20.16/28"]
  }
]
"@

Write-Host "✓ Body prepared" -ForegroundColor Green
Write-Host "  First 100 chars: $($body.Substring(0, [Math]::Min(100, $body.Length)))..." -ForegroundColor Gray
Write-Host ""

# ===== 5. SEND REQUEST =====
Write-Host "[5/5] Sending Request..." -ForegroundColor Yellow

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

try {
    Write-Host "Sending to: $uriFull" -ForegroundColor Gray
    
    # Option 1: Try with Invoke-RestMethod
    $response = Invoke-RestMethod -Uri $uriFull -Method Post -Body $body -Headers $headers
    
    Write-Host "✅ SUCCESS! Data sent." -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ REQUEST FAILED: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status: $statusCode" -ForegroundColor Red
        
        # Try to get more details
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorDetails = $reader.ReadToEnd()
            $reader.Close()
            
            Write-Host "Error Details:" -ForegroundColor Yellow
            Write-Host $errorDetails -ForegroundColor Gray
            
            if ($errorDetails -like "*stream*" -or $errorDetails -like "*StreamDeclaration*") {
                Write-Host ""
                Write-Host "🔍 STREAM NAME ISSUE DETECTED" -ForegroundColor Cyan
                Write-Host "The DCR might not have this exact stream name." -ForegroundColor Gray
                Write-Host "Check your DCR JSON for exact stream name spelling." -ForegroundColor Gray
            }
            
        } catch {
            Write-Host "(No detailed error)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "🔧 TROUBLESHOOTING:" -ForegroundColor Cyan
    Write-Host "1. Test the URI manually in browser (will fail but shows format)" -ForegroundColor Gray
    Write-Host "2. Check DCR in portal: Data Collection Rules -> dcr-subnet-mapping -> Streams" -ForegroundColor Gray
    Write-Host "3. Try alternate stream name: maybe 'CustomSubnetMap_CL' or 'Custom_SubnetMap_CL'" -ForegroundColor Gray
    
    # Try alternative stream names
    Write-Host ""
    Write-Host "🔍 Testing alternative stream names..." -ForegroundColor Yellow
    
    $altStreams = @(
        "CustomSubnetMap_CL",
        "Custom_SubnetMap_CL", 
        "subnetmap",
        "CustomLog"
    )
    
    foreach ($alt in $altStreams) {
        $testUri = $uriBase + $alt + "?api-version=2023-01-01"
        Write-Host "  Trying: $alt" -ForegroundColor Gray
        Write-Host "    URI: $testUri" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
