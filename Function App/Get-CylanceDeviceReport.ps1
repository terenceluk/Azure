<# 
The purpose of this script is to download a device report from Cylance and send a HTML report with the device count and list of devices to an emaila address
The CSV report will also be attached to the email

Refer to my blog post for more information: http://terenceluk.blogspot.com/2022/08/using-azure-function-app-and-logic-apps.html
#>

using namespace System.Net

<# Input bindings are passed in via param block - retrieving the report requires a unique Cylance token so we'll be passing it in the following JSON code via the HTTP Body:
{
  "token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
#>
param($Request, $TriggerMetadata)

Function Get-CylanceDevices
{

# Import product friendly name from a csv from Cylance and store in array
$cylanceDevices = @()
$reportURLPath= "https://protect-sae1.cylance.com/Reports/ThreatDataReportV1/devices/" # this URL is retrieved from the Cylance console in the Applications menu
$reportURLPathWithToken = $reportURLPath + $cylanceTenantToken
$cylanceDevices = (Invoke-WebRequest $reportURLPathWithToken).content | ConvertFrom-Csv -Delimiter ',' 

# Get a count of how many Cylance devices are there
$amountOfCylanceDevices = $cylanceDevices.count

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
<h3>The current Cylance device count for this tenant is: $amountofCylanceDevices <h3>
"@

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

# Use the function defined above to retrieve the device list in HTML format (includes header and body)
$HTML = Get-CylanceDevices

# Set the HTTP status code
$status = [HttpStatusCode]::OK

# Write the output data in HTML format
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    headers = @{'content-type' = 'text/html'}
    StatusCode = $status
    Body = $HTML
})