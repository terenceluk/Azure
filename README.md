# Azure

A collection of scripts, queries, and workflow definitions for managing and automating Azure infrastructure and services. Topics covered include networking, security, identity, monitoring, AI/ML, and cost management.

## Repository Structure

| Folder | Description |
|--------|-------------|
| [`AI Foundry`](./AI%20Foundry/) | Azure AI Foundry prompt flow workflow definitions for chatbot model selection. |
| [`AI Services`](./AI%20Services/) | Scripts for deploying Azure OpenAI resources and configuring AI Search with SharePoint Online. |
| [`AI-Foundry-Agent-Instructions`](./AI-Foundry-Agent-Instructions/) | System prompt instructions for Azure AI Foundry agents (e.g., Azure Resource Graph query executor). |
| [`API Management`](./API%20Management/) | APIM policy XML snippets for JWT validation, API key forwarding, and traffic capture. |
| [`App Gateway`](./App%20Gateway/) | Scripts for managing Azure Application Gateway WAF exclusion rules. |
| [`App Services`](./App%20Services/) | Scripts for bulk-configuring Azure App Service application settings and environment variables. |
| [`Automation Runbook`](./Automation%20Runbook/) | Azure Automation Runbooks and a Duo Security PowerShell module for user lifecycle automation. |
| [`Azure Calculator`](./Azure%20Calculator/) | Python scripts for retrieving Azure pricing data using the Azure Retail Prices API. |
| [`Azure Firewall`](./Azure%20Firewall/) | Scripts for converting Azure Firewall JSON diagnostic logs to CSV and managing network rule collections. |
| [`Azure Front Door`](./Azure%20Front%20Door/) | KQL queries for analyzing Front Door traffic patterns, routing rules, and regional distribution. |
| [`Azure Key Vault`](./Azure%20Key%20Vault/) | Utility scripts for retrieving secrets from Azure Key Vault via the Azure CLI. |
| [`Azure Price`](./Azure%20Price/) | Python scripts for querying Azure VM SKU pricing with CSV and JSON input/output support. |
| [`Azure Virtual Network`](./Azure%20Virtual%20Network/) | Scripts for configuring subnet address prefixes within Azure Virtual Networks. |
| [`Data-Collection-Rule`](./Data-Collection-Rule/) | Scripts for testing Log Analytics custom table ingestion via Data Collection Rule endpoints. |
| [`Event Hub`](./Event%20Hub/) | Python scripts for receiving events from Azure Event Hub and forwarding them to Log Analytics. |
| [`Firewall`](./Firewall/) | Scripts for auditing Azure Firewall rules and retrieving VNet/subnet information. |
| [`Function App`](./Function%20App/) | PowerShell and Python Azure Functions for VM management, device reporting, and blob metadata. |
| [`Kusto KQL`](./Kusto%20KQL/) | KQL query library covering AAD sign-ins, Azure Firewall, WAF, OpenAI token usage, and App Gateway autoscaling. |
| [`Logic App`](./Logic%20App/) | Logic App workflow definitions for password expiry notifications, SFTP events, and AI-powered firewall log analysis. |
| [`Logic Apps`](./Logic%20Apps/) | Additional Logic App workflows for automating Azure Firewall VNet/subnet table updates. |
| [`PowerShell`](./PowerShell/) | General-purpose Azure PowerShell scripts covering identity, RBAC, SQL, networking, compliance, and Terraform helpers. |
| [`Private DNS Zones`](./Private%20DNS%20Zones/) | Scripts for comparing Private DNS zone records across two Azure tenants (e.g., Production vs. DR). |
| [`Resource Graph Explorer`](./Resource%20Graph%20Explorer/) | KQL queries for Azure Resource Graph to search VNets, subnets, CIDRs, and IP addresses across subscriptions. |
| [`Storage Account`](./Storage%20Account/) | Scripts for exporting/importing Storage Account firewall rules and managing blob metadata. |
| [`Subscriptions`](./Subscriptions/) | Scripts for assigning Azure RBAC roles to service principals across multiple subscriptions. |

## Languages & Tools

- **PowerShell** — Azure PowerShell (`Az` module), Microsoft Graph, AzureAD
- **Python** — `azure-sdk-for-python`, `azure-storage-blob`, `azure-eventhub`, `azure-identity`
- **KQL** — Azure Monitor Log Analytics, Azure Data Explorer, Azure Resource Graph
- **Azure CLI** — Bash/shell scripts
- **JSON / YAML** — Logic App workflows, AI Foundry prompt flows, APIM policies

