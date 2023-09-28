# Input bindings are passed in via param block.
param($Timer)

Install-Module Az.ResourceGraph
Get-Module -Name Az.ResourceGraph -ListAvailable | Select-Object Name, Version
Import-Module Az.ResourceGraph
Search-AzGraph -Query $query

# Add the Azure Subscription Ids that this script should read and execute on
$subscriptionids = @"
[
"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
]
"@ | ConvertFrom-Json

# The following defines the variable to store the date and retrieves the current date/time in the desired timezone (the default is UTC)
# It is important to specify the correct timezone so the virtual machines will start/stop at the expected time
# The following Microsoft article provides the available timezones:
# https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones?view=windows-11#time-zones
# Use the value in the "Timezone" column for the passed string
$date = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now, "Eastern Standard Time")

## Use this line to test with date variable defined ##
# $date = [DateTime] "09/30/2023 9:00 AM"

$autoOnOffquery = @"
resources
| where type == "microsoft.compute/virtualmachines" 
and (isnotnull(tags['WD-AutoStart'])
and isnotnull(tags['WD-AutoDeallocate']))
or (isnotnull(tags['WE-AutoStart'])
and isnotnull(tags['WE-AutoDeallocate']))
or isnotnull(tags['Weekend'])
| extend ['Weekday AutoStart'] = tags['WD-AutoStart'], ['Weekday AutoDeallocate'] = tags['WD-AutoDeallocate'],['Weekend AutoStart'] = tags['WE-AutoStart'], ['Weekend AutoDeallocate'] = tags['WE-AutoDeallocate'],['Weekend'] = tags['Weekend'],['Status'] = properties.extended.instanceView.powerState.displayStatus,['Resource Group'] = resourceGroup
| project name,['Weekday AutoStart'],['Weekday AutoDeallocate'],['Weekend AutoStart'],['Weekend AutoDeallocate'],['Weekend'],Status,['Resource Group']
"@

foreach ($subscriptionId in $subscriptionIds) {
    # Set the current subscription to this iteration of the subscription
    Set-AzContext -SubscriptionId $SubscriptionID | Out-Null

    $currentSubscription = (Get-AzContext).Subscription.Id
    If ($currentSubscription -ne $SubscriptionID) {
        # Throw an error if switching to subscription fails
        Throw "Could not switch to the SubscriptionID: $SubscriptionID. Please check the permissions to the subscription and/or make sure the ID is correct."
    }

    # Fix single digit hour not having 2 digits (e.g. 08:50 = 8:50)
    If ($date.hour.length -eq 1) {
        $fixedHour = ([string]$date.hour).PadLeft(2, '0')
    }
    else {
        $fixedhour = $date.hour
    }

    # Fix single digit minute not having 2 digits (e.g. 12:05 = 12:5)
    If ($date.minute.length -eq 1) {
        $fixedMinute = ([string]$date.minute).PadLeft(2, '0')
    }
    else {
        $fixedMinute = $date.minute
    }

    # Set the $timeNow variable to today's date's HH:MM
    $timeNow = [string] $fixedHour + ":" + $fixedMinute

    # Determine whether today is a weekday
    $todayIsAweekday = (Get-Date).DayOfWeek.value__ -le 6

    ## Use this to test as if today was a weekend ##
    # $todayIsAweekday = $false

    # Fetch VMs with auto on and off schedule
    $virtualMachines = Search-AzGraph -Query $autoOnOffquery
    
    # Print out collects VMs in a table
    $virtualmachines | Format-Table
    foreach ($vm in $virtualMachines) {
        # Check to see if VM is running and handle VMs that may need to be deallocated
        if (($vm.Status -eq 'VM running')) {
            # Start processing whether VM should be powered off
            If ($todayIsAweekday) {
                If ($null -ne $vm.'Weekday AutoStart' -and $null -ne $vm.'Weekday AutoDeallocate') {
                    If ($timeNow -ge $vm.'Weekday AutoDeallocate' -or $timeNow -lt $vm.'Weekday AutoStart') {
                        Write-Host $vm.Name "should only be powered on between"$vm.'Weekday AutoStart'"and"$vm.'Weekday AutoDeallocate'"during Mon-Fri. Shutting down VM."
                        Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.'Resource Group' -Confirm:$false -NoWait -Force
                    }
                }
            } 
            else {
                # Today is a weekend
                # Handle VM that is supposed to be on over the weekend but needs to be powered off between start and deallocate time 
                If (($null -ne $vm.'Weekend AutoStart' -and $null -ne $vm.'Weekend AutoDeallocate') -and $vm.'Weekend' -ne "Off") {
                    If ($timeNow -ge $vm.'Weekend AutoDeallocate' -or $timeNow -lt $vm.'Weekend Autostart') {
                        Write-Host $vm.Name "should only be powered on between"$vm.'Weekend AutoStart'"and"$vm.'Weekend AutoDeallocate'"during Sat-Sun. Shutting down VM."
                        Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.'Resource Group' -Confirm:$false -NoWait -Force
                    }
                }
                # Handle VM that is supposed to be off over the weekend (ignores defined start and deallocate time)
                If ($vm.'Weekend' -eq "Off") {
                    Write-Host $vm.Name " should be powered off over the weekend. Shutting down VM."
                    Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.'Resource Group' -Confirm:$false -NoWait -Force
                }
            }
        }
        # Check to see if VM is deallocated and handle VMs that may need to be started
        elseif (($vm.Status -eq 'VM deallocated')) {
            # Start processing whether VM should be powered on
            If ($todayIsAweekday) {
                If ($null -ne $vm.'Weekday AutoStart' -and $null -ne $vm.'Weekday AutoDeallocate') {
                    If (($timeNow -ge $vm.'Weekday AutoStart') -and ($timeNow -le $vm.'Weekday AutoDeallocate')) {
                        Write-Host $vm.Name "should only be powered off outside of"$vm.'Weekday AutoStart'"and"$vm.'Weekday AutoDeallocate'"during Mon-Fri. Powering on VM."
                        Start-AzVM -Name $vm.Name -ResourceGroupName $vm.'Resource Group' -Confirm:$false -NoWait
                    }
                }
            } 
            else {
                # Today is a weekend
                # Handle VM that is supposed to be on over the weekend but needs to be powered off between start and deallocate time 
                If (($null -ne $vm.'Weekend AutoStart' -and $null -ne $vm.'Weekend AutoDeallocate') -and ($vm.'Weekend' -ne "On" -or $null -eq $vm.'Weekend')) {
                    If (($timeNow -ge $vm.'Weekend AutoStart') -and ($timeNow -le $vm.'Weekend AutoDeallocate')) {
                        Write-Host $vm.Name "should only be powered off outside of"$vm.'Weekend AutoStart'"and"$vm.'Weekend AutoDeallocate'"during Sat-Sun. Powering on VM."
                        Start-AzVM -Name $vm.Name -ResourceGroupName $vm.'Resource Group' -Confirm:$false -NoWait
                    }
                }
                # Handle VMs that are supposed to be turned off during the week but not the weekend (Weekday AutoStart and AutoDeallocate is set which turns server off on Friday evening so we need to turn it back on for Saturday)
                If (($null -ne $vm.'Weekday AutoStart' -and $null -ne $vm.'Weekday AutoDeallocate') -and ($vm.'Weekend' -ne "Off" -or $null -eq $vm.'Weekend')) {
                    Write-Host $vm.Name "should only be powered off outside of"$vm.'Weekday AutoStart'"and"$vm.'Weekday AutoDeallocate'"during Mon-Fri. Today is on a weekend. Powering on VM."
                    Start-AzVM -Name $vm.Name -ResourceGroupName $vm.'Resource Group' -Confirm:$false -NoWait
                }
            }
        }
    }
}
