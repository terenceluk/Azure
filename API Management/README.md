# API Management

Azure API Management (APIM) policy XML snippets for common gateway scenarios including traffic capture, authentication, and JWT validation.

## Contents

### XML Policies (`XML/`)

| File | Description |
|------|-------------|
| `XML/Capture-APIM-Traffic-and-JWT-Token-Information.xml` | APIM inbound policy that captures request traffic details and extracts JWT token claims for logging or diagnostics. |
| `XML/Set-Header-API-Key.xml` | APIM policy that sets an API key in an outgoing request header, useful for forwarding authentication to backend services. |
| `XML/Validate-JWT-Access-Claim.xml` | APIM inbound policy that validates a JWT bearer token and checks for a required access claim before allowing the request to proceed. |

## Usage

These XML snippets are intended to be applied as policies within Azure API Management. In the Azure Portal, navigate to your APIM instance → **APIs** → select an API or operation → **Policies** → paste the XML into the appropriate policy scope (inbound/outbound/on-error).
