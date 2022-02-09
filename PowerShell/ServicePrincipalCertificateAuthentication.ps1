# https://docs.microsoft.com/en-us/powershell/azure/active-directory/signing-in-service-principal?view=azureadps-2.0

# Import AzureAD module with -UseWindowsPowerShell switch for PowerShell 7
Import-Module AzureAD -UseWindowsPowerShell

# Login to Azure AD PowerShell With Admin Account
Connect-AzureAD

# Define variables that will be used to create the certificate and export it
$password = "YourPassword123$" # certificate password
$certDNSname = "EnterpriseApps.contoso.com" # the CN (common name) of the certificate
$certificateLifeInYears = 3
$certificateExportPath = "c:\temp\"
$certificateExportName = "enterpriseAppsCert.pfx"
$certificatePathandName = $certificateExportPath + $certificateExportName
$enterpriseAppName = "Enterprise-Apps-Permissions-PS" # This is the App Registration object that the Enterprise Application created from

# Create the self signed cert on the local Windows machine's Computer Store (Not User Store)
$currentDate = Get-Date
$notAfter = $currentDate.AddYears($certificateLifeInYears)
$thumb = (New-SelfSignedCertificate -CertStoreLocation cert:\localmachine\my -DnsName $certDNSname -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint

### Certificate is now created in the computer's local store

# ^^^ Convert the password to a secure string and export the newly created certificate on the computer's Computer Store to a PFX file
$password = ConvertTo-SecureString -String $password -Force -AsPlainText
Export-PfxCertificate -cert "cert:\localmachine\my\$thumb" -FilePath $certificatePathandName -Password $password

### ^^^ Certificate now exported to the local computer

# Load the certificate into variables
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate($certificatePathandName, $password)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

# Create the Azure Active Directory Application (Azure Active Directory > App Registrations) and upload certificate during creation
$application = New-AzureADApplication -DisplayName $enterpriseAppName # include URL if there is one or omit it -IdentifierUris "https://TestApp"
New-AzureADApplicationKeyCredential -ObjectId $application.ObjectId -CustomKeyIdentifier $enterpriseAppName -StartDate $currentDate -EndDate $notAfter -Type AsymmetricX509Cert -Usage Verify -Value $keyValue

### ^^^ App registrations should now show the newly created application with the certificate uploaded to "Certificates and secrets" so it would allow a client with the
### certificate and its private key to authenticate

# Create the Service Principal (Enterprise Application) and linked to the Application (App Registration)
$sp=New-AzureADServicePrincipal -AppId $application.AppId

### ^^^ Enterprise Applications should now show the newly created application with filter set to "All Applications"

# Give the Service Principal Reader access to the current tenant (Use Get-AzureADDirectoryRole to list the roles - Azure Active Directory > Roles and Administration > Directory readers)
Add-AzureADDirectoryRoleMember -ObjectId (Get-AzureADDirectoryRole | where-object {$_.DisplayName -eq "Directory Readers"}).Objectid -RefObjectId $sp.ObjectId

# Give the Service Principal Reader access to the current tenant (Use Get-AzureADDirectoryRole to list the roles - Azure Active Directory > Roles and Administration > Application administrator)
Add-AzureADDirectoryRoleMember -ObjectId (Get-AzureADDirectoryRole | where-object {$_.DisplayName -eq "Application administrator"}).Objectid -RefObjectId $sp.ObjectId

### ^^^ The Enterprise App (Service Principal) should now be added to the "Application administrator" and "Directory Readers" roles

<# 
We can now test authentication with the Service Principal and the certificate stored on the local computer we have just created
#>

# Get Tenant Detail
$tenant=Get-AzureADTenantDetail

# Now you can login to Azure PowerShell with your Service Principal and Certificate
Connect-AzureAD -TenantId $tenant.ObjectId -ApplicationId  $sp.AppId -CertificateThumbprint $thumb