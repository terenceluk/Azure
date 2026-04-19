# PowerShell

A broad collection of reusable PowerShell scripts for Azure administration, identity management, security, compliance, networking, and Terraform assistance.

## Contents

### Identity & Authentication

| File | Description |
|------|-------------|
| `Connect-AzAccount-with-Service-Principal.ps1` | Demonstrates authenticating to Azure using a Service Principal with a client secret via `Connect-AzAccount -ServicePrincipal`. |
| `ServicePrincipalCertificateAuthentication.ps1` | Creates a self-signed certificate, registers it on an App Registration, creates a Service Principal, assigns Azure AD roles, and demonstrates certificate-based authentication. |
| `Update-Azure-AD-UPN-Domain.ps1` | Updates all non-guest Azure AD user UPNs from an `onmicrosoft.com` domain to a custom domain (e.g., during tenant domain migrations). |
| `EnterpriseApps-Permissions.ps1` | Compares AD group members with users assigned to an Enterprise Application and assigns new users using `New-AzureADUserAppRoleAssignment`. |
| `Assign-GraphPermissionsToEnterpriseApplication.ps1` | Assigns Microsoft Graph API permissions to an Enterprise Application's service principal. |
| `Assign-GraphPermissionsToEnterpriseApplication_v2.ps1` | Updated version of the Graph permissions assignment script. |
| `Configure-Managed-Identity-API-Permissions.ps1` | Assigns Microsoft Graph (or other API) permissions to a Managed Identity service principal. |

### App Registration Expiration Reporting

Four variants of a script that inventories all App Registrations, calculates certificate and secret expiration dates, and sends the results to a Log Analytics workspace:

| File | Description |
|------|-------------|
| `Get-AppRegistrationExpirationInteractive.ps1` | Interactive login (`Connect-AzAccount`) version. |
| `Get-AppRegistrationExpirationAutomation.ps1` | Azure Automation Runbook version using a PSCredential asset. |
| `Get-AppRegistrationExpirationManagedSystemIdentity.ps1.ps1` | System-assigned Managed Identity version (`Connect-AzAccount -Identity`). |
| `Get-AppRegistrationExpirationServicePrincipal.ps1` | Service Principal version with hardcoded credentials. |

### Networking

| File | Description |
|------|-------------|
| `Create-IP-Groups.ps1` | Creates Azure Firewall IP Groups from a list of IP addresses or CIDR ranges. |
| `Create-Route-Tables-and-UDRs.ps1` | Reads route table and UDR definitions from an Excel file and creates them in Azure. |

### Storage

| File | Description |
|------|-------------|
| `Create-Storage-Account-Container.ps1` | Reads container definitions from an Excel file, creates missing containers in a Storage Account, and sets metadata on each. |

### Monitoring & Log Analytics

| File | Description |
|------|-------------|
| `CreateWindowsEventLogsForLogAnalytics.ps1` | Creates Windows Event Log data sources in a Log Analytics workspace for Azure Virtual Desktop monitoring. |
| `CreateWindowsPerformanceCountersForLogAnalytics.ps1` | Creates Windows Performance Counter data sources in Log Analytics for AVD monitoring. |
| `Get-Expiring-Passwords.ps1` | Uses Microsoft Graph to find enabled users with passwords expiring within a configurable warning period and reports on expired/soon-to-expire accounts. |

### Azure SQL

| File | Description |
|------|-------------|
| `Backup-AzureSQLDatabases.ps1` | Triggers on-demand backups of Azure SQL Databases across resource groups. |
| `Export-All-Subscriptions-AzureSQLDatabases-To-Excel.ps1` | Retrieves all Azure SQL Databases from a subscription and exports the list to an Excel file. |

### Security & Compliance

| File | Description |
|------|-------------|
| `Export_WAF-Policy-OWASP_3-2-Rules.ps1` | Retrieves OWASP CRS 3.2 WAF rule sets from Azure Application Gateway and exports them. |
| `Export_WAF-Policy-OWASP_3-2-Rules.json` | JSON export of OWASP 3.2 WAF rules (reference data). |
| `OWASP_3_2_rules.csv` | CSV export of OWASP 3.2 WAF rules for reference or import. |
| `New-ComplianceSearchAction-Continuously-Purge.ps1` | Continuously creates and purges Microsoft 365 compliance search results in batches (hard-delete, for >10 items). |

### Utilities

| File | Description |
|------|-------------|
| `Generate-Random-Password.ps1` | Generates cryptographically random passwords meeting complexity requirements using `RNGCryptoServiceProvider`. |
| `Generate-OneTimeSecret-URL.ps1` | Calls the OneTimeSecret API to create a one-time viewable secret link for a given password. |
| `AzureVM-MatchNames.ps1` | Matches Azure VM names against a reference list, useful for reconciliation or filtering operations. |

### Terraform Helpers

| File | Description |
|------|-------------|
| `Extract-import-tf-file.ps1` | Parses an `import.tf` file produced by `aztfexport`, extracting resource IDs and Terraform logical names into a CSV. |
| `Replace-Text-with-CSV-Reference.ps1` | Uses a CSV (from `Extract-import-tf-file.ps1`) to perform whole-word regex replacements across Terraform files, replacing generic `res-N` names with actual Azure resource names. |

### KQL (included in PowerShell folder)

| File | Description |
|------|-------------|
| `Temp.kusto` | KQL query identifying top CPU-consuming processes (Perf table, >90% CPU threshold). |

## Prerequisites

- Azure PowerShell (`Az` module) — most scripts
- `AzureAD` or `Microsoft.Graph` module — identity scripts
- `ImportExcel` module — Excel-related scripts
- `ExchangeOnlineManagement` — compliance purge script
