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

#Requires -Modules Microsoft.Entra.Authentication, Microsoft.Entra.Applications, ExchangeOnlineManagement

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

# Import modules
Import-Module -Name Microsoft.Entra.Authentication
Import-Module -Name Microsoft.Entra.Applications
Import-Module -Name ExchangeOnlineManagement

Write-Host "Connecting to Entra PowerShell..."
# Comnnect to Entra
Connect-Entra -NoWelcome

Write-Host "Creating Entra App..."
# Create app and service principal
$app = New-EntraApplication -DisplayName $AppName
$servicePrincipal = New-EntraServicePrincipal -AppId $app.AppId

# Add required application api permissions
$applicationPermission = 'SMTP.SendAsApp'
$graphApiId = '00000002-0000-0ff1-ce00-000000000000'
$graphServicePrincipal = Get-EntraServicePrincipal -Filter "AppId eq '$graphApiId'"

Write-Host "Setting Entra App API permissions..."
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
New-EntraServicePrincipalAppRoleAssignment -PrincipalId $servicePrincipal.Id -ResourceId $graphServicePrincipal.Id -Id $appRoleId -ServicePrincipalId $servicePrincipal.Id | Out-Null

Write-Host "Creating client secret..."
# Create client secret
$passCred = New-Object Microsoft.Open.MSGraph.Model.PasswordCredential
$passCred.EndDateTime = (Get-Date).AddMonths($ClientSecretLifetimeMonths)
$passCred.DisplayName = "$AppName secret"
$appPassword = New-EntraApplicationPassword -ApplicationId $app.Id -PasswordCredential $passCred

Write-Host "Connecting ExchangeOnline PowerShell..."
# Connect to ExchangeOnline
Connect-ExchangeOnline -ShowBanner:$false

Write-Host "Setting Exchange Service-Principal permissions on Mailbox $UserPrincipalName..."
# Manage Exchange Online permissions
$exoServicePrincipal = New-ServicePrincipal -AppId $servicePrincipal.AppId -ObjectId $servicePrincipal.Id -DisplayName $AppName
Add-MailboxPermission -AccessRights FullAccess -Identity $UserPrincipalName -User $exoServicePrincipal.ObjectId | Out-Null

# Disconnect modules
$entraSession = Disconnect-Entra
Disconnect-ExchangeOnline -Confirm:$false

# Display required output values
$checkmark = [char]0x2705
$exclamation = [char]0x26a0
Write-Host "$checkmark DONE!"
Write-Host
Write-Host "$exclamation  Variables you will need $exclamation"
Write-Host "Tenant ID:     " -NoNewLine
Write-Host $entraSession.TenantId -ForegroundColor Cyan
Write-Host "App ID:        " -NoNewLine
Write-Host $app.AppId -ForegroundColor Cyan
Write-Host "Client-Secret: " -NoNewLine
Write-Host $appPassword.SecretText -ForegroundColor Cyan
