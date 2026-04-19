# Azure Price

Python scripts for retrieving Azure VM pricing using the Azure Retail Prices API, with support for CSV-driven lookups and JSON output.

## Contents

| File | Description |
|------|-------------|
| `Get-Azure-VM-SKUs.py` | Retrieves and lists available Azure VM SKUs and their pricing for a specified region. |
| `Retrieve-Azure-VM-Cost-With-CSV-Reference.py` | Reads a CSV file containing VM SKU names and retrieves current pricing for each from the Azure Retail Prices API. |
| `Retrieve-Azure-VM-Cost-With-Input-Output-JSON-And-CSV.py` | Takes a JSON input file of VM definitions, retrieves pricing, and outputs results in both JSON and CSV formats. |

## Prerequisites

- Python 3.x
- `requests` library (`pip install requests`)
- No Azure authentication required — uses the public [Azure Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices)
