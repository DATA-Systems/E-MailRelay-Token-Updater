# E-MailRelay-Token-Updater
A convenient script to retrieve Microsoft 365 OAuth (Exchange Online SASL XOAUTH2) tokens and update the auth configuration file for [E-MailRelay](https://emailrelay.sourceforge.net/).
This basically extends E-MailRelay to be useable as a silent but powerful Microsoft 365 (Exchange Online) SMTP Relay with modern authentication.

## Installation

### 1. Setup

You need to install the Microsoft Entra and Exchange Online Management PowerShell module(s):

`PS C:\> Install-Module -Name Microsoft.Entra -AllowClobber`
`PS C:\> Install-Module -Name ExchangeOnlineManagement -AllowClobber`

> [!NOTE]
> * Administrative rights may be needed, depending on your configuration
> * Depending on your PowerShell edition (core/destkop/windows) and Version you might need different Versions of the ExchangeOnlineManagement
> * We have noticed, the current release v3.7.2 doesn't work in Windows PowerShell v5.1. It requires PowerShell (formerly known as PowerShell Core) [version 7](https://learn.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5#install-powershell-using-winget-recommended) or newer instead.

Then, download or clone one or both script(s):

#### create-m365-app-principals.ps1

Assists you in creating the required Entra ID application with appropiate permissions for sending E-Mails

`PS C:\> curl.exe -L https://github.com/DATA-Systems/E-MailRelay-Token-Updater/raw/refs/heads/main/create-m365-app-principals.ps1 > create-m365-app-principals.ps1`

#### emailrelay-update-xoauth.ps1

Retrieves the actual authentication tokens and writes them to the E-MailRelay configuration file for use during SMTP authentication. Needs to be run regularly (i.e. as a scheduled task)

`PS C:\> curl.exe -L https://github.com/DATA-Systems/E-MailRelay-Token-Updater/raw/refs/heads/main/emailrelay-update-xoauth.ps1 > emailrelay-update-xoauth.ps1`

<br />

> [!NOTE]
> After downloading, make sure to unblock the files either by using the [Unblock-File](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file) PowerShell cmdlet or by manually unblocking it via the file properties using the Explorer.
> Also check [about_Execution_Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies) and make sure your systems' execution policy allows running the scripts.

### 2. Create Entra ID application
There are two ways this can be done. [Manually](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) or automatically using the `create-m365-app-principals.ps1` script.

We recommend using `create-m365-app-principals.ps1` to create the app, client secrets and Exchange Online service principals with their appropriate permissions.

When running the Script, provide the mailbox in whose name you want to send mails using the `-UserPrincipalName` parameter.

> [!TIP]
> You can specify a different client secret lifetime using the `-ClientSecretLifetimeMonths` parameter. (default: _120_ months)
> 
> Likewise using the `-AppName` parameter, you can change the Entra ID application name. (default: _E-MailRelay_), 

#### Example
`PS C:\Program Files\E-MailRelay> .\create-m365-app-principals.ps1 -ClientSecretLifetimeMonths 20 -UserPrincipalName mail@exmaple.com`

You will then be prompted to log in two times. You will need a user with administrative permissions for this. The first login is required for authenticating to Microsoft Entra using the Microsoft.Entra.* modules, the second login is needed for managing ExchangeOnline permissions using the ExchangeOnlineManagement module.

Microsoft Internet Explorer (IE) "Protected Mode" has to be turned off, for the modern authentication window to work properly. Default is "off" on Windows Server, which can be changed in "Server Manager" app.

### 3. Backup/Paste credentials
`create-m365-app-principals.ps1` will output your new apps' credentials, namely `AppID`, `AppSecret` and `TenantID`.

> [!WARNING]
> Store them at a secure place.
> 
> The AppSecret has a lifetime of 120 months (by default, see `-ClientSecretLifetimeMonths` parameter) and needs to be renewed ***manually***.

Edit `emailrelay-update-xoauth.ps1` using your editor of choice and paste the required values.

```powershell
# Path to the "emailrelay.auth" config file
$AuthFile = 'C:\ProgramData\E-MailRelay\emailrelay.auth'

# Username (UPN) of the sending UserMailbox, like "mailrelay@example.com".
$Username = ''

# TenantID, as shown in App registration (or Enterprise App)
$TenantId = ''

# ApplicationID (Client) as shown in App Registration (or Enterprise App)
$AppId = ''

# Application Secret (Client secret); This will need to be MANUALLY renewed according to the expiration set during creation.
$AppSecret = ''
```

> [!CAUTION]
> Make sure the script is stored in a secure place with appropriate ACLs, as anyone with access to it can use it to request a valid authentication token and send mails as the configured mailbox.


Ensure that E-MailRelay is set up to actually use the [authentication](https://emailrelay.sourceforge.net/index.html#reference_md_Authentication) config file via the `client-auth` parameter (either as part of the command line or in the `emailrelay.cfg` file).

### 4. Set up scheduled task (for automatic token renewal)
To ensure OAuth tokens are renewed before their lifetime expires (60 minutes), you should set up a scheduled task to run the `emailrelay-update-xoauth.ps1` script every ~45-55 minutes.

This example sets up a scheduled task named "Update-E-MailRelay-OAuth-Token" to run the script as NT-AUTHORITY\SYSTEM every 45 minutes.
The second line immediately runs the task to update the E-MailRelay config with a freshly acquired OAuth token (i.e. during initial setup).
```
schtasks /create /sc MINUTE /mo 45 /ru System /rl HIGHEST /tn Update-E-MailRelay-OAuth-Token /tr "powershell.exe -File '<path to emailrelay-update-xoauth.ps1>'"
schtasks /run /tn Update-E-MailRelay-OAuth-Token
```

## Trouble shooting

### Script can not be executed due to missing digital signature.

Open the properties and click allow at security (at the bottom of file)

## Thank you
We set this up because E-MailRelay is our SMTP relay of choice since Microsoft [removed the SMTP services in Windows Server 2025](https://learn.microsoft.com/en-us/windows-server/get-started/removed-deprecated-features-windows-server?tabs=ws25#features-removed).
We are planning to use (and support) these scripts as long as needed. We will gladly read (and most likely accept) PRs for patches, improvements and updates.

Thanks to the admins of [ugg.li](https://ugg.li) for their very friendly help and guidance and thanks to Microsoft for keeping us on our toes.

## License
Shall be used under [GPLv3](LICENSE).
