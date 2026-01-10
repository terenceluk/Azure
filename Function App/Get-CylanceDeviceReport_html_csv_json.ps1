using namespace System.Net

<# Input bindings are passed in via param block - retrieving the report requires a unique Cylance token so we'll be passing it in the following JSON code via the HTTP Body:
{
  "token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "format": "html"  
}

{
  "token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "format": "csv"  
}

{
  "token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "format": "json"  
}

You can now also specify the format via query parameter or body:
?format=html or ?format=csv or ?format=json
#>
param($Request, $TriggerMetadata)

Function Get-CylanceDevices {
    [CmdletBinding()]
    param(
        [string]$Format = 'html'
    )
    
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

    # Return data based on requested format
    switch ($Format.ToLower()) {
        'csv' {
            # Convert to CSV and ensure it's a single string
            $csvData = $cylanceDevices | ConvertTo-Csv -NoTypeInformation | Out-String
        
            return @{
                Data        = $csvData
                ContentType = 'text/csv'
                FileName    = "CylanceDevices_$(Get-Date -Format 'yyyyMMdd').csv"
            }
        }
        'json' {
            $jsonData = @{
                Client      = "Contoso Limited"
                DeviceCount = $amountOfCylanceDevices
                Devices     = $cylanceDevices
                Duplicates  = @{
                    Count       = $cylanceDuplicatesCount
                    DeviceNames = $cylanceDuplicates.Name
                }
                Generated   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            return @{
                Data        = $jsonData | ConvertTo-Json -Depth 10
                ContentType = 'application/json'
            }
        }
        default {
            # 'html' format
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
            $htmlFormat = $cylanceDevices | ConvertTo-Html

            return @{
                Data        = $Header + $Body + $htmlFormat
                ContentType = 'text/html'
            }
        }
    }
}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request
$cylanceTenantToken = $Request.Query.token
if (-not $cylanceTenantToken) {
    $cylanceTenantToken = $Request.Body.token
}

# Get the format parameter (default to html if not specified)
$format = $Request.Query.format
if (-not $format) {
    $format = $Request.Body.format
}
if (-not $format) {
    $format = 'html'  # Default format
}

# Validate format
$validFormats = @('html', 'csv', 'json')
if ($format -notin $validFormats) {
    $status = [HttpStatusCode]::BadRequest
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            headers    = @{'content-type' = 'text/plain' }
            StatusCode = $status
            Body       = "Invalid format parameter. Valid values are: html, csv, json"
        })
    return
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
Write-Host "Format requested: $format"

try {
    # Use the function defined above to retrieve the device list in the requested format
    $result = Get-CylanceDevices -Format $format

    # Set the HTTP status code
    $status = [HttpStatusCode]::OK

    # Prepare response based on format
    $headers = @{'content-type' = $result.ContentType }
    
    # Add Content-Disposition header for CSV downloads
    if ($format -eq 'csv' -and $result.FileName) {
        $headers['Content-Disposition'] = "attachment; filename=$($result.FileName)"
    }

    # Write the output data in the requested format
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            headers    = $headers
            StatusCode = $status
            Body       = $result.Data
        })
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "StackTrace: $($_.Exception.StackTrace)"
    
    # Format error response based on requested format
    $status = [HttpStatusCode]::InternalServerError
    
    switch ($format.ToLower()) {
        'csv' {
            $errorMessage = "Error,$($_.Exception.Message)"
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                    headers    = @{'content-type' = 'text/csv' }
                    StatusCode = $status
                    Body       = $errorMessage
                })
        }
        'json' {
            $errorJson = @{
                error     = $_.Exception.Message
                timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                client    = "Contoso"
                status    = "error"
            } | ConvertTo-Json
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                    headers    = @{'content-type' = 'application/json' }
                    StatusCode = $status
                    Body       = $errorJson
                })
        }
        default {
            # 'html' format
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
    }
}
