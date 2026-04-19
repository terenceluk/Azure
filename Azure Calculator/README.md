# Azure Calculator

Python scripts for programmatically retrieving Azure pricing and generating cost estimates using the Azure Retail Prices API.

## Contents

| File | Description |
|------|-------------|
| `Azure-Calculator-Estimate-Generator.py` | Queries the Azure Retail Prices API and generates a cost estimate report for a set of Azure resources or SKUs. |
| `Azure-Calculator-Product-Only.py` | Retrieves pricing information for specific Azure products only (without generating a full estimate), useful for quick price lookups. |

## Prerequisites

- Python 3.x
- `requests` library (`pip install requests`)
- No Azure authentication required — uses the public [Azure Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices)
