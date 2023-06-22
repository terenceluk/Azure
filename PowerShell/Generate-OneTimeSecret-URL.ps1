<# 
The purpose of this script is to create and return a Onetimesecret URL with a secret that can only be viewed once.

Refer to my blog post for more information: http://terenceluk.blogspot.com/2023/06/powershell-script-that-will-use.html

API Documentation: https://onetimesecret.com/docs/api
#>

param(
     [Parameter(Mandatory=$true)]
     [string]$suppliedPassword
)

$password = $suppliedPassword

### Create a secret ###

# Onetimesecret authentication
$onetimesecretUsername = "tluk@contoso.com"
$onetimesecretAPIkey = "5f9af351asewrewaasd90abddadfasdfa6042adsfasdfafds3743"

# Create authentication credentials to be passed
$base64Authentication = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $onetimesecretUsername,$onetimesecretAPIkey)))

$Parameters = @{
    Method = "POST"
    Uri =  "https://onetimesecret.com/api/v1/share"
    Headers = @{
        Authorization = ("Basic {0}" -f $base64Authentication)
    }
    # Set secret time to Live in seconds (7 days)
    Body = @{
        secret = $password
        ttl = 604800
    }
}

# Call the OneTimeSecret API to create a provided password
$oneTimeSecret = Invoke-RestMethod @Parameters

# secret_key is the unique string added to https://onetimesecret.com/secret/ for accessing the secret
Return "https://onetimesecret.com/secret/$($oneTimeSecret.secret_key)"
