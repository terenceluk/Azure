# Private DNS Zones

Scripts and configuration for comparing Azure Private DNS zones between tenants, useful for disaster recovery validation and environment synchronization.

## Contents

### Compare DNS Zones (`Compare DNS Zones/`)

| File | Description |
|------|-------------|
| `Compare-DNSZones.ps1` | Comprehensive PowerShell script that compares Private DNS zone records between two Azure tenants (e.g., Production vs. DR). Authenticates to each tenant using Service Principal credentials, supports zone filtering (include/exclude lists), and outputs results in multiple formats: Console, HTML, CSV, or JSON. Optionally sends results by email. |
| `config.json` | Sample configuration file for `Compare-DNSZones.ps1`. Defines tenant connection details (TenantId, SubscriptionId, ClientId, ClientSecret) for both tenants and a `ZoneMappings` array specifying DNS zones and their resource groups in each tenant. |

## Supported DNS Zones (sample config)

- `privatelink.blob.core.windows.net`
- `privatelink.postgres.database.azure.com`
- `privatelink.vaultcore.azure.net`

## Prerequisites

- Azure PowerShell modules: `Az.Accounts`, `Az.PrivateDns`
- Service Principal credentials with `Private DNS Zone Contributor` or `Reader` role on both tenants' DNS zones
- Update `config.json` with your own tenant and subscription details before running
