# Install all prerequisite modules
Install-Module -Name ImportExcel -Force
Install-Module -Name Az -Repository PSGallery -Force
Import-Module Az
Import-Module ImportExcel

# Sign in to Azure account and select the subscription
Connect-AzAccount
$subscriptionID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxx"
Set-AzContext -SubscriptionId $SubscriptionID

##### Create Route Tables from Excel #####

# Read the route tables in Excel spreadsheet
$excelFilePath = "C:\Users\tluk\RouteTables-UDRs.xlsx"
$worksheetName = "dev-routes" # Worksheet name
$routeData = Import-Excel -Path $excelFilePath -WorksheetName $worksheetName

# Loop through each record and create the route table
foreach ($route in $routeData) {
    $RouteName = $route."Route Name"
    $ResourceGroup = $route."Resource Group"
    $Location = $route."Location"

    New-AzRouteTable `
    -Name $RouteName `
    -ResourceGroupName $ResourceGroup `
    -location $Location
}

##### Add UDRs to Route Table from Excel #####

## With the Route Tables created, proceed to create UDRs in there
## This is broken into another section in case we want to test creating the tables first rather than placing UDRs into a sub loop and immediately adding the UDRs to the tables
## We can run the above code first, confirm Route Tables creation, then run the code below to create UDRs

# Read the UDRs in Excel spreadsheet
$excelFilePath = "C:\Users\tluk\RouteTables-UDRs.xlsx"
$worksheetName = "dev-udrs" # Worksheet name
$udrData = Import-Excel -Path $excelFilePath -WorksheetName $worksheetName

# Start looping through each Route Table that was created earlier

foreach ($route in $routeData) {
    $routeTableName = $route."Route Name"
    $resourceGroupName = $route."Resource Group"

    # Get and store the Route Table object
    $routeTable = Get-AzRouteTable -Name $routeTableName -ResourceGroupName $resourceGroupName

    # Loop through UDRs and create them in each Route Table
    foreach ($udr in $udrData) {

        $UDRName = $udr."UDRName"
        $AddressPrefix = $udr."AddressPrefix"
        # Need to trim the white space between "Virtual Appliance" because the -NextHopType expects one word with no space
        $NextHopType = $udr."NextHopType" -replace '\s'
        $NextHopIpAddress = $udr."NextHopIpAddress"
    
        # Skip any UDRs for the route table's subnet so we don't end up routing the same subnet traffic to the firewall
        # Take the Route Table name and replace the prefix with UDR prefix to see if this is the route we want to omit
        $RouteTableNameMod = $RouteTableName.replace("rt-ca-c","udr-ca-c")

        # Only execute if the route table and UDR names do not match
        If ($RouteTableNameMod -ne $UDRName) {
            $routeTable 
            | Add-AzRouteConfig `
            -Name $UDRName `
            -AddressPrefix $AddressPrefix `
            -NextHopType $NextHopType `
            -NextHopIpAddress $NextHopIpAddress `
            | Set-AzRouteTable
        }
    }
}
