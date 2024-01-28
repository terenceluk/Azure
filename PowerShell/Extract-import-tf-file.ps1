<# 
The purpose of this script is to take the import.tf file created by the aztfexport tool to extract the fields “id” and “to” into 2 columns, 
then create and addition 2 columns that contain the “res-#” and the next containing the name of the resource in Azure to a CSV.
#>

# Define the path to the input text file
#$inputFilePath = "C:\Path\To\Your\Input\File.txt"
$inputFilePath = "C:\Users\tluk\Documents\Terraform\Hub\import.tf"

# Define the path to the output CSV file
#$outputCsvFilePath = "C:\Path\To\Your\Output\File.csv"
$outputCsvFilePath = "C:\Users\tluk\Documents\Terraform\Import-TF.csv"

# Read the content of the input file
$inputContent = Get-Content $inputFilePath -Raw

# Initialize an array to store the CSV data
$csvData = @()

# Define a regex pattern to extract id and to values
$pattern = 'id\s*=\s*"([^"]+)"\s*to\s*=\s*(\S+)'

# Use regex to match id and to values
$matches = [regex]::Matches($inputContent, $pattern)

# Iterate through each match and extract values
foreach ($match in $matches) {
    $id = $match.Groups[1].Value
    $to = $match.Groups[2].Value
    $toAfterDot = ($to -split '\.')[-1]
    $idAfterLastSlash = ($id -split '/')[-1]

    # Create a hashtable for the CSV row
    $csvRow = @{
        'ID'              = $id
        'To'              = $to
        'Logical TF Name'    = $toAfterDot
        'Azure Resource Logical Name' = $idAfterLastSlash
    }

    # Add the CSV row to the array
    $csvData += New-Object PSObject -Property $csvRow
}

# Export the CSV data to a CSV file
$csvData | Select-Object 'ID', 'To', 'Logical TF Name', 'Azure Resource Logical Name' | Export-Csv -Path $outputCsvFilePath -NoTypeInformation

Write-Host "CSV file created at: $outputCsvFilePath"
