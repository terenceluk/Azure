<#

The purpose of this PowerShell script is to use PowerShell to configure an AI Search's:

1. Data source
2. Index
3. Indexer

... to index data from SharePoint document libraries. This feature as of March 23, 2024 is still in preview and can only be configured via REST API (not in portal.azure.com)

More information about the configuration can be found in the following Microsoft document: https://learn.microsoft.com/en-us/azure/search/search-howto-index-sharepoint-online

#>

########################### Configure AI Search Data source ########################################

# Define variables that will be used to call the REST API
$aiSearchserviceName = "contoso-dev-aisearch" # AI Search logical name
$aiSearchAPIKey = "xxxxxxxxxxxxxxxxxxxxx" # AI Search API Key (AI Serach > Keys > API keys > Primary admin key)
$applicationId = "xxxxxxxxxxxxxxxxxxxxxxxxx" # Application (Client) ID
$applicationSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxx" # App Registration secret
$tenantId = "xxxxxxxxxxxxxxxxxxxxxxxxx" # Directory (Tenant) ID
$sharePointOnlineEndpoint = "https://contoso.sharepoint.com/sites/contosoITOpenAI" # URL of SharePoint site that can be retrieved from SharePoint admin center under "Site address": https://contoso.sharepoint.com/sites/contosoITOpenAI
$sharePointLibrary = "https://contoso.sharepoint.com/sites/contosoITOpenAI/Shared%20Documents/Forms/AllItems.aspx" # URL of document library (ending with AllItems.aspx) that can be retrieved by clicking on the "Documents" menu on the left pane: https://contoso.sharepoint.com/sites/contosoITOpenAI/Shared%20Documents/Forms/AllItems.aspx
$additionalColumns = "Published" # Any additional columns that were created in the document library, "Published" is just an example provided

$aiSearchDatasourceName = "sharepoint-policies" # Datasource logical name (what will be displayed in the data source blade)

$connectionString = "SharePointOnlineEndpoint=$sharePointOnlineEndpoint;ApplicationId=$applicationId;ApplicationSecret=$applicationSecret;TenantId=$tenantId"

$containerName = "defaultSiteLibrary" # Leave this value as is
$containerQuery = "includeLibrary=$sharePointLibrary;additionalColumns=$additionalColumns"

$apiVersion = "2023-10-01-Preview" # Define the version of API to call

# Build the body of REST API call
$body = @"
{
    "name" : "$aiSearchDatasourceName",
    "type" : "sharepoint",
    "credentials" : { "connectionString" : "$connectionString" 
    },
    "container" : { 
        "name": "$containerName", 
        "query": "$containerQuery"
    }
}
"@

# Build the URL to call with the method POST
$url = "https://$aiSearchserviceName.search.windows.net/datasources?api-version=$apiVersion"

# Build the header and insert the AI Search API Key
$headers = @{   
    'api-key' = "$aiSearchAPIKey"
    'Content-Type' = "application/json"
}

# Call the REST API to create the SharePoint data source
$json = Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $body -Verbose
$json

########################### Configure Index ########################################

$aiSearchserviceName = "contoso-dev-aisearch" # AI Search logical name
$aiSearchAPIKey = "xxxxxxxxxxxxxxxxxxxxx" # AI Search API Key (AI Serach > Keys > API keys > Primary admin key)
$apiVersion = "2023-10-01-Preview" # Define the version of API to call
$aiSearchIndexName = "sharepoint-policies-index" # Index logical name (what will be displayed in the indexes blade)
$customColumn = "Published" # Custom column that was created in the document library

# Build the body that will be sent with the default SharePoint fields (first block) and any additional custom columns build (second block)
$body = @"
{
    "name" : "$aiSearchIndexName",
    "fields": [
        { "name": "id", "type": "Edm.String", "key": true, "searchable": false },
        { "name": "metadata_spo_item_name", "type": "Edm.String", "key": false, "searchable": true, "filterable": false, "sortable": false, "facetable": false },
        { "name": "metadata_spo_item_path", "type": "Edm.String", "key": false, "searchable": false, "filterable": false, "sortable": false, "facetable": false },
        { "name": "metadata_spo_item_content_type", "type": "Edm.String", "key": false, "searchable": false, "filterable": true, "sortable": false, "facetable": true },
        { "name": "metadata_spo_item_last_modified", "type": "Edm.DateTimeOffset", "key": false, "searchable": false, "filterable": false, "sortable": true, "facetable": false },
        { "name": "metadata_spo_item_size", "type": "Edm.Int64", "key": false, "searchable": false, "filterable": false, "sortable": false, "facetable": false },
        { "name": "content", "type": "Edm.String", "searchable": true, "filterable": false, "sortable": false, "facetable": false },

        { "name": "$customColumn", "type": "Edm.String", "searchable": true, "filterable": false, "sortable": false, "facetable": false }
        
    ]
}
"@

# Build the URL to call with the method POST
$url = "https://$aiSearchserviceName.search.windows.net/indexes?api-version=$apiVersion"

# Build the header and insert the AI Search API Key
$headers = @{   
    'api-key' = "$aiSearchAPIKey"
    'Content-Type' = "application/json"
}

# Call the REST API to create the AI Search Index
$json = Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $body -Verbose
$json

########################### Configure Indexer ########################################

$aiSearchserviceName = "contoso-dev-aisearch" # AI Search logical name
$aiSearchAPIKey = "xxxxxxxxxxxxxxxxxxxxx" # AI Search API Key (AI Serach > Keys > API keys > Primary admin key)
$apiVersion = "2023-10-01-Preview" # Define the version of API to call
$aiSearchIndexerName = "sharepoint-policies-indexer"
$aiSearchDatasourceName = "sharepoint-policies" # Datasource logical name that was created earlier
$aiSearchIndexName = "sharepoint-policies-index" # Index logical name that was created earlier

# Build the body that will be used to create the indexer
$body = @"
{
    "name" : "$aiSearchIndexerName",
    "dataSourceName" : "$aiSearchDatasourceName",
    "targetIndexName" : "$aiSearchIndexName",
    "parameters": {
    "batchSize": null,
    "maxFailedItems": null,
    "maxFailedItemsPerBatch": null,
    "base64EncodeKeys": null,
    "configuration": {
        "indexedFileNameExtensions" : ".pdf, .docx",
        "excludedFileNameExtensions" : ".png, .jpg",
        "dataToExtract": "contentAndMetadata"
      }
    },
    "schedule" : { },
    "fieldMappings" : [
        { 
          "sourceFieldName" : "metadata_spo_site_library_item_id", 
          "targetFieldName" : "id", 
          "mappingFunction" : { 
            "name" : "base64Encode" 
          } 
         }
    ]
}
"@

# Build the URL to call with the method POST
$url = "https://$aiSearchserviceName.search.windows.net/indexers?api-version=$apiVersion"

# Build the header and insert the AI Search API Key
$headers = @{   
    'api-key' = "$aiSearchAPIKey"
    'Content-Type' = "application/json"
}

# Call the REST API to create the indexer
$json = Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $body -Verbose
$json

########################### Get Indexer ########################################

$aiSearchserviceName = "contoso-dev-aisearch" # AI Search logical name
$aiSearchAPIKey = "xxxxxxxxxxxxxxxxxxxxx" # AI Search API Key (AI Serach > Keys > API keys > Primary admin key)
$apiVersion = "2023-10-01-Preview" # Define the version of API to call
$aiSearchIndexerName = "sharepoint-policies-indexer" # Indexer logical name
$aiSearchDatasourceName = "sharepoint-policies" # Datasource logical name that was created earlier
$aiSearchIndexName = "sharepoint-policies-index" # Index logical name that was created earlier

# Build the body that will be used to get the indexer
$body = @"
{
    "name" : "$aiSearchIndexerName",
    "dataSourceName" : "$aiSearchDatasourceName",
    "targetIndexName" : "$aiSearchIndexName",
    "parameters": {
    "batchSize": null,
    "maxFailedItems": null,
    "maxFailedItemsPerBatch": null,
    "base64EncodeKeys": null,
    "configuration": {
        "indexedFileNameExtensions" : ".pdf, .docx",
        "excludedFileNameExtensions" : ".png, .jpg",
        "dataToExtract": "contentAndMetadata"
      }
    },
    "schedule" : { },
    "fieldMappings" : [
        { 
          "sourceFieldName" : "metadata_spo_site_library_item_id", 
          "targetFieldName" : "id", 
          "mappingFunction" : { 
            "name" : "base64Encode" 
          } 
         }
    ]
}
"@

# Build the URL to call with the method GET
$url = "https://$aiSearchserviceName.search.windows.net/indexers/$aiSearchIndexerName/status?api-version=$apiVersion"

# Build the header and insert the AI Search API Key
$headers = @{   
    'api-key' = "$aiSearchAPIKey"
    'Content-Type' = "application/json"
}

# Call the REST API to get the indexer details
$json = Invoke-RestMethod -Method GET -Uri $url -Headers $headers -Body $body -Verbose
$json
