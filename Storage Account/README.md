# Storage Account

Scripts for managing Azure Storage Account firewall rules and blob metadata, using Azure CLI, Python, and the Azure Blob Storage SDK.

## Contents

| File | Description |
|------|-------------|
| `Export-Import-Firewall-Rules.sh` | Azure CLI Bash script that exports Storage Account IP firewall rules to a CSV file and imports them into another Storage Account. Includes example IP ranges for Azure service tags (`ServiceFabric.CanadaCentral`, `DataFactory.CanadaCentral`, `Sql.CanadaCentral`). |
| `Set-Blob-Metadata.py` | Python script that sets standard metadata fields (`containername`, `toplevelfolder`, `folderpath`, `filename`) on a specific Azure Blob using `InteractiveBrowserCredential` for authentication. |
| `Set-Blob-Metadata_v2.py` | Extended version that reads blob details and arbitrary custom tags from a `blob_details.json` file (e.g., `tag1`, `tag2`, `tag3`) and merges them into the blob's metadata. |

## Prerequisites

- **Shell script**: Azure CLI, Bash (or WSL/Git Bash on Windows)
- **Python scripts**: Python 3.x, `azure-storage-blob`, `azure-identity` (`pip install azure-storage-blob azure-identity`)
- Appropriate Azure RBAC role: **Storage Blob Data Contributor** on the target container
