""" 
# Create the following blob_details.json file in the same directory
{
    "storage_account_url": "https://fileuploadtest.blob.core.windows.net/",
    "container_name": "sharepoint",
    "blob_path": "Shared Documents/Root Folder/Folder01/Folder01 A",
    "blob_file_name": "Test01.docx",
    "tag1" : "value1",
    "tag2" : "value2",
    "tag3" : "value3"
} 
"""

# Additional code added to add custom tags

# Install required packages  
# pip install azure-identity azure-storage-blob  
  
import json
from azure.identity import InteractiveBrowserCredential
from azure.storage.blob import BlobServiceClient

# Function to load blob details and tags from a JSON file
def load_blob_details(json_file):
    with open(json_file, 'r') as file:
        details = json.load(file)
    return details

# Function to set metadata
def set_blob_metadata(container_client, blob_name, metadata):
    # Get blob client
    blob_client = container_client.get_blob_client(blob_name)
    
    # Check if the blob exists
    try:
        blob_client.get_blob_properties()
        print(f"The blob '{blob_name}' exists.")
    except Exception as e:
        print(f"The blob '{blob_name}' does not exist. Please check the blob name and try again.")
        return
    
    # Set metadata
    try:
        blob_client.set_blob_metadata(metadata)
        print(f"Metadata set successfully for blob '{blob_name}'.")
        
        # Confirm metadata was set
        properties = blob_client.get_blob_properties()
        print("Metadata for blob:", properties.metadata)
    except Exception as e:
        print(f"Failed to set metadata: {e}")

def main():
    # Load blob details and tags from JSON file
    json_file = 'blob_details.json'
    details = load_blob_details(json_file)
    
    storage_account_url = details["storage_account_url"]
    container_name = details["container_name"]
    blob_path = details.get("blob_path", "")
    blob_file_name = details["blob_file_name"]
    
    # Extract metadata tags
    metadata = {k: v for k, v in details.items() if k not in ["storage_account_url", "container_name", "blob_path", "blob_file_name"]}
    
    # Construct full blob name, ensuring no double slashes
    if blob_path and not blob_path.endswith('/'):
        blob_path += '/'
    blob_name = f"{blob_path}{blob_file_name}"  # Full path to the blob
    
    # Determine toplevelfolder
    if blob_path:
        toplevelfolder = blob_path.split('/')[0]
    else:
        toplevelfolder = "null"
    print(f"Determined toplevelfolder: {toplevelfolder}")  # Debug statement
    
    # Remove trailing slash from folderpath for metadata
    folderpath_metadata = blob_path.rstrip('/')
    print(f"Determined folderpath_metadata: {folderpath_metadata}")  # Debug statement
    
    # Add additional metadata
    metadata.update({
        "containername": container_name,
        "toplevelfolder": toplevelfolder,
        "folderpath": folderpath_metadata,
        "filename": blob_file_name
    })
    
    # Create a credential object using the Azure AD credentials
    credential = InteractiveBrowserCredential()
    
    # Authenticate with Azure AD
    blob_service_client = BlobServiceClient(account_url=storage_account_url, credential=credential)
    
    # Get container client
    container_client = blob_service_client.get_container_client(container_name)
    
    # Set metadata for the specified blob
    set_blob_metadata(container_client, blob_name, metadata)

if __name__ == "__main__":
    main()
