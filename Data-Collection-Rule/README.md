# Data Collection Rule

Scripts for testing Azure Monitor Data Collection Rules (DCR) and custom log table ingestion.

## Contents

| File | Description |
|------|-------------|
| `Test-Custom-Table-Insert.ps1` | PowerShell script that sends a test JSON payload to a custom Log Analytics table via a Data Collection Rule endpoint. Useful for validating DCR configuration, ingestion mappings, and confirming that data appears in the target custom table. |

## Prerequisites

- Azure PowerShell (`Az` module)
- A configured Data Collection Rule with a custom table destination in a Log Analytics workspace
- The DCR endpoint URL and DCR Immutable ID
- `Monitoring Metrics Publisher` role assigned on the DCR to the identity running the script
