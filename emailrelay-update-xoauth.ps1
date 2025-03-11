<#
.SYNOPSIS
    Updates the E-Mailrelay auth config file with [Microsft] SASL XOAuth2 token(s) for Exchange Online
.DESCRIPTION
    Takes TenantID, AppID and AppSecret of a Microsoft 365 AzureAD-Application ("Entra App"),
    generates the Grpah access token for it, generates a SASL XAUTH2 Access Token from that and
    updates the E-MailRelay auth config file with the new token. All while E-MailRelay is running.
    This script is intended to be run as a scheduled task to keep the E-MailRelay auth config file up-to-date.
.PARAMETER <Parameter_Name>
    No command line parameters
.EXAMPLE
    .\emailrelay-update-xoauth.ps1
    This will update the E-MailRelay auth config file with a new SASL XOAuth2 token.
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        0.8
  Author:         b.stromberg@data-systems.de (Github: weed-), j.saslona@data-systems.de (Github: Jon1Games)
  Creation Date:  2025-03-11
  Change:         -Initial script development
                  - Added TenantID, AppID and AppSecret as parameters
                  - Stole stuff from https://learn.microsoft.com/de-de/entra/global-secure-access/scripts/powershell-get-token
#>

# Configuration 
$authFile = 'C:\ProgramData\E-MailRelay\emailrelay.auth'	### Put your (full) E-Mailrelay Auth file path here
$username = ''				    			### Put your Username (UPN) here, like "bob@example.com"
$tenantId = '' 		    					### Paste your tenant ID here, like "12345678-1234-1234-1234-123456789012"
$appId = '' 		    					### Paste your Application ID here, like "12345678-1234-1234-1234-123456789012"
$appSecret = '' 						    ### Paste your Application Secret (key) here, like "_ew1849n~2as#+a.33"
$sourceAppIdUri = 'https://outlook.office365.com/.default' 	# Paste your scope URL here, like "https://outlook.office365.com/.default" (Exchange Online)

# Get new access token
$oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
$authBody = [Ordered] @{
    scope = "$sourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}
$authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
$token = $authResponse.access_token

# Convert toke to SASL XOauth2 format
$saslXOAuth2Bytes = [System.Text.Encoding]::Unicode.GetBytes("user=$username^Aauth=Bearer $token^A^A")
$saslXOAuth2 = [Convert]::ToBase64String($saslXOAuth2Bytes)

# Replace old token
$emailrelayAuth = "Client oauth:b $saslXOAuth2"
$content = Get-Content $authFile
if (Get-Content $authFile | %{$_ -match "Client oauth:b *"}) {
	$content = $content -replace "Client oauth:b *", $emailrelayAuth
	$content | Set-Content $authFile
	Write-Host "XOAuth base 64 token was replaced in $authFile."
} else {
    Out-File -append -FilePath $authFile -InputObject $emailrelayAuth
    Write-Host "XOAuth base 64 token was appended to the file $authFile."
}
