# Function App

PowerShell and Python scripts designed to run as Azure Functions, covering VM management, device reporting, blob metadata, and API integrations.

## Contents

| File | Description |
|------|-------------|
| `Get-AzureVMs.ps1` | Azure Function that retrieves a list of Azure VMs and returns their details (name, status, size, location) as an HTTP response. |
| `Get-CylanceDeviceReport.ps1` | Azure Function that queries the Cylance API and generates a device status report. |
| `Get-CylanceDeviceReport_v2.ps1` | Updated version of the Cylance device report function with additional fields or improved error handling. |
| `Get-CylanceDeviceReport_html_csv_json.ps1` | Extended Cylance report function that returns output in HTML, CSV, and JSON formats depending on the request parameters. |
| `JSON-To-HTML-Function.ps1` | Azure Function that accepts a JSON body and transforms it into a formatted HTML page, useful for rendering structured data in email or web output. |
| `Set-Blob-Metadata-Function.py` | Python Azure Function that sets standard metadata fields (`containername`, `toplevelfolder`, `folderpath`, `filename`) on an Azure Blob. |
| `Set-Blob-Metadata-Function_v2.py` | Version 2 that extends blob metadata support to include arbitrary custom tags read from a `blob_details.json` configuration file. |
| `Start-Stop-VM-Function-Based-On-Tags.ps1` | Azure Function that starts or stops Azure VMs based on schedule tags (e.g., `StartTime`, `StopTime`) to optimize costs. |
| `Test-Calling-API.ps1` | Simple Azure Function for testing outbound HTTP API calls from within the Function App runtime. |

## Prerequisites

- Azure Functions runtime (PowerShell or Python worker)
- Managed Identity or appropriate credentials configured in the Function App's application settings
- Relevant Azure SDK packages (`azure-storage-blob` for Python functions)
