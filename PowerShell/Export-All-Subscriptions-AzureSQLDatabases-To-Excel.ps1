<# 
This PowerShell script will export all of the Azure SQL Databases along with their attributes to an Excel spreadsheet
#>

# Install Excel Module
Install-Module -Name ImportExcel -Scope CurrentUser -Repository PSGallery -Force
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

# Connect to Azure
Connect-AzAccount

<# Export Subscription Azure SQL Databases #>

$subscriptionId = "xxxxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxx" # Update with Subscription ID

# Set the subscription to Dev
Set-AzContext -Subscription $subscriptionId

# Set the path to the Excel file that will store Microsoft Teams User configuration
$path = "C:\Scripts\"
$excelFileName = "AzureSQLDatabasesDev.xlsx" # Update with desired filename
$fullPathAndFile = $path + $excelFileName

# Export MS Teams configuration for every user into Excel file 
$excelFile = Export-Excel -Path $fullPathAndFile

Get-AzResourceGroup | Get-AzSqlServer | Get-AzSqlDatabase | Export-Excel -Path $fullPathAndFile -AutoSize -TableName UserConfig
Write-Host "Exported all database information configuration to $($fullPathAndFile)"