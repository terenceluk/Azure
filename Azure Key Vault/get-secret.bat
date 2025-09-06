:: =============================================================================
:: EXAMPLE CONFIGURATION
:: =============================================================================
:: All defaults
:: get-secret.bat

:: Different key vault only
:: get-secret.bat production-vault
:: get-secret.bat https://prod-vault.vault.azure.net

:: Different key vault and secret
:: get-secret.bat production-vault DatabasePassword
:: get-secret.bat test-vault ApiKey

:: Different key vault, secret, and tenant
:: get-secret.bat production-vault DatabasePassword mycompany.com
:: get-secret.bat prod-vault ApiKey 12345678-1234-1234-1234-123456789012

:: Default vault, different secret and tenant
:: get-secret.bat "" DatabasePassword mycompany.com

:: Default vault and secret, different tenant
:: get-secret.bat "" "" mycompany.com

:: Different vault, default secret, different tenant
:: get-secret.bat production-vault "" mycompany.com

:: Show help
:: get-secret.bat /?
:: get-secret.bat --help
:: =============================================================================

@echo off
setlocal enabledelayedexpansion

:: =============================================================================
:: DEFAULT CONFIGURATION
:: =============================================================================
set DEFAULT_TENANT=xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx
set CLIENT_ID=04b07795-8ddb-461a-bbee-02f9e1bf7b46
set DEFAULT_KEY_VAULT_NAME=my-key-vault-name
set DEFAULT_SECRET_NAME=my-secret-name
set API_VERSION=7.4

:: =============================================================================
:: PARAMETER PARSING - ORDER: [keyvault] [secret] [tenant]
:: =============================================================================
set KEY_VAULT_NAME=
set SECRET_NAME=
set TENANT=

:: Show help if requested
if "%~1"=="/?" goto show_usage
if "%~1"=="-?" goto show_usage
if "%~1"=="/help" goto show_usage
if "%~1"=="--help" goto show_usage

:: Parse parameters
set /a param_count=0
:parse_loop
if not "%~1"=="" (
    set /a param_count+=1
   
    if !param_count! equ 1 (
        set KEY_VAULT_NAME=%~1
    ) else if !param_count! equ 2 (
        set SECRET_NAME=%~1
    ) else if !param_count! equ 3 (
        set TENANT=%~1
    )
   
    shift
    goto parse_loop
)

:: Set defaults for any missing parameters
if "!KEY_VAULT_NAME!"=="" set KEY_VAULT_NAME=!DEFAULT_KEY_VAULT_NAME!
if "!SECRET_NAME!"=="" set SECRET_NAME=!DEFAULT_SECRET_NAME!
if "!TENANT!"=="" set TENANT=!DEFAULT_TENANT!

:: Build Key Vault URL (handle both name and full URL)
echo "!KEY_VAULT_NAME!" | findstr /i "^https://" >nul
if !errorlevel! equ 0 (
    set KEY_VAULT_URL=!KEY_VAULT_NAME!
) else (
    set KEY_VAULT_URL=https://!KEY_VAULT_NAME!.vault.azure.net
)

:: Build the full secret URL
set KV_URL=!KEY_VAULT_URL!/secrets/!SECRET_NAME!?api-version=!API_VERSION!

:: =============================================================================
:: MAIN EXECUTION
:: =============================================================================

echo ========================================
echo Azure Key Vault Secret Retrieval Tool
echo ========================================
echo Key Vault:    !KEY_VAULT_URL!
echo Secret:       !SECRET_NAME!
echo Tenant:       !TENANT!
echo ========================================
echo.

:: Step 1: Get device code
echo [1/4] Requesting login code...
curl -s -X POST "https://login.microsoftonline.com/%TENANT%/oauth2/v2.0/devicecode" ^
     -H "Content-Type: application/x-www-form-urlencoded" ^
     -d "client_id=%CLIENT_ID%" ^
     -d "scope=https://vault.azure.net/.default" > response.txt

:: Extract values using PowerShell
for /f "tokens=*" %%i in ('powershell -Command "$response=Get-Content response.txt | ConvertFrom-Json; $response.user_code"') do set USER_CODE=%%i
for /f "tokens=*" %%i in ('powershell -Command "$response=Get-Content response.txt | ConvertFrom-Json; $response.verification_uri"') do set VERIFICATION_URL=%%i

echo [2/4] Please complete the login at: !VERIFICATION_URL!
echo Enter code: !USER_CODE!
echo.
echo Press any key AFTER you complete the browser login...
pause >nul

:: Step 3: Get access token
echo.
echo [3/4] Getting access token...
for /f "tokens=*" %%i in ('powershell -Command "$response=Get-Content response.txt | ConvertFrom-Json; $response.device_code"') do set DEVICE_CODE=%%i
curl -s -X POST "https://login.microsoftonline.com/%TENANT%/oauth2/v2.0/token" ^
     -H "Content-Type: application/x-www-form-urlencoded" ^
     -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" ^
     -d "client_id=%CLIENT_ID%" ^
     -d "device_code=%DEVICE_CODE%" > token.txt

:: Extract access token
for /f "tokens=*" %%i in ('powershell -Command "try {$response=Get-Content token.txt | ConvertFrom-Json; $response.access_token} catch {''}"') do set ACCESS_TOKEN=%%i

if "!ACCESS_TOKEN!"=="" (
    echo ERROR: Authentication failed!
    goto cleanup
)

:: Step 4: Fetch secret
echo [4/4] Fetching secret...
curl --location "!KV_URL!" ^
     --header "Authorization: Bearer !ACCESS_TOKEN!" ^
     --header "Content-Type: application/json"

goto cleanup

:: =============================================================================
:: USAGE HELP
:: =============================================================================
:show_usage
echo.
echo USAGE: get-secret.bat [keyvault] [secret] [tenant]
echo.
echo PARAMETERS:
echo   [keyvault]  Key Vault name or URL  (default: %DEFAULT_KEY_VAULT_NAME%)
echo   [secret]    Secret name            (default: %DEFAULT_SECRET_NAME%)
echo   [tenant]    Tenant ID or domain    (default: %DEFAULT_TENANT%)
echo.
echo EXAMPLES:
echo   get-secret.bat
echo   get-secret.bat my-vault
echo   get-secret.bat my-vault my-secret
echo   get-secret.bat my-vault my-secret my-tenant.com
echo   get-secret.bat "" my-secret
echo   get-secret.bat "" "" my-tenant.com
echo.
exit /b 0

:: =============================================================================
:: CLEANUP
:: =============================================================================
:cleanup
del response.txt 2>nul
del token.txt 2>nul

endlocal
