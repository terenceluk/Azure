# Azure Retail Prices overview
# https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices

'''
This python script will read an existing CSV file named "Azure-VM-Input.csv" with the columns:

1. currencyCode
2. armRegionName
3. armSkuName

Sample of these are:

1. CAD
2. canadaeast
3. Standard_D2_v4 or Standard_E2s_v5

To retrieve the various prices for reservations, consumption, low priority, spot.

Then output it to the console in JSON and export to CSV named "Azure-VM-Price-Output.csv" adding a column for the monthly cost based on 730 hours.

'''

# #!/usr/bin/env python3
import requests
import json
import csv

def fetch_data(currencyCode, armRegionName, armSkuName):
    api_url = "https://prices.azure.com/api/retail/prices"
    query = f"armRegionName eq '{armRegionName}' and armSkuName eq '{armSkuName}'"
    params = {
        'currencyCode': currencyCode,
        '$filter': query
    }
    response = requests.get(api_url, params=params)

    if response.status_code == 200:
        try:
            json_data = json.loads(response.text)
            nextPage = json_data['NextPageLink']
    
            while(nextPage):
                response = requests.get(nextPage)
                if response.status_code == 200:
                    additional_data = json.loads(response.text)
                    json_data['Items'].extend(additional_data['Items'])
                    nextPage = additional_data['NextPageLink']
                else:
                    print(f"Error: {response.status_code}")
                    break

            # Add 'Retail Price (Month @ 730 hours)' column
            for item in json_data['Items']:
                if item['type'] == 'Reservation':
                    item['Retail Price (Month @ 730 hours)'] = 'N/A'
                else:
                    item['Retail Price (Month @ 730 hours)'] = item['retailPrice'] * 730

            return json_data['Items']
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON: {e}")
    else:
        print(f"Error: {response.status_code}")

    return []

if __name__ == "__main__":
    input_file = 'Azure-VM-Input.csv'  
    output_file = 'Azure-VM-Price-Output.csv'  

    exclude_columns = ['tierMinimumUnits', 'meterName','serviceId','isPrimaryMeterRegion','productId','skuId','meterId']

    with open(input_file, 'r') as f_in, open(output_file, 'w', newline='') as f_out:
        reader = csv.DictReader(f_in)
        writer = None

        for row in reader:
            data = fetch_data(row['currencyCode'], row['armRegionName'], row['armSkuName'])
            if data:
                if writer is None:
                    all_keys = set().union(*[item.keys() for item in data])
                    all_keys = [key for key in all_keys if key not in exclude_columns]
                    first_item_keys = [key for key in data[0].keys() if key not in exclude_columns]
                    first_item_keys.insert(first_item_keys.index('unitPrice') + 1, 'Retail Price (Month @ 730 hours)')
                    fieldnames = sorted(all_keys, key=lambda x: first_item_keys.index(x) if x in first_item_keys else len(first_item_keys))
                    writer = csv.DictWriter(f_out, fieldnames=fieldnames)
                    writer.writeheader()

                items = [{key: item[key] for key in item if key not in exclude_columns} for item in data]
                writer.writerows(items)
