# This Python script will process continuously run to listen for events sent to an Event Hub, process each event
# into a JSON array, send each processed event to a Data Collection Endpoint with Data Collection Rule, 
# that will ingest the data into a Log Analytics workspace custom table
#
# Please see the following blog post for more information: https://terenceluk.blogspot.com/2023/11/python-script-that-will-asynchronously.html

import asyncio
import json
from datetime import datetime
from azure.eventhub.aio import EventHubConsumerClient
from azure.eventhub.extensions.checkpointstoreblobaio import BlobCheckpointStore
from azure.core.exceptions import HttpResponseError
from azure.identity.aio import ClientSecretCredential
from azure.monitor.ingestion.aio import LogsIngestionClient

# Define variables for Event Hub
EVENT_HUB_CONNECTION_STR = "Endpoint=sb://contosoapimevhns.servicebus.windows.net/;SharedAccessKeyName=PreviewDataPolicy;SharedAccessKey=#######################;EntityPath=contosoapimevh"
EVENTHUB_NAME = 'contosoapimevh' # Note that I experienced issues having "dashes" or "hyphens" for the event hub when creating an Eventhub trigger for function app
CONSUMER_GROUP = "$Default"

# Define variables for storage account to store checkpoint
STORAGE_CONNECTION_STR = "DefaultEndpointsProtocol=https;AccountName=contosoeventhubcheckpoint;AccountKey=#################/###################################################;EndpointSuffix=core.windows.net"
BLOB_CONTAINER_NAME = "checkpoint"  # Precreated blob container that will store checkpoint files

# Define variables for App Registration authentication
AZURE_TENANT_ID="#########-####-####-####-############"
AZURE_CLIENT_ID="#########-####-####-####-############"
AZURE_CLIENT_SECRET="###############################"

# Define variables for Data Collection Endpoint and Rule to ingest logs into Log Analytics
DATA_COLLECTION_ENDPOINT="https://contoso-dev-apim-dcep-3hal.canadaeast-1.ingest.monitor.azure.com"
LOGS_DCR_RULE_ID="dcr-##################################" # Data Collection Rule "immutableId"
CONSUMER_GROUP = "$Default" # Consumer group for Event Hub
LOGS_DCR_STREAM_NAME="Custom-APIMOpenAILogs_CL" # Data Collection Rule "streamDeclarations"


# Function/Method for ingesting log into Log Analytics
async def send_logs(body):
    print("Start send_logs def function/method - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    # Configure authentication to App Registration credential object
    print("Create client secret object - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    credential = ClientSecretCredential(tenant_id=AZURE_TENANT_ID,client_id=AZURE_CLIENT_ID,client_secret=AZURE_CLIENT_SECRET)
    print("Done creating client secret object - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    # Configure log ingestion object
    print("Create log client object - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    log_client = LogsIngestionClient(endpoint=DATA_COLLECTION_ENDPOINT, credential=credential, logging_enable=True)
    print("Done creating client object - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    try:
        print("Start upload of JSON to Log Analytics - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
        await log_client.upload(rule_id=LOGS_DCR_RULE_ID, stream_name=LOGS_DCR_STREAM_NAME, logs=body)
        print("Done uploading JSON to Log Analytics - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    except HttpResponseError as e:
        print(f"Upload failed: {e}")
    # Close credential and log_client session (this will hang if we forget to do so)
    await credential.close()
    await log_client.close()

# Function/Method for processing each incoming event
async def on_event(partition_context, event):
    '''
    # Print the event data.
    print(
        'Received the event: "{}" from the partition with ID: "{}"'.format(
            event.body_as_str(encoding="UTF-8"), partition_context.partition_id
        )
    )
    '''

    # Load Event Hub data into string
    data = json.loads(event.body_as_str())
    
    # Retrieve and store each column value in a variable to construct JSON for Log Analytics custom table ingestion
    EventTime = data['EventTime']
    ServiceName = data['ServiceName']
    RequestId = data['RequestId']
    RequestIp = data['RequestIp']
    OperationName = data['OperationName']
    apikey = data['apikey']
    requestbody = data['requestbody']
    JWTToken = data['JWTToken']
    AppId = data['AppId']
    Oid = data['Oid']
    Name = data['Name']

    # Create JSON to send into Azure Log Analytics custom table - Replaces the ' with " and adds array bracket []
    event_data_for_log_analytics = [{
        "EventTime": EventTime,
        "ServiceName": ServiceName,
        "RequestId": RequestId,
        "RequestIp": RequestIp,
        "OperationName": OperationName,
        "apikey": apikey,
        "requestbody": requestbody,
        "JWTToken": JWTToken,
        "AppId": AppId,
        "Oid": Oid,
        "Name": Name
    }]
    
    # Print JSON created for Log Analytics data ingestion
    print("----------------------------------------")
    print("The JSON created for Log Analytics ingestion is: ")
    print(event_data_for_log_analytics)
    print("----------------------------------------")
    
    try: 
        # Call send_logs method/function to send the constructed JSON to Log Analytics
        print("Start sending logs to log analytics - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
        await send_logs(event_data_for_log_analytics)
        print("Done sending logs to log analytics - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting

        # Update the checkpoint so that the program doesn't read the events that it has already read when you run it next time.
        print("Start updating checkpoint - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
        await partition_context.update_checkpoint(event)
        print("Done Start updating checkpoint - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    except Exception as e:
        print(f"Error processing event: {e}")

async def main():
    # Create an Azure blob checkpoint store to store the checkpoints.
    print("Create checkpoint store - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    checkpoint_store = BlobCheckpointStore.from_connection_string(
        STORAGE_CONNECTION_STR, BLOB_CONTAINER_NAME
    )
    print("Done Create checkpoint store - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting

    # Create a consumer client for the event hub.
    print("Create Event Hub client store - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    client = EventHubConsumerClient.from_connection_string(
        EVENT_HUB_CONNECTION_STR,
        consumer_group=CONSUMER_GROUP,
        eventhub_name=EVENTHUB_NAME,
        checkpoint_store=checkpoint_store,
    )
    print("Done create Event Hub client store - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    print("Call the receive event - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting

    async with client:
        # Call the receive method. Read from the beginning of the partition (starting_position: "-1")
        await client.receive(on_event=on_event, starting_position="-1")
        print("Done Call the receive event - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting

if __name__ == "__main__":
    print("Looping - " + datetime.now().strftime("%H:%M:%S")) # Output to console for status and troubleshooting
    loop = asyncio.get_event_loop()
    # Run the main method.
    loop.run_until_complete(main())
