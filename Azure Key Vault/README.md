# Azure Key Vault

Scripts and utilities for interacting with Azure Key Vault secrets.

## Contents

| File | Description |
|------|-------------|
| `get-secret.bat` | Windows batch script that uses the Azure CLI (`az keyvault secret show`) to retrieve a secret value from an Azure Key Vault and display it in the terminal. |

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Reader or higher permissions on the Key Vault, and **Get** permission on secrets (via Key Vault access policy or RBAC)
