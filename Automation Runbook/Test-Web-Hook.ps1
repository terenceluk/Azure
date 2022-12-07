$uri = 'https://d36f1e53-eabe-4b85-82d1-4710b90d5b52.webhook.eus.azure-automation.net/webhooks?token=x1WEKX%2f%2bL%2f%2fz2pX%2fBcJx3UqNii7GTU3T8lxAVIhA0PU%3d'
$headerMessage = @{ message = "Testing Webhook"}
$data = @(
    @{ samAccountName="jsmith"},
    @{ email = "jsmith@contoso.com"},
    @{ fullname = "John Smith"},
    @{ mobile = "+14165553445"}
)
$body = ConvertTo-Json -InputObject $data
$response = Invoke-Webrequest -method Post -uri $uri -header $headerMessage -Body $body -UseBasicParsing 
$response
