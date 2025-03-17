<#
.EXAMPLE
    .\create-m365-app-principals.ps1 test@domain.com
    This will create an new App with Permissions and an Exchange-Serviceprinzipal needed for emailrelay-update-xoauth.ps1.
    Also it prints out the AppID and Secret needed in emailrelay-update-xoauth.ps1.
.INPUTS
  UPN (Username) that need to auth with XOAuth2
  2x Promt for M365 login
.OUTPUTS
  App(Client)-ID
  AppSecret
.NOTES
  Version:        0.1
  Author:         j.saslona@data-systems.de (Github: Jon1Games)
  Creation Date:  2025-03-17
#>

# Get args
param ($upn)
if ($upn -eq $null) {
    $upn = read-host -Prompt "Please enter UPN (Username), this is the user which can auth with the App" 
}

Write-Host "Check if modules are installed, if not install."

# Install the modules if not installed
Write-Host "processing: Microsoft.Graph.Authentication"
Install-Module Microsoft.Graph.Authentication
Write-Host "processing: Microsoft.Graph.Applications"
Install-Module Microsoft.Graph.Applications
Write-Host "processing: Microsoft.Entra"
Install-Module Microsoft.Entra
Write-Host "processing: ExchangeOnlineManagement"
Install-Module ExchangeOnlineManagement

# Import modules
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications
Import-Module Microsoft.Entra
Import-Module ExchangeOnlineManagement

# Comnnect to graph and ExchangeOnline
$scopes = @(
    "Application.Read.All"
    "Application.ReadWrite.All"
    "User.Read.All"
)
Connect-MgGraph -Scopes $scopes
Connect-ExchangeOnline

# Some configuration
$appName = "E-MailRelay"

# Create APP
$App = New-MgApplication -DisplayName $AppName

# Get APP informations
$APPObjectID = $App.Id
Get-MgApplication -ApplicationId $APPObjectID

# Store this for later
$AppID = Get-MgApplication -ApplicationId $APPObjectID | Select-Object -ExpandProperty AppId

# Create Graph service prinzipal
$params = @{
	appId = $AppID
}
$MgServicePrincipal = New-MgServicePrincipal -BodyParameter $params

# Add permissions and admin consent
$applicationPermission = 'SMTP.SendAsApp'
$graphApiId = '00000002-0000-0ff1-ce00-000000000000'
$graphServicePrincipal = Get-EntraServicePrincipal -Filter "AppId eq '$graphApiId'"
$servicePrincipal = Get-EntraServicePrincipal -Filter "DisplayName eq '$appName'"

# Get application role ID
$appRoleId = ($graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $applicationPermission }).Id

New-EntraServicePrincipalAppRoleAssignment -ObjectId $servicePrincipal.Id -ResourceId $graphServicePrincipal.Id -Id $appRoleId -PrincipalId $servicePrincipal.Id

# Add app secret
$passwordCred = @{
    "displayName" = $appName
    "endDateTime" = (Get-Date).AddMonths(+12)
}
$ClientSecret2 = Add-MgApplicationPassword -ApplicationId $APPObjectID -PasswordCredential $passwordCred
$secret = $ClientSecret2.SecretText

#Show ClientSecrets
$App = Get-MgApplication -ApplicationId $APPObjectID
$App.PasswordCredentials

Write-Host "Wait for MS to register app and principal"
Start-Sleep -Seconds 10

# Create ServicePrincipal
New-ServicePrincipal -appid $MgServicePrincipal.AppId -objectid $MgServicePrincipal.Id -DisplayName $appName

# Add user permission
Add-MailboxPermission -identity $upn -user $MgServicePrincipal.AppId -accessrights Fullacces

# Disconnect Graph
Disconnect-MgGraph

# Disconnect
Disconnect-ExchangeOnline

Write-Host "--- Variables you will need ---"
Write-Host "AppID: $AppID"
Write-Host "Client-Secret: $secret"

exit
