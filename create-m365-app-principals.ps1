<#
.SYNOPSIS
    This script sets up a new Entra ID app, service principal and Exchange Online service principal with permissions to send mails as a given UserMailbox.
    It will then return the ID and secret values needed for emailrelay-update-xoauth.ps1.
.EXAMPLE
    PS> .\create-m365-app-principals.ps1 -UserPrincipalName test@example.com
.INPUTS
    UserPrincipalName for the mailbox that will be used to authenticate via SMTP XOAUTH2
    2x Prompt for administrative M365 login (Entra and ExchangeOnlineManagement PowerShell connectivity)
.OUTPUTS
    Tenant ID, app ID and client secret
.LINK
    https://github.com/DATA-Systems/E-MailRelay-Token-Updater
.NOTES
    Version:    0.2
    Author:	    j.saslona@data-systems.de (GitHub: Jon1Games), j.tueselmann@data-systems.de (GitHub: iSnackyCracky)
    References:
        - https://learn.microsoft.com/en-us/powershell/entra-powershell/manage-apps?view=entra-powershell
        - https://learn.microsoft.com/en-us/powershell/entra-powershell/create-custom-application?view=entra-powershell&tabs=application&pivots=powershell
        - https://github.com/microsoftgraph/entra-powershell/blob/main/samples/create-custom-app-with-delegated-permissions.ps1
#>

param (
    [Parameter(Mandatory=$true,
               Position=0,
               HelpMessage="UserPrincipalName of the user that authenticates using the app")]
    [Alias("UPN")]
    [ValidateNotNullOrEmpty()]
    [string]
    $UserPrincipalName,

    [Parameter(Position=1,
               HelpMessage="Name of the Entra ID application")]
    [ValidateNotNullOrEmpty()]
    [string]
    $AppName = "E-MailRelay",

    [Parameter(Position=2,
               HelpMessage="Lifetime of the created client secret in months")]
    [int]
    $ClientSecretLifetimeMonths = 120
)

Write-Host "Check if modules are installed, if not install."

# Install the modules if not installed
Write-Host "processing: Microsoft.Entra"
Install-Module Microsoft.Entra
Write-Host "processing: ExchangeOnlineManagement"
Install-Module ExchangeOnlineManagement

# Import modules
Import-Module Microsoft.Entra
Import-Module ExchangeOnlineManagement

# Comnnect to graph and ExchangeOnline
Write-Host "Connect to MgGraph and ExchangeOnline"
Connect-ExchangeOnline

# Create app and service principal
$app = New-EntraApplication -DisplayName $AppName
$servicePrincipal = New-EntraServicePrincipal -AppId $app.AppId

# Add required application api permissions
$applicationPermission = 'SMTP.SendAsApp'
$graphApiId = '00000002-0000-0ff1-ce00-000000000000'
$graphServicePrincipal = Get-EntraServicePrincipal -Filter "AppId eq '$graphApiId'"

# Create resource access object
$resourceAccess = New-Object Microsoft.Open.MSGraph.Model.ResourceAccess
$resourceAccess.Id = ((Get-EntraServicePrincipal -ServicePrincipalId $graphServicePrincipal.Id).AppRoles | Where-Object { $_.Value -eq $applicationPermission}).Id
$resourceAccess.Type = 'Role'

# Create required resource access object
$requiredResourceAccess = New-Object Microsoft.Open.MSGraph.Model.RequiredResourceAccess
$requiredResourceAccess.ResourceAppId = $graphApiId
$requiredResourceAccess.ResourceAccess = $resourceAccess

# Set application required resource access
Set-EntraApplication -ApplicationId $app.Id -RequiredResourceAccess $requiredResourceAccess

# Assign API permissions to the service principal
$appRoleId = ($graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $applicationPermission }).Id
New-EntraServicePrincipalAppRoleAssignment -PrincipalId $servicePrincipal.Id -ResourceId $graphServicePrincipal.Id -Id $appRoleId -ServicePrincipalId $servicePrincipal.Id

# Create client secret
$passCred = New-Object Microsoft.Open.MSGraph.Model.PasswordCredential
$passCred.EndDateTime = (Get-Date).AddMonths($ClientSecretLifetimeMonths)
$passCred.DisplayName = "$AppName secret"
$appPassword = New-EntraApplicationPassword -ApplicationId $app.Id -PasswordCredential $passCred

# Manage Exchange Online permissions
$exoServicePrincipal = New-ServicePrincipal -AppId $servicePrincipal.AppId -ObjectId $servicePrincipal.Id -DisplayName $AppName
Add-RecipientPermission -AccessRights SendAs -Identity $UserPrincipalName -Trustee $exoServicePrincipal.ObjectId

# Disconnect modules
$entraSession = Disconnect-Entra
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "--- Variables you will need ---"
Write-Host "Tennant ID: $( $entraSession.TenantId )"
Write-Host "App ID: $( $app.AppId )"
Write-Host "Client-Secret: $( $appPassword.SecretText )"
