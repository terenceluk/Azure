<# 
The purpose of this script is to export the list of Azure VMs to display the fields:

- Name
- Resource Group
- Location
- VMSize
- OsType
- Status

.. and send a HTML report with the list.

Refer to my blog post for more information: http://terenceluk.blogspot.com/2022/11/configuring-azure-function-app-that.html
#>

using namespace System.Net

param($Request, $TriggerMetadata)

Function Get-AzureVMList
{

    $VMList = Get-AzVM
    $VMListArray = New-Object System.Collections.ArrayList
    $singleVMDetails = [ordered]@{} 
    
    # Loop through list of VMs from Get-AzVM
    foreach($VMResource in $VMList) 
    {
        $singleVMDetails.'Name' = $VMResource.Name
        $singleVMDetails.'Resource Group' = $VMResource.ResourceGroupName
        $singleVMDetails.'Location' = $VMResource.Location
        $singleVMDetails.'VmSize' = $VMResource.HardwareProfile.VmSize
        $singleVMDetails.'OsType' = $VMResource.StorageProfile.OsDisk.OsType
        
        # Get VM Status
        $VMStatus = Get-AzVM -ResourceGroupName $VMResource.ResourceGroupName -Name $VMResource.Name -Status
        $singleVMDetails.'Status' = $VMStatus.Statuses[1].DisplayStatus
    
        # Write VM Details to Array
        $VMListArray.Add((New-object PSObject -Property $singleVMDetails)) | Out-Null
    }
    
    # Test Export to CSV
    # $VMListArray | Export-Csv "VMDetails.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ',' 
    

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
<title>Azure Virtual Machine Status</title>
<h1>Azure Virtual Machine Status Report</h1>
<h2>Client: Contoso Limited</h2>
"@

# Create the table and convert to HTML format
$htmlFormat = $VMListArray | ConvertTo-Html # -Head $Header | Out-File -FilePath VMDetails.html <-- used for troubleshooting

# Combine Header, Body and HTML elements for output
$Header + $Body + $htmlFormat

}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Use the function defined above to retrieve the device list in HTML format (includes header and body)
$HTML = Get-AzureVMList

# Set the HTTP status code
$status = [HttpStatusCode]::OK

# Write the output data in HTML format
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    headers = @{'content-type' = 'text/html'}
    StatusCode = $status
    Body = $HTML
})