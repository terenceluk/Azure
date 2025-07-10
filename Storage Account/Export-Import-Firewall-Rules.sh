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
