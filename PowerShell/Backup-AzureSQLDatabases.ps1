<# 
This PowerShell script will use the updated spreadsheet exported by the PowerShell Script Export-All-Subscriptions-AzureSQLDatabases-To-Excel.ps1 
to backup all the databases. Note that the reason why the spreadsheet is updated is because an additional Username and Password columns are added
to the spreadsheet so the appropriate credentials can be used to access the database.
#>

# Install Excel Module
Install-Module -Name ImportExcel -Scope CurrentUser -Repository PSGallery -Force
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

# Connect to Azure
Connect-AzAccount

# Set subscription context
$subscriptionId = "aee5068e-f197-46d9-a122-4f11b6f17e80"
Set-AzContext -Subscription $subscriptionId

# Configure variables required for the storage account where the backups of the Azure SQL Database export will be placed
$authenticationType = "sql" # Use SQL authentication
$MyStorageKeytype = "StorageAccessKey" # The options are: StorageAccessKey, SharedAccessKey
$MyStorageKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Obtain the Access Key for the storage account
$BaseStorageUri = "https://sqldatabasebkp.blob.core.windows.net/backups/" # Update with storage account URI

# Set the path to text file containing output
$outputTextFile = "C:\Scripts\AzureSQLDatabaseDevExport.txt" # We wille export the output of each Azure SQL Database export so we can use the OperationStatusLink to check the status

# Set the path to the Excel file that will store Microsoft Teams User configuration
$path = "C:\Scripts\"
$excelFileName = "AzureSQLDatabasesDevTest.xlsx"
$fullPathAndFile = $path + $excelFileName

# Store Excel file in variable
$excelFile = Import-Excel -Path $fullPathAndFile

# GUI Grid View to view the imported Excel in a GUI when troubleshooting
# $excelFile | Out-GridView

# Loop through each record
foreach ($record in ($excelFile))
{
    $mySQLserverAdmin = $record."Username"
    $mySQLserverPassword = $record."Password"
    $mysecurePassword = ConvertTo-SecureString $mySQLserverPassword -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential($mySQLserverAdmin, $mysecurePassword)
    $DBResourceGroupName = $record."ResourceGroupName"
    $DBServerName = $record."ServerName"
    $SQLDatabaseName = $record."DatabaseName"
    $bacpacFilename = $SQLDatabaseName + (Get-Date).ToString("yyyyMMddHHmm") + ".bacpac"
    $BacpacUri = $BaseStorageUri + $bacpacFilename

    $exportRequest = New-AzSqlDatabaseExport -ResourceGroupName $DBResourceGroupName -ServerName $DBServerName `
    -DatabaseName $SQLDatabaseName -StorageKeytype $MyStorageKeytype -StorageKey $MyStorageKey -StorageUri $BacpacUri `
    -AdministratorLogin $credentials.UserName -AdministratorLoginPassword $credentials.Password -AuthenticationType $authenticationType

    $exportRequest >> $outputTextFile
}

<# The following cmdlet is an example of how to view the Azure SQL Database export progress
Get-AzSqlDatabaseImportExportStatus -OperationStatusLink https://management.azure.com/subscriptions/xxxxxxxxxxxxxxxxx/providers/Microsoft.Sql/locations/eastus/importExportOperationResults/
#>

<#
################################## Test Exporting only 1 database ##############################################
$mySQLserverAdmin = "Admin"
$mySQLserverPassword = "abc123P@SSWORD!"
$mysecurePassword = ConvertTo-SecureString $mySQLserverPassword -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($mySQLserverAdmin, $mysecurePassword)
$authenticationType = "sql"
$MyStorageKeytype = "StorageAccessKey" # StorageAccessKey, SharedAccessKey
$MyStorageKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$BaseStorageUri = "https:/sqldatabasebkp.blob.core.windows.net/backups/"

$DBResourceGroupName = "DevResGrp"
    $DBServerName = "devdatabase"
    $SQLDatabaseName = "Db_20172018"
    $bacpacFilename = $SQLDatabaseName + (Get-Date).ToString("yyyyMMddHHmm") + ".bacpac"
    $BacpacUri = $BaseStorageUri + $bacpacFilename

    $exportRequest = New-AzSqlDatabaseExport -ResourceGroupName $DBResourceGroupName -ServerName $DBServerName `
    -DatabaseName $SQLDatabaseName -StorageKeytype $MyStorageKeytype -StorageKey $MyStorageKey -StorageUri $BacpacUri `
    -AdministratorLogin $credentials.UserName -AdministratorLoginPassword $credentials.Password -AuthenticationType $authenticationType


    # Get the status of the export status
    Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink
#>