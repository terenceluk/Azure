# Subscriptions

PowerShell scripts for managing Azure RBAC role assignments across multiple subscriptions.

## Contents

| File | Description |
|------|-------------|
| `Assign-App-Reg-Permissions-To-Multiple-Subscriptions.ps1` | Assigns a specified Azure RBAC role to an App Registration's service principal across multiple subscriptions. Supports parameters for `AppId`, `RoleName`, `SubscriptionIds`, `SkipExisting`, and `WhatIf`. Includes examples for common roles: Reader, Contributor, Owner, Key Vault Reader, Storage Blob Data Reader, and more. |
| `Grant-Logic-App-Subscription-Permissions.ps1` | Retrieves a Logic App's system-assigned Managed Identity Principal ID and assigns the `Reader` role across all accessible subscriptions, skipping any where the role is already assigned. |

## Prerequisites

- Azure PowerShell (`Az` module) with `Az.Resources`
- `Owner` or `User Access Administrator` role on the target subscriptions (required to assign roles)
