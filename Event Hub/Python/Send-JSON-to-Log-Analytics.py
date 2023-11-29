# The purpose of this Python script is to send a JSON payload to a Data Collection Point and Data Collection Rule
# to ingest the data into a Log Analytics Workspace custom table

from azure.core.exceptions import HttpResponseError
from azure.identity import ClientSecretCredential
from azure.monitor.ingestion.aio import LogsIngestionClient

# Variables for App Registration authentication
AZURE_TENANT_ID="#########-####-####-####-############"
AZURE_CLIENT_ID="#########-####-####-####-############"
AZURE_CLIENT_SECRET="###############################"

# Variables for Data Collection Endpoint and Log Analytics
DATA_COLLECTION_ENDPOINT="https://contoso-dev-apim-dcep-3hal.canadaeast-1.ingest.monitor.azure.com"
LOGS_DCR_RULE_ID="dcr-##################################" # Data Collection Rule "immutableId"
LOGS_DCR_STREAM_NAME="Custom-APIMOpenAILogs_CL" # Data Collection Rule "streamDeclarations"

# Import required modules
from azure.monitor.ingestion import LogsIngestionClient
from azure.core.exceptions import HttpResponseError

print("Getting credential")
 # Configure authentication to App Registration credential object
credential = ClientSecretCredential(tenant_id=AZURE_TENANT_ID,client_id=AZURE_CLIENT_ID,client_secret=AZURE_CLIENT_SECRET)
print("Done getting credential")

print("Creating client for Log Ingestion")
# Configure log ingestion object
client = LogsIngestionClient(endpoint=DATA_COLLECTION_ENDPOINT, credential=credential, logging_enable=True)
print("Done creating client for Log Ingestion")

body = [
        {
    "EventTime": "11/24/2023 8:19:57 PM",
    "ServiceName": "contoso-dev-openai-apim.azure-api.net",
    "RequestId": "91ff7b54-a0eb-4ada-8d27-6081f71e44a3",
    "RequestIp": "74.114.240.15",
    "OperationName": "Creates a completion for the chat message",
    "apikey": "################################",
    "requestbody": {
        "messages": [
            {
                "role": "user",
                "content": "How many sides does a octagon have?"
            }
        ],
        "temperature": 0.7,
        "top_p": 0.95,
        "frequency_penalty": 0,
        "presence_penalty": 0,
        "max_tokens": 800,
        "stop": False
    },
    "JWTToken": "bearer eyJ0eXAiOiJKV1QiLCJhbGci################################################################hMmQtYWU3YS00ZjU3MzJlN2E3OWQiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC84NGY0NDcwYi0zZjFlLTQ4ODktOWY5NS1hYjBmNTE0MzAyNGYvIiwiaWF0IjoxNzAwODU2MzQ4LCJuYmYiOjE3MDA4NTYzNDgsImV4cCI6MTcwMDg2MTMyNSwiYWNyIjoiMSIsImFpbyI6IkFUUUF5LzhWQUFBQUN5NDZNdUg4VG0yWTF3VDkvazZWVjFzcU9oUWZaOFU5N0ExcWRyT0FMYThGcVVsTEhRclN2OVlwNU5hUE94QnMiLCJhbXIiOlsicHdkIl0sImFwcGlkIjoiMTJiY2NjMjYtYjc3OC00YTJkLWFlN2EtNGY1NzMyZTdhNzlkIiwiYXBwaWRhY3IiOiIxIiwiZmFtaWx5X25hbWUiOiJUdXpvIiwiZ2l2ZW5fbmFtZSI6Ilpha2lhIiwiaXBhZGRyIjoiNzQuMTE0LjI0MC4xNSIsIm5hbWUiOiJaYWtpYSBUdXpvIiwib2lkIjoiZWUxMTZkNTktZDQ5Yi00NTU3LWIyYWItYzkxMWY0NTFkNWM4Iiwib25wcmVtX3NpZCI6IlMtMS01LTIxLTIwNTcxOTExOTEtMTA1MDU2ODczNi01MjY2NjAyNjMtMTg0MDAiLCJyaCI6IjAuQVZFQUMwZjBoQjRfaVVpZmxhc1BVVU1DVHliTXZCSjR0eTFLcm5wUFZ6TG5wNTFSQUU0LiIsInJvbGVzIjpbIkFQSU0uQWNjZXNzIl0sInNjcCI6IkFQSS5BY2Nlc3MiLCJzdWIiOiJKR3JLbXB4NjVDOGNqRGxUVXBDZFZKaHFoSmtkelJ6b3lJZURENWRMNUhRIiwidGlkIjoiODRmNDQ3MGItM2YxZS00ODg5LTlmOTUtYWIwZjUxNDMwMjRmIiwidW5pcXVlX25hbWUiOiJaVHV6b0BibWEuYm0iLCJ1cG4iOiJaVHV6b0BibWEuYm0iLCJ1dGkiOiJRRWx2U05CX29rUzFLZnV0NTVFNUFBIiwidmVyIjoiMS4wIn0.a__8D9kLedJi48Q9QuEPWUjhqVWJeTZVXkDIcV-gQ5DYCjU7SjwDQWGc1dsYZ_nD0SH4id-PGiTa3RaZo_y5jrtJs_UoW3L8KmViKF1llqaK5XRw7fbGtdPJsFcDXfcWd-hLlWIorjSZ6MdS4beRx4mPTOfeomFWL6e2ExMBzELe_1MzJaUtbYkfZlhoOQu1TUaIoOM5Qs5PpFO1oO-ihcKu3Vl-aY_rmItB1fzRXIip-LQqUVmOwBjOWrzSVkYWRFGnsO1jZNWp0GJKqzVJJFCqNBgZf4BfjN0vvIXRhsR5dGJqd1AAS8VsczZOSBV2uutixNnjJ3jVIZIOa31wzg",
    "AppId": "########-####-####-####-#############",
    "Oid": "ee116d59-d49b-4557-b2ab-c911f451d5c8",
    "Name": "Terence Luk"
    }
    ]

try:
    print("Start upload")
    client.upload(rule_id=LOGS_DCR_RULE_ID, stream_name=LOGS_DCR_STREAM_NAME, logs=body)
    print("Done upload")
except HttpResponseError as e:
    print(f"Upload failed: {e}")

credential.close() 
