# https://learn.microsoft.com/en-us/rest/api/compute/resource-skus/list?view=rest-compute-2024-03-01&tabs=HTTP
# pip install azure-identity azure-mgmt-compute pandas

'''

This script will have you interactively sign on into Azure with a subscription specified in the script. Then proceed to retrieve all the VM SKUs available
then export to a CSV file named: "Azure-VM-SKU-List.csv"

***Remember to update the subscription_id variable below.

'''

# Replace 'your_subscription_id' with your Azure subscription ID
subscription_id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx'

from azure.identity import InteractiveBrowserCredential
import requests
import pandas as pd

# Interactive login
credential = InteractiveBrowserCredential()

# Get the access token
token = credential.get_token('https://management.azure.com/.default')

# Azure API endpoint
url = "https://management.azure.com/subscriptions/{subscription-id}/providers/Microsoft.Compute/skus?api-version=2021-07-01"

# Replace {subscription-id} with your actual subscription ID
url = url.replace("{subscription-id}", subscription_id)

# Set up the headers for the request
headers = {
    'Authorization': 'Bearer ' + token.token,
}

# Make the GET request
response = requests.get(url, headers=headers)

# Print the response
if response.status_code == 200:
    data = response.json()
    df = pd.json_normalize(data['value'])

    # Filter the DataFrame to only include rows where resourceType is virtualMachines
    df = df[df['resourceType'] == 'virtualMachines']

    df.to_csv('Azure-VM-SKU-List.csv', index=False)
else:
    print(f"Request failed with status code {response.status_code}")
