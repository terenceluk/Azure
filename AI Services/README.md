# AI Services

PowerShell scripts and configuration for Azure AI Services, including Azure OpenAI deployments and AI Search integration with SharePoint Online.

## Contents

| File | Description |
|------|-------------|
| `Deploy-Azure-OpenAI-with-Chatbot-UI.ps1` | Deploys an Azure OpenAI resource and provisions a Chatbot UI web application on Azure App Service. |
| `OpenAI-Studio-Customize-Web-App.ps1` | Customizes an Azure OpenAI Studio web app deployment (e.g., settings, branding, or configuration). |
| `SharePoint Online Indexer/Configure-AI-Search-for-SharePoint.ps1` | Configures an Azure AI Search indexer to crawl and index a SharePoint Online site. |
| `SharePoint Online Indexer/Create-App-Registration.sh` | Azure CLI script to create the Entra ID (Azure AD) App Registration required for the SharePoint Online indexer to authenticate. |

## Prerequisites

- Azure PowerShell (`Az` module)
- Azure CLI (for `.sh` scripts)
- Appropriate permissions to create Azure resources and Entra ID App Registrations
