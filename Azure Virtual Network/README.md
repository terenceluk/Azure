# Azure Virtual Network

Scripts for managing Azure Virtual Network subnets and related networking configuration.

## Contents

| File | Description |
|------|-------------|
| `Configure-Subnet-Prefixes.ps1` | PowerShell script that configures or updates address prefixes on subnets within an Azure Virtual Network. Useful for bulk subnet reconfiguration or applying a standard addressing scheme across a VNet. |

## Prerequisites

- Azure PowerShell (`Az` module) with `Az.Network`
- Network Contributor or higher permissions on the target Virtual Network
