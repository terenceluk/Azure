# Connect to Azure CLI
az login --tenant <tenant_id>
az account set --subscription <subscription_id>

# Export to CSV
az storage account show ^
--name <source_storage_account_name> ^
--resource-group <source_resource_group> ^
--query "networkRuleSet.ipRules[].ipAddressOrRange" ^
--output tsv > storage_account_firewall_rules.csv

# Microsoft Documentation Reference: https://learn.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-show

# Import from CSV (this will add IP addresses and not overwrite)
FOR /F "usebackq tokens=*" %i IN ("C:\users\firewall_rules.csv") DO ^
az storage account network-rule add ^
--account-name <target_storage_account_name> ^
--resource-group <target_resource_group> ^
--ip-address %i

# Microsoft Documentation Reference: https://learn.microsoft.com/en-us/cli/azure/storage/account/network-rule?view=azure-cli-latest#az-storage-account-network-rule-add

# Blog post: https://blog.terenceluk.com/2025/05/issues-with-data-factory-pipelines-using-copy-data-to-query-azure-sql-database-stage-on-adls-and-sink-to-fabric-warehouse.html

# Sample storage account firewall rules for ServiceFabric.CanadaCentral, DataFactory.CanadaCentral, Sql.CanadaCentral
13.71.170.224/29
13.71.170.248/29
20.38.149.192/30
40.85.224.118
52.246.157.8/30
4.174.238.128/27
13.71.175.80/28
20.38.147.224/28
20.48.201.0/26
20.116.47.72/29
52.228.80.128/25
52.228.81.0/26
52.228.86.144/29
52.246.155.224/28
13.71.168.0/27
13.71.168.32/29
13.71.169.0/27
13.71.177.192/27
13.71.178.0/26
20.38.144.0/27
20.38.144.32/29
20.38.145.0/27
20.48.196.32/27
20.48.196.64/27
20.48.196.128/26
20.220.3.0/25
40.85.224.249
52.228.35.221
52.246.152.0/27
52.246.152.32/29
52.246.153.0/27
