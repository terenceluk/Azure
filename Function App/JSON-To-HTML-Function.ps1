using namespace System.Net

<# Input bindings are passed in via param block - we'll be passing the following JSON code into the HTTP Body:
{
  "body": "https://rgcacinfratemp.blob.core.windows.net/integration/AD-Report-06-29-2023.json" <-- The Json file name will be dynamic
}

#>
param($Request, $TriggerMetadata)

Function Convert-JsonToHtml
{
    param (
      [Parameter(Mandatory = $true)]
      $inputJson
  )

# th <-- header
# td <-- records

# tr:nth-child(even) { background: #dae5f4; }
# Light blue

# tr:nth-child(odd) { background: #b8d1f3; }
# Dark Blue

# The following header creates a table with alternating colours of blue for the rows but the child even and odd, unfortunately, is not supported in Outlook or GMail so the rows will all be the same blue
$header = @"
<style>
h1, h5, th { text-align: center; font-family: Calibri; }
table { margin: auto; font-family: Calibri; box-shadow: 10px 10px 5px #888; border: thin solid black ; }
th { font-size: 16px; background: #4472C4; color: #FFFFFF; max-width: 400px; padding: 5px 10px; }
td { font-size: 13px; padding: 1px 10px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
"@

# Convert JSON to HTML with defined header
$Body = $inputJson | ConvertTo-Html 

# Combine Header and Body HTML elements for output
$Header + $Body 

}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Get passed path to JSON file stored on Storage Account Container
$blobPathToJSON = $Request.Body.path

# Extract Json file name from path
$blobName = $blobPathToJSON.Substring($blobPathToJSON.LastIndexOf("/") + 1)

# Extract Storage Account Name from path
$blobStorageName = $blobPathToJSON.Substring($blobPathToJSON.IndexOf("//") + 2, $blobPathToJSON.IndexOf(".blob") - 8)

# Extract container name from path with RegEx matching
$regexPattern = '(?<=blob.core.windows.net\/)([\s\S]*)(?=\/)'
$blobContainerName = [regex]::Match($blobPathToJSON, $regexPattern)

# Set container name in storage account that contains the JSON
$container = $blobContainerName.value

# Create Storage Context
$blobContext = New-AzStorageContext -StorageAccountName $blobStorageName

# Retrieve JSON blob
$jsonBlob = Get-AzStorageBlob -Blob $blobName -Container $container -Context $blobContext

# Retrieve JSON blob contents and convert JSON file
$jsonBlobContent = $jsonBlob.ICloudBlob.DownloadText() | ConvertFrom-Json

# Convert the retrived Json file to HTML
$HTML = Convert-JsonToHtml -inputJson $jsonBlobContent

# Set the HTTP status code
$status = [HttpStatusCode]::OK

# Write the output data in HTML format
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    headers = @{'content-type' = 'text/html'}
    StatusCode = $status
    Body = $HTML
})
