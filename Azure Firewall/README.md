# Azure Firewall

Scripts for working with Azure Firewall logs and network rule management.

## Contents

| File | Description |
|------|-------------|
| `Convert-JSON-Logs-to-CSV.ps1` | Converts Azure Firewall diagnostic JSON log files to CSV format for easier analysis. |
| `Bulk-Convert-Az-Firewall-Logs-JSON-to-CSV.ps1` | Bulk version that processes multiple JSON log files in a directory and converts them all to CSV. |
| `Bulk-Convert-Az-Firewall-Logs-JSON-to-CSV_v2.ps1` | Updated version of the bulk converter with additional handling for different Azure Firewall log schemas. |
| `Function-Convert-JSON-Logs-to-CSV.ps1` | Refactored version of the JSON-to-CSV converter using a reusable function, suitable for inclusion in larger scripts or modules. |
| `Create-NetworkRuleCollection.ps1` | PowerShell script that creates a Network Rule Collection in an Azure Firewall, adding rules for specific source/destination IP and port combinations. |
| `subnet-schema-sample.json` | Sample JSON schema file representing subnet definitions, used as reference or input for firewall rule scripts. |

## Prerequisites

- Azure PowerShell (`Az` module) with `Az.Network`
- Azure Firewall diagnostic logs exported to a storage account or Log Analytics
