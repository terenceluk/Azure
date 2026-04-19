# Event Hub

Python scripts for sending and receiving messages from Azure Event Hub, including integration with Log Analytics.

## Contents

### Python (`Python/`)

| File | Description |
|------|-------------|
| `Python/Receive-from-Event-Hub-with-checkpoint-store-async.py` | Async Python script that receives events from an Azure Event Hub using the `azure-eventhub` SDK with checkpoint store support (Azure Blob Storage) for reliable, resumable consumption. |
| `Python/Send-JSON-to-Log-Analytics.py` | Python script that reads events from an Event Hub and forwards them as JSON to an Azure Log Analytics workspace using the HTTP Data Collector API. |
| `Python/Sample-Output-for-Log-Analytics.json` | Sample JSON payload showing the expected format for data ingested into a Log Analytics custom table. |

## Prerequisites

- Python 3.x
- `azure-eventhub`, `azure-eventhub-checkpointstoreblob-aio`, `azure-identity` (install via `pip`)
- Azure Event Hub namespace with a consumer group
- (For Log Analytics ingestion) Log Analytics Workspace ID and Primary Key
