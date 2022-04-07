<#
The purpose of this script is to create the Windows Performance Counters located in: 
Log Analytics Workspace > Agents configuration > Windows performance counters
The script will create an array with objects that store the performance counter's ObjectName, CounterName, InstanceName and the desired IntervalSecond. An 
additional logical name is also required to create the counter so a WinPerfCount- with a number appended to it will be used for it.

The performance counters included in this script are provided by Microsoft as a baseline for monitoring Azure Virtual Desktop virtual machines (https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/wvd/eslz-management-and-monitoring)
To add an additional counter, create an additional $ObjectNames, $CounterNames, $InstanceNames and $IntervalSeconds variable representing the counter.
#>

# Connect to Azure

Connect-AzAccount

# Declare variables to store the resource group name containing the Log Analytics Workspace and the Log Analytics Workspace name

$ResourceGroupName   = 'rg-prod-analytics'
$WorkspaceName       = 'lg-prod-analytics'

# Define the ObjectName for each counter

$ObjectNames = @()
$ObjectNames += 'LogicalDisk'
$ObjectNames += 'PhysicalDisk'
$ObjectNames += 'PhysicalDisk'
$ObjectNames += 'PhysicalDisk'
$ObjectNames += 'Processor Information'
$ObjectNames += 'Terminal Services'
$ObjectNames += 'LogicalDisk'
$ObjectNames += 'Terminal Services'
$ObjectNames += 'Terminal Services'
$ObjectNames += 'User Input Delay per Process'
$ObjectNames += 'User Input Delay per Session'
$ObjectNames += 'RemoteFX Network'
$ObjectNames += 'RemoteFX Network'
$ObjectNames += 'LogicalDisk'
$ObjectNames += 'LogicalDisk'
$ObjectNames += 'Memory'
$ObjectNames += 'Memory'
$ObjectNames += 'Memory'
$ObjectNames += 'Memory'
$ObjectNames += 'PhysicalDisk'
$ObjectNames += 'Process'
$ObjectNames += 'Processor Information'

# Define the CounterName of the ObjectName for each counter in the same order as the list above

$CounterNames = @()
$CounterNames += '% Free Space'
$CounterNames += 'Avg. Disk sec/Read'
$CounterNames += 'Avg. Disk sec/Transfer'
$CounterNames += 'Avg. Disk sec/Write'
$CounterNames += '% Processor Time'
$CounterNames += 'Active Sessions'
$CounterNames += 'Avg. Disk Queue Length'
$CounterNames += 'Inactive Sessions'
$CounterNames += 'Total Sessions'
$CounterNames += 'Max Input Delay'
$CounterNames += 'Max Input Delay'
$CounterNames += 'Current TCP RTT'
$CounterNames += 'Current UDP Bandwidth'
$CounterNames += 'Avg. Disk sec/Transfer'
$CounterNames += 'Current Disk Queue Length'
$CounterNames += 'Available MB'
$CounterNames += 'Page Faults/sec'
$CounterNames += 'Pages/sec'
$CounterNames += '% Committed Bytes In Use'
$CounterNames += 'Avg. Disk Queue Length'
$CounterNames += '% User Time' # Required for Processor utilization per user query
$CounterNames += '% Processor Time' 

# Define the InstanceName of the ObjectName for each counter in the same order as the list above

$InstanceNames = @()
$InstanceNames += 'C:'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '_Total'
$InstanceNames += '*'
$InstanceNames += 'C:'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += 'C:'
$InstanceNames += 'C:'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'
$InstanceNames += '*'

# Define the IntervalSecond of the ObjectName for each counter in the same order as the list above

$IntervalSeconds = @()
$IntervalSeconds += 60
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 60
$IntervalSeconds += 30
$IntervalSeconds += 60
$IntervalSeconds += 60
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 60
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 30
$IntervalSeconds += 60
$IntervalSeconds += 30

# Create an array containing objects that store the attributes of each Windows Performance Counter

$Count = 0
$WindowsPerformanceCounters = @()
$WindowsPerformanceCounters = @(
    foreach ($ObjectName in $ObjectNames) {
        [pscustomobject]@{ObjectName=$ObjectNames[$count];InstanceName=$InstanceNames[$count];CounterName=$CounterNames[$count];IntervalSecond=$IntervalSeconds[$count]}
        $Count++
    }
    ) 
    
# Use the array of objects created above to create each Windows Performance Counter by obtaining each attribute, then add a logical name WinPerfCount- with an incrementing number

$Count = 0
foreach ($WindowsPerformanceCounter in $WindowsPerformanceCounters) {
    $null = New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
    -ResourceGroupName $ResourceGroupName `
    -WorkspaceName $WorkspaceName `
    -ObjectName $WindowsPerformanceCounters[$count].ObjectName `
    -InstanceName $WindowsPerformanceCounters[$count].InstanceName `
    -CounterName $WindowsPerformanceCounters[$count].CounterName `
    -IntervalSecond $WindowsPerformanceCounters[$count].IntervalSecond `
    -Name "WinPerfCount-$($Count)"
    $Count++
}

<# Use the following cmdlet to list all the Windows Performance Counters that were created
Get-AzOperationalInsightsDataSource `
   -ResourceGroupName $ResourceGroupName `
   -WorkspaceName $WorkspaceName `
   -Kind 'WindowsPerformanceCounter'
#>