<#
.EXAMPLE
    .\create-m365-app-principals.ps1 example@example.com
    This will create an new App with Permissions and an Exchange-Serviceprinzipal needed for emailrelay-update-xoauth.ps1.
    Also it prints out the AppID and Secret needed in emailrelay-update-xoauth.ps1.
.INPUTS
  UPN (Username) that need to auth with XOAuth2
  2x Promt for M365 login
.OUTPUTS
  App(Client)-ID
  AppSecret
  TennantID
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
Write-Host "Connect to MgGraph and ExchangeOnline"
$scopes = @(
    "Application.Read.All"
    "Application.ReadWrite.All"
    "User.Read.All"
)
Connect-MgGraph -Scopes $scopes -NoWelcome
Connect-ExchangeOnline

# Some configuration
$appName = "E-MailRelay"

# Create APP
Write-host "Create MgApplication"
$App = New-MgApplication -DisplayName $AppName

# Get APP informations
$APPObjectID = $App.Id
$AppID = Get-MgApplication -ApplicationId $APPObjectID | Select-Object -ExpandProperty AppId

# Create Graph service prinzipal
$params = @{
	appId = $AppID
}
Write-host "Create MgServicePrinzipal"
$MgServicePrincipal = New-MgServicePrincipal -BodyParameter $params

# Add permissions and admin consent
$applicationPermission = 'SMTP.SendAsApp'
$graphApiId = '00000002-0000-0ff1-ce00-000000000000'
$graphServicePrincipal = Get-EntraServicePrincipal -Filter "AppId eq '$graphApiId'"
$servicePrincipal = Get-EntraServicePrincipal -Filter "DisplayName eq '$appName'"

# Get application role ID
$appRoleId = ($graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $applicationPermission }).Id

Write-host "Set Permissions"
New-EntraServicePrincipalAppRoleAssignment -ObjectId $servicePrincipal.Id -ResourceId $graphServicePrincipal.Id -Id $appRoleId -PrincipalId $servicePrincipal.Id | Out-Null

# Add app secret
$endDate = (Get-Date).AddMonths(+121)
$passwordCred = @{
    "displayName" = $appName
    "endDateTime" = $endDate
}
Write-host "Create client secret, expiration: $endDate"
$ClientSecret2 = Add-MgApplicationPassword -ApplicationId $APPObjectID -PasswordCredential $passwordCred
$secret = $ClientSecret2.SecretText

#Show ClientSecrets
$App = Get-MgApplication -ApplicationId $APPObjectID

$registered = $false
while ($registered -eq $false) {
    # Try to create ExchangeServicePrinzipal
    $principal = New-ServicePrincipal -appid $MgServicePrincipal.AppId -objectid $MgServicePrincipal.Id -DisplayName $appName -erroraction 'silentlycontinue'

    if ($principal -eq $null) {
        Write-Host "Wait 5 seconds for Microsoft to register MgApplication and MgServicePrinzipal."
        Start-Sleep -Seconds 5
    } else {
        Write-Host "ExchangeServicePrinzipal created."
        $registered = $true
    }
}   

# Add user permission
Write-Host "Grant $upn access to the ExchangeServicePrinzipal"
Add-MailboxPermission -identity $upn -user $MgServicePrincipal.AppId -accessrights Fullacces | Out-Null

# Disconnect Graph
$DisconnectGraph = Disconnect-MgGraph
$TenantID = $DisconnectGraph.TenantId

# Disconnect ExchnagOnline
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "--- Variables you will need ---"
Write-Host "TennantID: $TenantID"
Write-Host "AppID: $AppID"
Write-Host "Client-Secret: $secret"

exit
