#
# E-MailRelay - Get token from Microsoft 365 and update at in the E-MailRelay auth config
#
# Authors:
# - b.stromberg@data-systems.de
# - j.saslona@data-systems.de (Github: Jon1Games)
#

# Paste your config file path, Username, Tenant ID, App ID, and App Secret (App key) into the indicated quotes below.

# Configuration 
$authFile = "C:\Users\JonasSaslona\Desktop\test.txt"	    ### Put your Auth files paht from the emailrelay here # default: C:\ProgramData\E-MailRelay\emailrelay.auth
$username = 'beda-system@beda.com'				            ### Put your E-Mail here
$tenantId = 'bb8c1c38-2b5f-4745-9fa0-9741f4c2413e' 		    ### Paste your tenant ID here
$appId = '87d1f02d-e331-45ab-ba0c-9eb975986c06' 		    ### Paste your Application ID here
$appSecret = 'TyU8Q~_2F_9XpemfuyJxW6K.Fow9a95FvL.qEchj' 	### Paste your Application key here
$sourceAppIdUri = 'https://outlook.office365.com/.default' 	# Scope

# Get new token
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
