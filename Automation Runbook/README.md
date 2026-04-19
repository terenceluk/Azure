# Automation Runbook

Azure Automation Runbook scripts and Duo Security integration modules for user lifecycle and webhook automation.

## Contents

| File | Description |
|------|-------------|
| `Create-New-Duo-User.ps1` | Creates a new user in Duo Security, setting up their account for MFA enrollment. |
| `Create-New-Duo-User-Phone-Send-Activation.ps1` | Creates a new Duo user, associates a phone number, and sends an activation link for Duo Mobile setup. |
| `Email-Duo-User-Count-and-List.ps1` | Retrieves all Duo users, counts them, and emails a summary report. |
| `Sync-Duo-User.ps1` | Synchronizes updated user attributes (e.g., name, email) from a source to Duo Security. |
| `Test-Web-Hook.ps1` | Test runbook for validating that an Azure Automation webhook is reachable and returns the expected payload. |

### Duo Module (`Duo/`)

| File | Description |
|------|-------------|
| `Duo/Duo.psd1` | PowerShell module manifest for the Duo Security helper module. |
| `Duo/Duo.psm1` | PowerShell module that wraps the Duo Admin API, providing functions for user and phone management used by the runbook scripts. |

## Prerequisites

- Azure Automation account
- Duo Admin API credentials (Integration Key, Secret Key, API Hostname) stored as Automation Variables or Assets
- The `Duo` module imported into the Automation account
