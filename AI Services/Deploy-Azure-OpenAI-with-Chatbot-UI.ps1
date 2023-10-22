<#

***Version 1.0***
October 22, 2023

The purpose of this script is to collect all the information required to deploy the Azure OpenAI service, a model, and a container app providing a Chatbot UI interface
then create the resources and launch the Container App provider the UI for the chatbot.

This script is designed to receive input from the user for:
1. Subscription
2. Resource Group
3. OpenAI instance name
4. Model

The OpenAI instance name is used to derive the name for other items such as Container App components and Log Analytics.

Improvements to error handling and other components (conflict with custom domain, 32 character limit for Container App, automatic creation of Identity Provider, etc) will be made so please check back for updated versions.

#>

# Declare hardcoded variables for the deployment
$deploymentRegion = "canadaeast" # Region for the deployment
$openAISku = "S0" # Pricing tier for the OpenAI Service
$modelSkuName = 'Standard'
$modelSkuCapacity = '1'

Write-Host "Starting OpenAI with Chatbot UI Deployment..."
Write-Host "Logging into Azure Cloud"

# Connect to Azure tenant
Connect-AzAccount

### List Subscriptions and ask user to select which to deploy OpenAI ###
$SubscriptionList = Get-AzSubscription

Write-Host "There are $($SubscriptionList.count) subscriptions in this tenant"
# Starting at 1 rather than 0 so number will be shifted
$index = 1
foreach ( $SubscriptionName in $SubscriptionList) {
    Write-Host " [$($index)] Name: $($SubscriptionName.name) | ID: $($SubscriptionName.Id) | State: $($SubscriptionName.state)"
    $index++
}


# Ask to select subscription with number and check to see if the selection is within range of subscriptions
Do { 
    "`n"
    [Int]$SubscriptionSelection = Read-Host "Please enter the number for the subscription where you want to deploy OpenAI and the Chatbot UI"
    # Check if invalid value is entered
    if ($SubscriptionSelection -gt $SubscriptionList.count -or $SubscriptionSelection -lt 1) {
        Write-Host "Please enter a valid selection:"
        $index = 1
        foreach ( $SubscriptionName in $SubscriptionList) {
            Write-Host " [$($index)] Name: $($SubscriptionName.name) | ID: $($SubscriptionName.Id) | State: $($SubscriptionName.state)"
            $index++
        }
    }
}
Until ($SubscriptionSelection -le $SubscriptionList.count -and $SubscriptionSelection -ge 1)


# Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$SubscriptionSelection--
$SubscriptionName = $SubscriptionList[$SubscriptionSelection]
"`n"
Write-Host "Subscription ""Name: $($SubscriptionName.name) | ID: $($SubscriptionName.Id) | State: $($SubscriptionName.state)"" selected."

$subscriptionID = $SubscriptionName.Id

Set-AzContext -SubscriptionId $subscriptionID

### Ask user to enter a resource group name that will be created to store all solution resources ###

$openAIresourceGroupName = Read-Host "Please type in a name for the resource group that will be created and used to store all solution resources"

New-AzResourceGroup -Name $openAIresourceGroupName -Location $deploymentRegion

<#**************************************************** 

Begin deploying OpenAI Service

****************************************************#>

$openAIInstanceName = Read-Host "Please type in a name for the OpenAI instance"
$openAIInstanceCustomDomainName = Read-Host "Please type in a Custom Domain Name for the OpenAI instance [Default: $openAIInstanceName]"

# If no custom domain name is entered then use the OpenAI instance name
if ($openAIInstanceCustomDomainName -eq "") {
    $openAIInstanceCustomDomainName = $openAIInstanceName
}

try {
    # Try creating the OpenAI instance (name needs to be unique)
    New-AzCognitiveServicesAccount -ResourceGroupName $openAIresourceGroupName -Name $openAIInstanceName -Type OpenAI -SkuName $openAISku -Location $deploymentRegion -CustomSubdomainName $openAIInstanceCustomDomainName
    $openAIcreationSuccess = $true
}
catch {
    Write-Host "An error has occurred during the creation of the OpenAI instance."
    Exit
    Write-Host $_.Exception.Message 
}

New-AzCognitiveServicesAccount -ResourceGroupName $openAIresourceGroupName -Name $openAIInstanceName -Type OpenAI -SkuName $openAISku -Location canadaeast -CustomSubdomainName $openAIInstanceCustomDomainName

# Get the OpenAI configuration values

# Get the API endpoint
$openAIEndpoint = Get-AzCognitiveServicesAccount -ResourceGroupName $openAIresourceGroupName -Name $openAIInstanceName | Select-Object -Property endpoint
# Assign the API endpoint value to a variable
$openAIEndpointValue = $openAIEndpoint.endpoint

# Get the Primary Key
$openAIPrimaryKey = Get-AzCognitiveServicesAccountKey -ResourceGroupName $openAIresourceGroupName -Name $openAIInstanceName | Select-Object -Property Key1
# Assign the Primary Key value to a variable
$openAIPrimaryKeyValue = $openAIPrimaryKey.key1

### Deploy a model for the OpenAI instance ###

# Define the model selection as JSON
$modelsAsJSON = @"
[
    {
        "Model": "gpt-35-turbo-16k",
        "Version": "0613"
    },
    {
        "Model": "gpt-35-turbo",
        "Version": "0613"
    },
    {
        "Model": "gpt-4",
        "Version": "0613"
    },
    {
        "Model": "gpt-4-32k",
        "Version": "0613"
    },
    {
        "Model": "text-embedding-ada-002",
        "Version": "2"
    }
]
"@

$listOfModels = $modelsAsJSON | ConvertFrom-Json 

Write-Host "There are $($listOfModels.count) models available"
# Starting at 1 rather than 0 so number will be shifted
$index = 1
foreach ( $model in $listOfModels) {
    Write-Host " [$($index)] Name: $($model.Model) | Version: $($model.Version)"
    $index++
}

# Ask to select model with number and check to see if the selection is within range of subscriptions
Do { 
    "`n"
    [Int]$ModelSelection = Read-Host "Please enter the number for the model you want to deploy"
    # Check if invalid value is entered
    if ($ModelSelection -gt $listOfModels.count -or $ModelSelection -lt 1) {
        Write-Host "Please enter a valid selection:"
        $index = 1
        foreach ( $Model in $listOfModels) {
            Write-Host " [$($index)] Name: $($model.Model) | Version: $($model.Version)"
            $index++
        }
    }
}
Until ($ModelSelection -le $listOfModels.count -and $ModelSelection -ge 1)


# Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$ModelSelection--
$ModelSelected = $listOfModels[$ModelSelection]
"`n"
Write-Host "Model ""Name: $($ModelSelected.Model) | ID: $($ModelSelected.Version) "" selected."

###### End selecting the model to deploy ##########

$model = New-Object -TypeName 'Microsoft.Azure.Management.CognitiveServices.Models.DeploymentModel' -Property @{
    Name    = $ModelSelected.Model
    Version = $ModelSelected.Version
    Format  = 'OpenAI'
}

$properties = New-Object -TypeName 'Microsoft.Azure.Management.CognitiveServices.Models.DeploymentProperties' -Property @{
    Model = $model
}

$sku = New-Object -TypeName "Microsoft.Azure.Management.CognitiveServices.Models.Sku" -Property @{
    Name     = $modelSkuName
    Capacity = $modelSkuCapacity
}

# Ask what model name to use
$modelName = Read-Host "Please enter the a name for the model [Default: $($ModelSelected.Model)]"

if ($modelName -eq "") {
    $modelName = $ModelSelected.Model
}

# Deploy the model
New-AzCognitiveServicesAccountDeployment -ResourceGroupName $openAIresourceGroupName -AccountName $openAIInstanceName -Name $modelName -Properties $properties -Sku $sku

<#**************************************************** 

Begin deploying Container App for Chatbot UI

****************************************************#>

$containerAppTemplateName = "$openAIInstanceName-chatbot-cat"
$containerAppManagedEnvName = "$openAIInstanceName-chatbot-cae"
$workspaceName = "$openAIInstanceName-chatbot-containerapp-log"
$workspaceSku = "PerGB2018"
$registryLoginServer = "ghcr.io"
$image = "mckaywrigley/chatbot-ui"
$tag = "main"
$containerAppCPU = "2.0"
$containerAppMemory = "4Gi"

# Container app name has a character length of 32 or less
$containerAppName = "$openAIInstanceName-chatbot-ui-ca"
$containerAppActiveRevisionsMode = "Single"
$ingressTransport = "auto"
$ingressTargetPort = 3000

$trafficWeightLabel = "production"
$trafficWeightWeight = 100

# Create Traffic Weight
$trafficWeight = New-AzContainerAppTrafficWeightObject -Label $trafficWeightLabel -LatestRevision $True -Weight $trafficWeightWeight

### Configure Container App Secrets ###

# Declare Container App Secrets in JSON format
# Note that secret keys and values cannot have underscores or capitalizations
$containerAppSecretsJSON = @"
[
{
    "Name": "openaiapikey",
    "Value": "$openAIPrimaryKeyValue"
}
]
"@

# Convert the JSON to System.Object in preparation to loop and create Secret objects to place into an array
$listOfSecrets = $containerAppSecretsJSON | ConvertFrom-Json 

# Storing Secrets in an array
$secretObject = @()
foreach ( $eachSecret in $listOfSecrets) {
    $secretObject += New-AzContainerAppSecretObject -Name $eachSecret.name -Value $eachSecret.value
}


### Configure Container App Environment Variables ###

# Declare Container App Environment Variables in JSON format
$containerAppEnvironmentJSON = @"
[
    {
        "Name": "OPENAI_API_KEY",
        "Value": "",
        "SecretRef": "openaiapikey"
    },
    {
        "Name": "OPENAI_API_HOST",
        "Value": "$openAIEndpointValue"
    },
    {
        "Name": "OPENAI_API_TYPE",
        "Value": "azure"
    },
    {
        "Name": "OPENAI_API_VERSION",
        "Value": "2023-03-15-preview"
    },
    {
        "Name": "AZURE_DEPLOYMENT_ID",
        "Value": "gpt-35-turbo"
    },
    {
        "Name": "DEFAULT_MODEL",
        "Value": "gpt-35-turbo"
    }
]
"@

# Convert the JSON to System.Object in preparation to loop and create environment variable objects to place into an array
$listOfEnvironmentVariables = $containerAppEnvironmentJSON | ConvertFrom-Json 

# Storing Environment Variables in an array
$envVarObject = @()
foreach ( $eachEnvVar in $listOfEnvironmentVariables) {
    if ($eachEnvVar.value -eq "") {
        # This will handle an environment variable that references a secret
        $envVarObject += New-AzContainerAppEnvironmentVarObject -Name $eachEnvVar.name -SecretRef $eachEnvVar.SecretRef            
    }
    else {
        $envVarObject += New-AzContainerAppEnvironmentVarObject -Name $eachEnvVar.name -Value $eachEnvVar.value
    }
}

$image = New-AzContainerAppTemplateObject -Name $containerAppTemplateName -Image ($registryLoginServer + "/" + $image + ":" + $tag) -Probe $probe -ResourceCpu $containerAppCPU -ResourceMemory $containerAppMemory -Env $envVarObject

New-AzOperationalInsightsWorkspace -ResourceGroupName $openAIresourceGroupName -Name $workspaceName -Sku $workspaceSku -Location $deploymentRegion -PublicNetworkAccessForIngestion "Enabled" -PublicNetworkAccessForQuery "Enabled"
$CustomId = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $openAIresourceGroupName -Name $workspaceName).CustomerId
$SharedKey = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $openAIresourceGroupName -Name $workspaceName).PrimarySharedKey

New-AzContainerAppManagedEnv -EnvName $containerAppManagedEnvName -ResourceGroupName $openAIresourceGroupName -Location $deploymentRegion -AppLogConfigurationDestination "log-analytics" -LogAnalyticConfigurationCustomerId $CustomId -LogAnalyticConfigurationSharedKey $SharedKey -VnetConfigurationInternal:$false

$EnvId = (Get-AzContainerAppManagedEnv -ResourceGroupName $openAIresourceGroupName -EnvName $containerAppManagedEnvName).Id

# Create the Container App
New-AzContainerApp -Name $containerAppName -ResourceGroupName $openAIresourceGroupName -Location $deploymentRegion -ConfigurationActiveRevisionsMode $containerAppActiveRevisionsMode -ManagedEnvironmentId $EnvId -IngressExternal -IngressTransport $ingressTransport -IngressTargetPort $ingressTargetPort -TemplateContainer $image -ConfigurationSecret $secretObject -IngressTraffic $trafficWeight

# Launch browser and access the Container App URL
# Retrieve the ingress FQDN
$ingressFQDN = (Get-AzContainerApp -Name $containerAppName -ResourceGroupName $openAIresourceGroupName).ingressFQDN

# Launch browser
Start-Process "https://$ingressFQDN"
