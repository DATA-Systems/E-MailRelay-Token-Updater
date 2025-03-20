# E-MailRelay-Token-Updater

A convenient script to retrieve Microsoft 365 OAuth (Exchange Online SASL XOAUTH2) tokens and update the auth configuration file for [E-MailRelay](https://emailrelay.sourceforge.net/).
This basically extends [E-MailRelay](https://emailrelay.sourceforge.net/) to be useable as a silent but powerful Microsoft 365 (Exchange Online) SMTP Relay with modern authentication.

## Installation

### 1. Setup

Download one or both script(s) as needed:

`create-m365-app-principals.ps1` - Assists you in creating Entra ID applications with appropiate permissions for sending E-Mails.

`emailrelay-update-xoauth.ps1` - Retrieves the actual authentication tokens and writes them to the E-MailRelay configuration file for use during SMTP authentication. Needs to be run regularly (i.e. as a scheduled task).

### 2. Create Entra ID application

There are two ways this can be done. [Manually](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) or automatically using the `create-m365-app-principals.ps1` script.

We recommend using `.\create-m365-app-principals.ps1` to create the app, client secrets and Exchange Online service principals with correct permissions.

Log in using your Microsoft 365 administrative credentials when asked to do so. You will be prompted for credentials (at least) two times, depending on your Microsoft 365 tenant security setings. This is expected due to the multiple modules/connections required (EntraID, ExchangeOnline, Graph).

### 3. Backup/Paste credentials
`create-m365-app-principals.ps1` will output your new app's credentials, namely `AppID`, `AppSecret` and `TenantID`.

⚠️ Store them at a safe place.

⚠️ The AppSecret has a lifetime of 121 Months and needs to be renewed manually. ⚠️

Edit `emailrelay-update-xoauth.ps1` using your editor of choice and paste the required values.

⚠️ Make sure the script is in a safe place and has appropriate ACLs as anyone with access to it can use it to request a valid authentication token and send mails as the configured mailbox.

Paste your values to fill the required variables:

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

### 4. Set up scheduled task (for automatic token renewal)

A scheduled task running `emailrelay-update-xoauth.ps1` (with pasted secrets) should be set up to run every ~45 minutes as the OAuth tokens have a lifetime of 60 minutes.

This can be done with two simple lines from the command line (as admin):
```
schtasks /create /sc MINUTE /mo 30 /ru System /rl HIGHEST /tn Update-XOauth-Token /tr "powershell.exe -File '<path to emailrelay-update-xoauth.ps1>'"
schtasks /run /tn Update-XOauth-Token
```

## Thank you

We set this up because [E-MailRelay](https://emailrelay.sourceforge.net/) is our SMTP relay of choice, since Microsoft [dropped the SMTP services in Windows Server 2025](https://learn.microsoft.com/en-us/windows-server/get-started/removed-deprecated-features-windows-server).
We are planning to use (and support) these scripts, as long as needed. We will gladly read (and most likely accept) PRs for patches, improvements and updates.

Thanks to the admins of [ugg.li](https://ugg.li) for their very friendly help and guidance and thanks to Microsoft for keeping us on our toes.

## License
Shall be used under [GPLv3](https://choosealicense.com/licenses/gpl-3.0/).
