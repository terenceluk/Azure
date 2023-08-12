# Quickstart: Create and update an Azure Firewall policy using Azure PowerShell
# https://learn.microsoft.com/en-us/azure/firewall-manager/create-policy-powershell

Install-Module -Name ImportExcel -Force
Install-Module -Name Az -Repository PSGallery -Force
Import-Module Az
Import-Module ImportExcel

# Sign in to your Azure account
Connect-AzAccount

# Set the subscription where the resources reside
Set-AzContext -Subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"

##### Create Network Rule Collections from Excel #####

# Read the IP Groups in Excel spreadsheet
$excelFilePath = "C:\Users\tluk\Infrastructure Design\NetworkRuleCollections"
$worksheetName = "Collection Group SIT" # Change this to the actual name of your worksheet
$NetworkCollectionGroupData = Import-Excel -Path $excelFilePath -WorksheetName $worksheetName

# Define and store the Firewall Policy Information In Variables
$FirewallPolicyName = "awfp-ca-c-policy-prod" # Azure Firewall Policy Name
$FirewallPolicyRG = "rg-ca-c-vnet-hub-network" # Azure Firewall Policy Resource Group
$RuleCollectionGroupName = "SIT-NetworkRuleCollectionGroup" # Pre-existing Network Rule Collection Group
$RuleCollectionGroupPriority = "400" # Pre-existing Network Rule Collection Group Priority

# Get and store the Azure Firewall Policy object in a variable
$firewallpolicy = Get-AzFirewallPolicy -Name $FirewallPolicyName -ResourceGroupName $FirewallPolicyRG

# Get and store Azure Firewall Policy Collection Group object in a variable
$networkrulecollectiongroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $RuleCollectionGroupName -ResourceGroupName $FirewallPolicyRG -AzureFirewallPolicyName $FirewallPolicyName

foreach ($NetworkCollectionGroup in $NetworkCollectionGroupData) {
    # Begin creating Rule Collection (not group) variable and objects
    $Name = $NetworkCollectionGroup."Name"
    $Priority = $NetworkCollectionGroup."Priority"
    $AllowOrDeny = $NetworkCollectionGroup."Rule Collection Action"

    $newrulecollectionconfig=New-AzFirewallPolicyFilterRuleCollection -Name $Name -Priority $Priority -ActionType $AllowOrDeny
    $newrulecollection = $networkrulecollectiongroup.Properties.RuleCollection.Add($newrulecollectionconfig)

    # Create the Rule Collection under the rule collection group
    Set-AzFirewallPolicyRuleCollectionGroup -Name $RuleCollectionGroupName -Priority $RuleCollectionGroupPriority -FirewallPolicyObject $firewallpolicy -RuleCollection $networkrulecollectiongroup.Properties.RuleCollection
}
