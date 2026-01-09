<# 
The purpose of this script is to download a device report from Cylance and send a HTML report with the device count and list of devices to an emaila address
The CSV report will also be attached to the email

Refer to my blog post for more information: 
#>

using namespace System.Net

<# Input bindings are passed in via param block - retrieving the report requires a unique Cylance token so we'll be passing it in the following JSON code via the HTTP Body:
{
  "token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
#>
param($Request, $TriggerMetadata)

Function Get-CylanceDevices {
    # Import product friendly name from a csv from Cylance and store in array
    $cylanceDevices = @()
    $reportURLPath = "https://protect-sae1.cylance.com/Reports/ThreatDataReportV1/devices/" # this URL is retrieved from the Cylance console in the Applications menu
    $reportURLPathWithToken = $reportURLPath + $cylanceTenantToken
    
    Write-Host "Requesting report from: $reportURLPathWithToken"
    
    # Use HttpWebRequest to handle the 302 redirect properly
    $request = [System.Net.HttpWebRequest]::Create($reportURLPathWithToken)
    $request.AllowAutoRedirect = $false
    $request.UserAgent = "AzureFunction/1.0"
    
    $redirectUrl = $null
    
    try {
        $response = $request.GetResponse()
        Write-Host "Got response with status: $($response.StatusCode)"
        
        if ($response.StatusCode -eq [System.Net.HttpStatusCode]::Found) {
            $redirectUrl = $response.Headers["Location"]
            Write-Host "Found redirect URL: $redirectUrl"
        }
        $response.Close()
    }
    catch [System.Net.WebException] {
        # Fallback in case server throws exception for 302
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Found) {
            $redirectUrl = $_.Exception.Response.Headers["Location"]
            Write-Host "Found redirect URL (from exception): $redirectUrl"
        }
    }
    
    if (-not $redirectUrl) {
        throw "Failed to get redirect URL from Cylance API"
    }
    
    # Ensure URL is absolute
    if (-not [System.Uri]::IsWellFormedUriString($redirectUrl, [System.UriKind]::Absolute)) {
        $baseUri = New-Object System.Uri($reportURLPathWithToken)
        $redirectUrl = New-Object System.Uri($baseUri, $redirectUrl).AbsoluteUri
        Write-Host "Converted to absolute URL: $redirectUrl"
    }
    
    # Download CSV from S3 URL
    Write-Host "Downloading CSV from S3..."
    $csvContent = Invoke-RestMethod -Uri $redirectUrl -ErrorAction Stop
    $cylanceDevices = $csvContent | ConvertFrom-Csv -Delimiter ','
    
    Write-Host "Successfully retrieved $($cylanceDevices.Count) devices"

    # Get a count of how many Cylance devices are there
    $amountOfCylanceDevices = $cylanceDevices.count

    # Get duplicate entries
    $cylanceDuplicates = $cylanceDevices | Group-Object 'Device Name' | Where { $_.Count -gt 1 }
    $cylanceDuplicatesCount = $cylanceDuplicates.count

    # Create the HTML header
    $Header = @"
<style>
BODY {font-family:Calibri;}
table {border-collapse: collapse; font-family: Calibri, sans-serif;}
table td {padding: 5px;}
table th {background-color: #4472C4; color: #ffffff; font-weight: bold;	border: 1px solid #54585d; padding: 5px;}
table tbody td {color: #636363;	border: 1px solid #dddfe1;}
table tbody tr {background-color: #f9fafb;}
table tbody tr:nth-child(odd) {background-color: #ffffff;}
</style>
"@

    # Create the HTML Body
    $Body = @"
<title>Cylance Devices Usage Report</title>
<h1>Cylance Usage Report</h1>
<h2>Client: Contoso Limited</h2>
<h3>The current Cylance device count for this tenant is: $amountOfCylanceDevices <h3>
"@

    if ($cylanceDuplicatesCount -gt 0) {
        $cylanceDuplicatesName = $cylanceDuplicates.Name -join ', '
        $addBody = @"
  
  <h3>There are currently $cylanceDuplicatesCount devices with the same name<h3>
  <h3>The devices are: $cylanceDuplicatesName<h3>
"@
        $Body = $Body + $addBody
    }

    # Create the table and convert to HTML format
    $htmlFormat = $cylanceDevices | ConvertTo-Html # | Out-File -FilePath CylanceReport.html <-- used for troubleshooting

    # Combine Header, Body and HTML elements for output
    $Header + $Body + $htmlFormat
}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request - we're retrieving the Cylance Token passed in the body that will be used to retrieve the device report CSV
$cylanceTenantToken = $Request.Query.token
if (-not $cylanceTenantToken) {
    $cylanceTenantToken = $Request.Body.token
}

# Check if token was provided
if (-not $cylanceTenantToken) {
    $status = [HttpStatusCode]::BadRequest
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            headers    = @{'content-type' = 'text/plain' }
            StatusCode = $status
            Body       = "Missing token parameter. Please provide a Cylance token."
        })
    return
}

Write-Host "Token received (first 10 chars): $($cylanceTenantToken.Substring(0, [Math]::Min(10, $cylanceTenantToken.Length)))..."

try {
    # Use the function defined above to retrieve the device list in HTML format (includes header and body)
    $HTML = Get-CylanceDevices

    # Set the HTTP status code
    $status = [HttpStatusCode]::OK

    # Write the output data in HTML format
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            headers    = @{'content-type' = 'text/html' }
            StatusCode = $status
            Body       = $HTML
        })
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "StackTrace: $($_.Exception.StackTrace)"
    
    $status = [HttpStatusCode]::InternalServerError
    $errorHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Cylance Devices Usage Report - Error</title>
    <style>
        body { font-family: Calibri, sans-serif; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Cylance Usage Report - Error</h1>
    <h2>Client: Contoso Limited</h2>
    <h3 class="error">Error: $($_.Exception.Message)</h3>
    <p>Please check the Azure Function logs for more details.</p>
</body>
</html>
"@
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            headers    = @{'content-type' = 'text/html' }
            StatusCode = $status
            Body       = $errorHtml
        })
}
