# App Gateway

Scripts and reference data for managing Azure Application Gateway, including WAF exclusion rules.

## Contents

| File | Description |
|------|-------------|
| `Add-AppGatewayWafExclusions.ps1` | PowerShell script that reads WAF rule exclusion definitions and programmatically adds them to an Azure Application Gateway WAF policy. |
| `RuleIDs-Feb-18-2026.csv` | Reference CSV of WAF rule IDs exported as of February 18, 2026, used as input for the exclusion script. |

## Prerequisites

- Azure PowerShell (`Az` module) with `Az.Network`
- Appropriate RBAC permissions on the Application Gateway resource
