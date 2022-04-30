foreach ( $azVM in Get-AzVM ) {

    $networkProfile = $azVm.NetworkProfile.NetworkInterfaces.id.Split("/")|Select -Last 1
    $vmName = $azVm.OsProfile.ComputerName
    $rgName = $azVm.ResourceGroupName
    #$tags = $azVM.Tags  
    $hostname = (Get-AzVM -ResourceGroupName $rgName -Name $azVm.OsProfile.ComputerName -status).computername  
    $IPConfig = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PrivateIpAddress  
    
    [pscustomobject]@{  
    Name = $azVm.OsProfile.ComputerName 
    ComputerName = $hostname  
    "IP Addresses" = $IPConfig
    
    #Tags = $tags
    "Az Name Match Host Name" = $azVm.OsProfile.ComputerName.equals($hostname)
    }
}