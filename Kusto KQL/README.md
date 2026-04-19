# Kusto KQL

A collection of KQL (Kusto Query Language) queries for Azure Monitor Log Analytics, covering security, networking, firewall analysis, AI monitoring, and Application Gateway diagnostics.

## Contents

### General Queries

| File | Description |
|------|-------------|
| `AAD-Failed-SignIns.kusto` | Queries Azure AD sign-in logs for failed authentication attempts, useful for detecting brute-force or suspicious login activity. |
| `Active-Directory-Failed-Login.kusto` | Queries on-premises Active Directory failed login events forwarded to Log Analytics. |
| `Azure-App-Gateway-Website-Stats.kusto` | Aggregates Application Gateway access logs to produce website traffic statistics (requests, response codes, latency). |
| `Azure-Firewall-Azure-Diagnostics.kusto` | Queries the legacy `AzureDiagnostics` table for Azure Firewall log data, covering network and application rule hits. |
| `Azure-WAF-Policy-Custom-Rules-Exclusions.kql` | Queries WAF logs to identify requests matching custom WAF rules and active exclusions. |
| `Azure-WAF-Policy-Managed-Rules-Exclusions.kql` | Queries WAF logs focusing on managed (OWASP) rule hits and applied exclusions. |
| `Combine-AZ-Firewall-Logs.kql` | Combines multiple Azure Firewall log tables (`AZFWApplicationRule`, `AZFWNetworkRule`, etc.) into a unified view. |
| `Enriched-Azure-Firewall-Logs-Query-AZFWApplicationRule-with-VNet-Subnet-Information.kql` | Enriches `AZFWApplicationRule` log entries with source VNet and subnet information resolved from IP address ranges. |
| `Enriched-Azure-Firewall-Logs-Query-AZFWNetworkRule-with-VNet-Subnet-Information.kql` | Enriches `AZFWNetworkRule` log entries with source VNet and subnet information. |
| `Get Expiring and Expired App Reg Certs and Secrets.kusto` | Queries the `AppRegistrationExpiration` custom log table for app registrations with expiring or expired certificates and secrets. |
| `Get-Computer-Logon-Policy-Processing-Duration.kusto` | Analyzes Group Policy processing duration for computer logons from Windows Event logs. |
| `Get-User-Logon-Policy-Processing-Duration.kusto` | Analyzes Group Policy processing duration for user logons. |
| `Identify-token-usage-by-ip-and-mode.kusto` | Identifies Azure OpenAI token usage broken down by client IP and request mode. |
| `Monitor-prompt-completions.kusto` | Monitors Azure OpenAI prompt and completion requests, tracking usage and response patterns. |
| `Query-Storage-Account-Key-Vault-Azure-SQL-Database-Networking-Settings.kusto` | Cross-resource query that reports on networking settings (firewall rules, private endpoints) for Storage Accounts, Key Vaults, and Azure SQL Databases. |
| `Retrieve-VNet-Subnet-Information.kql` | Retrieves VNet and subnet IP information from Azure resource logs or Resource Graph data stored in Log Analytics. |
| `WAF-Troubleshooting.kusto` | General WAF troubleshooting query to identify blocked requests, rule IDs triggered, and client details. |

### Application Gateway — Autoscaling (`Application Gateway/Autoscaling/`)

| File | Description |
|------|-------------|
| `Instance-Activity-Window.kql` | Shows the active time window for each Application Gateway instance. |
| `Instance-Count.kql` | Tracks the instance count of an autoscaling Application Gateway over time. |
| `Instance-IDs.kql` | Lists unique instance IDs seen in the Application Gateway metrics. |
| `Instance-Lifecycle.kql` | Tracks scale-out and scale-in lifecycle events for Application Gateway instances. |
| `Request-Distribution.kql` | Shows how incoming requests are distributed across Application Gateway instances. |
| `Scale-Out-Events.kql` | Identifies specific scale-out events and the conditions that triggered them. |
| `Scaling-Summary.kql` | Summarizes autoscaling activity over a time period, including min/max instance counts. |
| `README.md` | Documentation for the Application Gateway autoscaling queries. |

## Usage

Run these queries in [Azure Monitor Log Analytics](https://portal.azure.com) or [Azure Data Explorer](https://dataexplorer.azure.com). Ensure the relevant diagnostic settings are enabled on the Azure resources being queried.
