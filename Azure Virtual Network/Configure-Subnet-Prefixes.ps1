# Connect to Azure
Connect-AzAccount

# Set Subscription
Set-AzContext -SubscriptionId xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Use Get-AzVirtualNetwork to retrieve the target virtual network configuration in a variable.
$vnet = Get-AzVirtualNetwork -ResourceGroupName 'Test-VNet-Subnet-RG' -Name 'VNET-192-168-0-0-24'

# Use Set-AzVirtualNetworkSubnetConfig to add a second address prefix to subnet configuration. Specify both the existing and new address prefixes in this step
Set-AzVirtualNetworkSubnetConfig -Name 'SNET-192.168-0-0-29' -VirtualNetwork $vnet -AddressPrefix '192.168.0.0/29', '192.168.0.16/29'

# Use Set-AzVirtualNetwork to apply the updated virtual network configuration.
$vnet | Set-AzVirtualNetwork

# Use Get-AzVirtualNetwork and Get-AzVirtualNetwork to retrieve updated virtual network and subnet configuration. Verify that the subnet now has two address prefixes.
Get-AzVirtualNetwork -ResourceGroupName 'Test-VNet-Subnet-RG' -Name 'VNET-192-168-0-0-24' | `
    Get-AzVirtualNetworkSubnetConfig -Name 'SNET-192.168-0-0-29' | `
    ConvertTo-Json
