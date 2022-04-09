<#
The purpose of this script is to add the Windows Event Logs located in: 
Log Analytics Workspace > Agents configuration > Windows event logs
The script will create an array with Windows Event Log names and then iterate through the array to add each log to Log Analytics 

The Windows Event Logs included in this script are provided by Microsoft as a baseline for monitoring Azure Virtual Desktop virtual machines (https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/wvd/eslz-management-and-monitoring)
To add an additional log, create an additional $EventLogNames variable containing the log path.
#>

# Connect to Azure

Connect-AzAccount

# Declare variables to store the resource group name containing the Log Analytics Workspace and the Log Analytics Workspace name

$ResourceGroupName   = 'rg-prod-analytics'
$WorkspaceName       = 'lg-prod-analytics'

# Define the event log name for each log and store it into an array

$EventLogNames       = @()
$EventLogNames      += 'Application'
$EventLogNames      += 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
$EventLogNames      += 'Microsoft-FSLogix-Apps/Operational'
$EventLogNames      += 'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin'
$EventLogNames      += 'Microsoft-FSLogix-Apps/Admin'
$EventLogNames      += 'Microsoft-Windows-GroupPolicy/Operational'

# Use the array of event log paths created above to create each Windows Event Log, then add a logical name Windows-event- with an incrementing number

$Count = 0
foreach ($EventLogName in $EventLogNames) {
    $Count++
    $null = New-AzOperationalInsightsWindowsEventDataSource `
    -ResourceGroupName $ResourceGroupName `
    -WorkspaceName $WorkspaceName `
    -Name "Windows-event-$($Count)" `
    -EventLogName $EventLogName `
    -CollectErrors `
    -CollectWarnings `
    -CollectInformation
}

<# Use the following cmdlet to list all the Windows Performance Counters that were created
Get-AzOperationalInsightsDataSource `
   -ResourceGroupName $ResourceGroupName `
   -WorkspaceName $WorkspaceName `
   -Kind 'WindowsEvent'
#>