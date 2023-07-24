Install-Module -Name ImportExcel -Force
Install-Module -Name Az -Repository PSGallery -Force
Import-Module Az
Import-Module ImportExcel

# Sign in to your Azure account
Connect-AzAccount

##### Create IP Groups from Excel #####

# Read the IP Groups in Excel spreadsheet
$excelFilePath = "C:\Users\tluk\Infrastructure Design\IPGroups.xlsx"
$worksheetName = "dev-ipgroups" # Change this to the actual name of your worksheet
$IPGroupData = Import-Excel -Path $excelFilePath -WorksheetName $worksheetName

foreach ($IPGroup in $IPGroupData) {
    $ipGroup = @{
        Name              = $IPGroup."Name"
        ResourceGroupName = $IPGroup."Resource Group"
        Location          = $IPGroup."Location"
        IpAddress         = $IPGroup."IPAddress"
    }

    New-AzIpGroup @ipGroup
}
