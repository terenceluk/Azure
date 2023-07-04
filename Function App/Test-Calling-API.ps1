$Body = @{
    path = https://storageAccountName.blob.core.windows.net/integration/AD-Report-06-28-2023.json
}

$Parameters = @{
    Method = "POST"
    Uri =  "https://youFunctionName.azurewebsites.net/api/Converter?code=xxxxxxxxxxxxm_Dnc_avHxxxxxxxxxxxxxxDH1A=="
    Body = $Body | ConvertTo-Json
    ContentType = "application/json"
}
Invoke-RestMethod @Parameters | Out-File "C:\Temp\Call-API.html"
