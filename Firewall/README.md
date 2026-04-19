# Firewall

PowerShell scripts for retrieving Azure Firewall rule and Virtual Network/subnet information.

## Contents

| File | Description |
|------|-------------|
| `Get-Firewall-Rules.ps1` | Retrieves and lists all network and application rules from one or more Azure Firewalls in a subscription, useful for auditing firewall configurations. |
| `Get-VNet-Subnet.ps1` | Retrieves Virtual Network and subnet details for a given subscription or resource group, often used alongside firewall rule analysis to map source/destination IP ranges. |

## Prerequisites

- Azure PowerShell (`Az` module) with `Az.Network`
- Reader or higher permissions on the target Azure Firewall and Virtual Network resources
