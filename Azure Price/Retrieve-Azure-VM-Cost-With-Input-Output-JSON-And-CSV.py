# Azure Retail Prices overview
# https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices

'''
This python script prompot for the following values in the console:

1. currencyCode
2. armRegionName
3. armSkuName

Sample of these are:

1. CAD
2. canadaeast
3. Standard_D2_v4 or Standard_E2s_v5

To retrieve the various prices for reservations, consumption, low priority, spot.

Then output it to the console in JSON and export to CSV named "Azure-Single-VM-Price.csv" adding a column for the monthly cost based on 730 hours.

'''

#!/usr/bin/env python3
import requests
import json
import csv

def main(currencyCode, armRegionName, armSkuName):
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

            return json_data
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON: {e}")
    else:
        print(f"Error: {response.status_code}")


if __name__ == "__main__":
    currencyCode = input("Enter the Currency Code: ")
    armRegionName = input("Enter the ARM Region Name: ")
    armSkuName = input("Enter the ARM SKU Name: ")
    data = main(currencyCode, armRegionName, armSkuName)
    print(json.dumps(data, indent=4))

    # Define columns to exclude in the CSV export
    exclude_columns = ['tierMinimumUnits', 'meterName','serviceId','isPrimaryMeterRegion','productId','skuId','meterId']  # Replace with the columns you want to exclude

    # Writing to CSV file
    try:
        with open('Azure-Single-VM-Price.csv', 'w', newline='') as file:
            if data['Items']:
                # Get all possible keys
                all_keys = set().union(*[item.keys() for item in data['Items']])
                # Remove excluded columns
                all_keys = [key for key in all_keys if key not in exclude_columns]
                # Get keys from the first item
                first_item_keys = [key for key in data['Items'][0].keys() if key not in exclude_columns]
                # Insert new column right after "unitPrice"
                first_item_keys.insert(first_item_keys.index('unitPrice') + 1, 'Retail Price (Month @ 730 hours)')
                # Sort all_keys according to the order in first_item_keys
                fieldnames = sorted(all_keys, key=lambda x: first_item_keys.index(x) if x in first_item_keys else len(first_item_keys))
                writer = csv.DictWriter(file, fieldnames=fieldnames)
                writer.writeheader()
                # Remove excluded columns from items and write them to CSV
                items = [{key: item[key] for key in item if key not in exclude_columns} for item in data['Items']]
                writer.writerows(items)
    except PermissionError:
        print("The file 'data.csv' is locked. Please close it and try again.")
