<#

This script first retrieves all existing settings and stores them into a hash table. 
Then it updates this hash table with new key-value pairs from the JSON. 
Lastly, uses the hash table to update the app settings in the app service.

More information about the environment variables can be found here: https://github.com/microsoft/sample-app-aoai-chatGPT

Detailed breakdown can be found in my blog post here: https://blog.terenceluk.com/2024/05/customizing-look-of-sample-web-app-deployed-by-azure-openai-studio.html

#>

# Log into Azure
Connect-AzAccount

# Define required variables for the App Service to be configured
$subscriptionID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"
$webAppRG = "dev-openai-rg"
$webAppName = "RAG-Demo-App"

# Select the subscription with the App Service using the subscription ID
Set-AzContext -Subscription $subscriptionID

# Get the Web App object and store it
$webApp = Get-AzWebApp -ResourceGroupName $webAppRG -Name $webAppName

# Define JSON in code with the environment variables to be added
$json = '
[
    {
        "key": "UI_CHAT_LOGO",
        "value": "https://tlimageassets.blob.core.windows.net/images/TL-Logo-small.png"
    },
    {
        "key": "UI_CHAT_TITLE",
        "value": "Start chatting with the bot"
    },
    {
        "key": "UI_FAVICON",
        "value": "https://tlimageassets.blob.core.windows.net/images/favicon.ico"
    },
    {
        "key": "UI_LOGO",
        "value": "https://tlimageassets.blob.core.windows.net/images/TL-Logo-small.png"
    },
    {
        "key": "UI_TITLE",
        "value": "TL Corporation"
    },
    {
        "key": "UI_CHAT_DESCRIPTION",
        "value": "Use this bot to ask questions"
    },
    {
        "key": "UI_SHOW_SHARE_BUTTON",
        "value": "True"
    }
]
' | ConvertFrom-Json

# Create a hash table for the application settings of the App Service
$appSettingsHashTable = @{}

# Populate the hash table with current App Service settings
foreach($appSetting in $webApp.SiteConfig.AppSettings) {
    $appSettingsHashTable[$appSetting.Name] = $appSetting.Value
       
}

# Add additional settings from the JSON
foreach($pair in $json) {
    $appSettingsHashTable[$pair.key] = $pair.value
}

# Update the App Service with the hash table containing the new key-value pairs
Set-AzWebApp -ResourceGroupName $webAppRG -Name $webAppName -AppSettings $appSettingsHashTable
