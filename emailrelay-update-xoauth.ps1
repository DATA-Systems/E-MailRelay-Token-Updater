<#
.SYNOPSIS
    Updates the E-Mailrelay auth config file with [Microsft] SASL XOAuth2 token(s) for Exchange Online
.DESCRIPTION
    Takes TenantID, AppID and AppSecret for a Microsoft 365 Entra Application ("App Registration"),
    retrieves the Grpah access token from it, generates a SASL XAUTH2 Access Token from that and
    updates the E-MailRelay auth config file with the new token. All while E-MailRelay is running.
    This script is intended to be run as a scheduled task to keep the E-MailRelay auth config file up-to-date.
    The task needs to be run more than once per hour, since tokens are usually valid for 3600 seconds.
.EXAMPLE
    .\emailrelay-update-xoauth.ps1
    This will update the E-MailRelay auth config file with a new SASL XOAuth2 token.
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        0.8
  Author:         b.stromberg@data-systems.de (Github: weed-), j.saslona@data-systems.de (Github: Jon1Games), j.tueselmann@data-systems.de (Github: iSnackyCracky)
  Creation Date:  2025-03-11
#>

# Configuration
# (full) path to the E-Mailrelay auth file
$AuthFile = 'C:\ProgramData\E-MailRelay\emailrelay.auth'
# Username (UPN) of the sending UserMailbox
$Username = ''
# Tenant ID as shown in App Registration or Enterprise App
$TenantId = ''
# Application ID (Client) as shown in App Registration or Enterprise App
$AppId = ''
# Application Secret (Client secret); This will need to be MANUALLY renewed according to the expiration set during creation.
$AppSecret = ''
# Scopes for the OAuth Token request; Since we're using the "Client Credentials Grant" OAuth-Flow, this has to include the /.default Scope.
$ScopeUri = 'https://outlook.office365.com/.default'

# Get new access token
# We're using the "Client Credentials Grant" flow (grant_type = 'client_credentials'), so we can directly
# acquire a token from the token endpoint and don't need to go through the authorization endpoint first.
$oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
$authBody = [Ordered] @{
    scope = "$ScopeUri"
    client_id = "$AppId"
    client_secret = "$AppSecret"
    grant_type = 'client_credentials'
}
$authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
$token = $authResponse.access_token

# Convert token to SASL XOauth2 format and encode it in Base64. RFC7628 defines the SASL XOauth format
# as a string of key/value pairs separated by a separator "kvsep = %x01". This is sometimes represented
# as ^A (Control-A) and corresponds to the ASCII or Unicode "Start of Heading" control code.
$kvsep = [char]0x1
$saslXOAuth2Bytes = [System.Text.Encoding]::UTF8.GetBytes("user=${username}${kvsep}auth=Bearer ${token}${kvsep}${kvsep}")
$saslXOAuth2 = [Convert]::ToBase64String($saslXOAuth2Bytes)

# Append the client oauth line to the E-Mailrelay auth file.
# If it already exists, replace the existing token with the new one.
$emailrelayClientOauth = "client oauth:b $username"
$emailrelayAuthConfig = "$emailrelayClientOauth $saslXOAuth2"
$line = Get-Content $AuthFile | Select-String $emailrelayClientOauth | Select-Object -ExpandProperty Line
if ($line -eq $null) {
    Out-File -Append -FilePath $AuthFile -InputObject $emailrelayAuthConfig -Encoding utf8
    Write-Host "XOAuth base 64 token was appended to the file $AuthFile."
} else {
    $content = Get-Content $AuthFile
    $content | ForEach-Object {$_ -replace $line,$emailrelayAuthConfig} | Set-Content $AuthFile
    Write-Host "XOAuth base 64 token was replaced in $AuthFile."
}

exit
