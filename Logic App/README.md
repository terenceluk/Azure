# Logic App

Azure Logic App workflow definitions and supporting configuration for automation scenarios including password expiry notifications, firewall log analysis with AI, SFTP event processing, and Azure Resource Graph queries.

## Contents

### Workflow Definitions

| File | Description |
|------|-------------|
| `anonymous-host.json` | Logic App host configuration file for anonymous (no-auth) HTTP trigger setup. |
| `Azure-Resource-Graph-Explorer.json` | Logic App workflow that queries Azure Resource Graph and returns resource data, useful for inventory or reporting automation. |
| `Merged.json` | Combined or merged Logic App workflow definition (multiple workflows or steps merged into one). |
| `Password-Expiry.json` | Logic App workflow that sends password expiry notification emails to users whose passwords are approaching expiration. |
| `Sftp-Events.json` | Logic App workflow triggered by SFTP events (e.g., file arrival), processing or routing the incoming files. |

### Batch Processing Firewall Logs with AI (`Batch-Processing-Firewall-Logs-with-AI/`)

An end-to-end Logic App solution that retrieves Azure Firewall logs, processes them in batches, and sends them to an Azure OpenAI LLM for analysis and summarization.

| File | Description |
|------|-------------|
| `workflow.json` | Main Logic App workflow definition for the firewall log AI analysis pipeline. |
| `Query-Firewall-Logs.kql` | KQL query used by the workflow to pull Azure Firewall log entries from Log Analytics. |
| `Parse-JSON-Schema.json` | JSON schema used in the Logic App **Parse JSON** action to structure the Log Analytics query results. |
| `Query-AI-LLM.json` | Configuration or payload template for the HTTP action that calls the Azure OpenAI API with the firewall log batch. |
| `HTML-Formatting.txt` | HTML template used to format the AI-generated analysis for email or notification output. |
| `README.md` | Documentation for the Batch Processing Firewall Logs with AI workflow. |

## Prerequisites

- Azure Logic Apps (Standard or Consumption tier)
- Log Analytics workspace with Azure Firewall diagnostic logs
- Azure OpenAI resource with a deployed model (for the AI batch processing workflow)
- Appropriate managed identity or connection credentials configured in the Logic App
