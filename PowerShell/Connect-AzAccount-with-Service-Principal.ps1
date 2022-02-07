<# Begin by creating the service principal and client secret #>

# Connect-AzAccount - https://docs.microsoft.com/en-us/powershell/module/az.accounts/connect-azaccount?view=azps-7.1.0
# Sign in with a service principal - https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps?view=azps-7.1.0#sign-in-with-a-service-principal

# Connect to Azure with an authenticated account for use with cmdlets from the Az PowerShell modules
Connect-AzAccount

# Set the variables (name and password) for creating the App Registration and Enterprise Application that will be named "TestApp"

$spName = "TestApp"
$spPassword = "ChM7Q~fbYA934Q.nFxihDrSfBov3vqhh4g5OG"
$passwordLifeInYears = 3

# Use the $spPassword variable containing the password to create an object that is used to create a secret in the TestApp App Registration
# The object will also specify when the date of this secret will expire and that is today's Month and Date in 3 years
$credentials = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential `
               -Property @{StartDate=Get-Date; EndDate=Get-Date -Year (Get-Date).AddYears($passwordLifeInYears).year; Password=$spPassword};
$spConfig = @{
              DisplayName = $spName
              PasswordCredential = $credentials
             }

# Create the App Registration with a client secret configured and Enterprise Application (Service Principal) named test app
$servicePrincipal = New-AzAdServicePrincipal @spConfig

##############################################################################################################

<# Try connecting with the newly created Service Principal (Enterprise Application) named TestApp with a secret configured #>

# Define the variables required to connect
$tenantId = "84xxxxx0b-xxxx-xxxx-xxxx-ab0xxxxx24x"
$spPassword = "ChM7Q~fbYA934Q.nFxihDrSfBov3vqhh4g5OG"
$servicePrincipalAppID = "b27b779c-02ab-4911-aab9-4a4f43a4be45" # This is the Application ID of the Enterprise App

# Convert the Service Principal secret to secure string
$password = ConvertTo-SecureString $spPassword -AsPlainText -Force

# Create a new credentials object containing the application ID and password that will be used to authenticate
$psCredentials = New-Object System.Management.Automation.PSCredential ($servicePrincipalAppID, $password)

# Authenticate with the credentials object
Connect-AzAccount -ServicePrincipal -Credential $psCredentials -Tenant $tenantId