<# 
The purpose of this script is to reference the csv file created by this script: https://github.com/terenceluk/Azure/blob/main/PowerShell/Extract-import-tf-file.ps1
then search through the directory provided that will contain the aztfexport files (aztfexportResourceMapping.json, import.tf, main.tf) and update the res-# values 
to the desired values.
#>

# Define the path to the CSV file
$csvFilePath = "C:\Users\tluk\Documents\Terraform\Import-TF.csv"

# Define the directory containing the files to be processed
$filesDirectory = "C:\Users\tluk\Documents\Terraform\Hub"

# Read the CSV file
$csvData = Import-Csv $csvFilePath

# Iterate through each row in the CSV
foreach ($row in $csvData) {
    # Construct the search and replace parameters
    $searchText = $row."Logical TF Name"
    $replaceText = $row."Azure Resource Logical Name"

    # Get all files in the specified directory
    $files = Get-ChildItem -Path $filesDirectory -File

    # Iterate through each file and perform search and replace
    foreach ($file in $files) {
        # Read the content of the file
        $content = Get-Content $file.FullName

        # Perform the search and replace - use regular expressions and the Word Boundary \b to wrap the search term to only match whole words.
        $newContent = $content -replace "\b$searchText\b", $replaceText

        # Write the modified content back to the file
        Set-Content -Path $file.FullName -Value $newContent
    }

    Write-Host "Search and replace for '$searchText' with '$replaceText' completed."
}
