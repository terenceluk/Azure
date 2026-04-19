# Logic Apps

Additional Azure Logic App workflow definitions for Azure Firewall automation.

## Contents

| File | Description |
|------|-------------|
| `logic-update-azfw-custom-vnet-subnet-table.json` | Logic App workflow that automatically updates a custom Azure Firewall VNet/subnet lookup table. This is useful for keeping firewall log enrichment data (VNet and subnet name mappings) current as your network topology changes. |

## Prerequisites

- Azure Logic Apps (Standard or Consumption tier)
- Appropriate permissions to read Virtual Network information and write to the target data store (e.g., Log Analytics, Storage Table, or Azure Firewall IP Groups)
