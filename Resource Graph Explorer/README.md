# Resource Graph Explorer

KQL queries for Azure Resource Graph Explorer to search and analyze Virtual Networks, subnets, and CIDR ranges across subscriptions.

## Contents

| File | Description |
|------|-------------|
| `Retrieve-VNets-and-Subnets.kql` | Retrieves all VNets and their subnets. Handles both `addressPrefix` (single string) and `addressPrefixes` (array) subnet schema variants, returning each subnet as its own row. |
| `Search-for-Subnet-With-Specified-CIDR.kql` | Finds the VNet and subnet that exactly match a specified CIDR block (e.g., `10.224.20.16/28`). |
| `Search-for-Subnet-With-Specified-IP-Address.kql` | Identifies which VNet and subnet a specific IP address belongs to using `ipv4_is_in_range`. |
| `Search-for-VNet-Details-With-Specified-VNet-Name.kql` | Returns all subnets of a named VNet, including associated NSG and route table details. |
| `Search-for-VNet-Subnet-Details-With-Specified-Subnet-Name.kql` | Finds all VNets that contain a subnet matching a specified name, returning address space and prefix details. |
| `Search-for-VNet-Subnet-Details-With-Specified-VNet-and-Subnet-Name.kql` | Locates a specific VNet+Subnet combination (using `vnetName/subnetName` input format) and returns address details, NSG, and route table. |
| `Search-for-VNet-With-Specified-CIDR.kql` | Finds all VNets whose address space contains a specified CIDR, expanding and listing their subnets. |

## Usage

Run these queries in [Azure Resource Graph Explorer](https://portal.azure.com/#view/HubsExtension/ArgQueryBlade) in the Azure Portal, or via:

```bash
az graph query -q "$(Get-Content .\Search-for-Subnet-With-Specified-IP-Address.kql -Raw)"
```

Update IP addresses, CIDR blocks, or VNet/subnet names within each query before running.
