# Install required packages  
# pip install azure-identity azure-storage-blob  
  
from azure.identity import InteractiveBrowserCredential  
from azure.storage.blob import BlobServiceClient  
  
# Blob details  
storage_account_url = "https://fileuploadtest.blob.core.windows.net/"  
container_name = "sharepoint"  
#blob_path = "Shared Documents/Root Folder/Folder01/Folder01 A"  # Path to the blob  
#blob_file_name = "Test01.docx"  # Blob file name  

blob_path = ""  # Path to the blob, empty for root  
blob_file_name = "New Doc.txt"  # Blob file name  
  
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
  
# Metadata to set  
metadata = {  
    "containername": container_name,  
    "toplevelfolder": toplevelfolder,  
    "folderpath": folderpath_metadata,  
    "filename": blob_file_name  
}  
  
# Create a credential object using the Azure AD credentials  
credential = InteractiveBrowserCredential()  
  
# Authenticate with Azure AD  
blob_service_client = BlobServiceClient(account_url=storage_account_url, credential=credential)  
  
# Get container client  
container_client = blob_service_client.get_container_client(container_name)  
  
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
  
# List blobs in the container to ensure the blob exists (commented out for faster execution)  
# print("Listing blobs in the container:")  
# blobs_list = container_client.list_blobs()  
# for blob in blobs_list:  
#     print(f"Blob name: {blob.name}")  
  
# Set metadata for the specified blob  
set_blob_metadata(container_client, blob_name, metadata)  
