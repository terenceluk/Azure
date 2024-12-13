import azure.functions as func
import logging
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

@app.route(route="setblobmetadatafunc")
def setblobmetadatafunc(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        # Parse request parameters
        req_body = req.get_json()
        storage_account_url = req_body.get('storage_account_url')
        container_name = req_body.get('container_name')
        blob_path = req_body.get('blob_path', "")
        blob_file_name = req_body.get('blob_file_name')

        if not all([storage_account_url, container_name, blob_file_name]):
            return func.HttpResponse(
                "Please pass storage_account_url, container_name, and blob_file_name in the request body",
                status_code=400
            )

        # Construct full blob name, ensuring no double slashes
        if blob_path and not blob_path.endswith('/'):
            blob_path += '/'
        blob_name = f"{blob_path}{blob_file_name}"  # Full path to the blob

        # Determine toplevelfolder
        if blob_path:
            toplevelfolder = blob_path.split('/')[0]
        else:
            toplevelfolder = "root"

        # Remove trailing slash from folderpath for metadata
        folderpath_metadata = blob_path.rstrip('/')

        # Metadata to set
        metadata = {
            "containername": container_name,
            "toplevelfolder": toplevelfolder,
            "folderpath": folderpath_metadata,
            "filename": blob_file_name
        }

        # Add additional metadata from the payload
        for key, value in req_body.items():
            if key not in metadata and key not in ['storage_account_url', 'container_name', 'blob_path', 'blob_file_name']:
                metadata[key] = value

        # Create a credential object using the Azure AD credentials
        credential = DefaultAzureCredential()

        # Authenticate with Azure AD
        blob_service_client = BlobServiceClient(account_url=storage_account_url, credential=credential)

        # Get container client
        container_client = blob_service_client.get_container_client(container_name)

        # Set metadata
        try:
            set_blob_metadata(container_client, blob_name, metadata)
            logging.info(f"Metadata set successfully for blob '{blob_name}'.")

            # Confirm metadata was set
            blob_client = container_client.get_blob_client(blob_name)
            properties = blob_client.get_blob_properties()
            logging.info("Metadata for blob: %s", properties.metadata)

            return func.HttpResponse(
                f"Metadata set successfully for blob '{blob_name}'.",
                status_code=200
            )
        except Exception as e:
            logging.error(f"Failed to set metadata: {e}")
            return func.HttpResponse(
                f"Failed to set metadata: {e}",
                status_code=500
            )

    except Exception as e:
        logging.error(f"Error: {e}")
        return func.HttpResponse(
            f"An error occurred: {e}",
            status_code=500
        )

def set_blob_metadata(container_client, blob_name, metadata):
    # Get blob client
    blob_client = container_client.get_blob_client(blob_name)

    # Check if the blob exists
    try:
        blob_client.get_blob_properties()
        logging.info(f"The blob '{blob_name}' exists.")
    except Exception as e:
        logging.error(f"The blob '{blob_name}' does not exist. Please check the blob name and try again.")
        raise e  # Raise the exception to be caught in the outer function

    # Set metadata
    try:
        blob_client.set_blob_metadata(metadata)
        logging.info(f"Metadata set successfully for blob '{blob_name}'.")
    except Exception as e:
        logging.error(f"Failed to set metadata: {e}")
        raise e  # Raise the exception to be caught in the outer function
