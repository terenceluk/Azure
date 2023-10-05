<# 
PowerShell for creating Azure Storage Account Containers and adding Metadata from a list in a spreadsheet.

Excel preadsheet fields required:
1. Storage Account Name
2. Container name
3. Metadata key
4. Metadata value

Manage blob containers using PowerShell
https://learn.microsoft.com/en-us/azure/storage/blobs/blob-containers-powershell
#>

# Install and import the Azure PowerShell module
Install-Module -Name Az.Storage -Force
Install-Module -Name ImportExcel -Force
Install-Module -Name Az -Repository PSGallery -Force
Import-Module -Name Az.Storage
Import-Module Az
Import-Module ImportExcel

# Sign in to your Azure account
Connect-AzAccount

# The subscription ID of where the Storage Account containers are to be created
$subscription = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx"

# Set the subscription where the resources reside
Set-AzContext -Subscription $subscription

# Define the Azure Storage account variables
$storageAccountName = $null # Variable for storage account where the containers will be created
$containerName = $null # Variable to store the container name
$metadataKey = $null # Variable to store metadata key
$metadataValue = $null # Variable to store metadata value

# Read the Containers in Excel spreadsheet
$excelFilePath = "C:\Users\tluk\Documents\Infrastructure Design\"
$excelFileName = "Storage Account Containers.xlsx"
$worksheetName = "TEST" # Change this to the actual name of your worksheet
$storageAccountContainerData = Import-Excel -Path $excelFilePath$excelFileName -WorksheetName $worksheetName

##### Create Containers from Excel #####

foreach ($eachStorageAccountContainer in $storageAccountContainerData) {
    # Read Excel file rows for each column
    $storageAccountName = $eachStorageAccountContainer."Storage Account Name"
    $containerName = $eachStorageAccountContainer."Container Name"
    $metadataKey = $eachStorageAccountContainer."Metadata Key"
    $metadataValue = $eachStorageAccountContainer."Metadata Value"

    # Create a storage context using the account name
    $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName

    # Test to see if the container exists and set $containerExists variable to true or false
    $containerExists = $null
    try {
        Get-AzStorageContainer -name $containerName -Context $storageContext -ErrorAction stop | Out-Null
        # Use the block below to get exception name which will result in: Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException
        # $Error[0].Exception.GetType().FullName
        Write-Host "Container name" $containerName "already exists so skipping creation."
        $containerExists = $true
    }
    catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException] {
        # Write-Host $_.Exception.Message
        $containerExists = $false
    }
    catch {
        Write-Host "Some error has occurred."
        Write-Host $_.Exception.Message 
    }

    if (!$containerExists) {
       
        # Create the container
        $container = New-AzStorageContainer -Name $containerName -Context $storageContext
  
        # Create IDictionary, add key-value metadata pairs to IDictionary
        $metadata = New-Object System.Collections.Generic.Dictionary"[String,String]"
        $metadata.Add($metadataKey, $metadataValue) | Out-Null
  
        # Update metadata
        $container.BlobContainerClient.SetMetadata($metadata, $null) | Out-Null

        Write-Host "Container" $containerName "has been created."
    }
}
