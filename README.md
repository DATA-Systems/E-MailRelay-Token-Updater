# E-MailRelay-Token-Updater

A convenient script to read and update Microsoft 365 OAuth (Exchange Online SASL/XAuth) tokens and update the auth config file of [E-MailRelay](https://emailrelay.sourceforge.net/). This basically extends [E-MailRelay](https://emailrelay.sourceforge.net/) to be useable as a silend but powerful Microsoft 365 (Exchange) SMTP Relay.

## Installation

### 1. Setup

Download one or both script(s) as you need:

`create-m365-app-principals.ps1` - Assist you in creating AzureAD Applications with appropiate permissions for sending E-Mails. Run this once or fetch your App-credentials using the EntraID GUI.

`emailrelay-update-xoauth.ps1` - Has to be set up as a scheduled task, using those credentials to update the OAuth token(s).

### 2. Create Azure (Entra) Application

There are two ways this can be done. [Manually](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) or automatically using this script.

We recommend using `.\create-m365-app-principals.ps1` to create the App (with least privileges to send mail).

Login with your Microsoft 365 Administrator when asked to to so. This ensues the "least privilege" setup and sets the [admin consent](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/grant-admin-consent) flag for your new application. You will be prompted (at least) two times, depending on your Microsoft 365 tenants security setings. This is expected.

### 3. Backup/Paste credentials
`create-m365-app-principals.ps1` will output your new App's credentials, namely "AppID" and "AppSecret" and "TenantID" ⚠️ Backup them to a safe place.<br>
⚠️ The AppSecret has a livetime of 121 Moths (1 year with 1 month of spare time) ⚠️

Edit `emailrelay-update-xoauth.ps1` using notepad or your editor of choice and paste those values. Make sure the (changed) script is in a safe place and has appropriate ACLs.

Paste your values to fill those variables:

    # Path to your "emailrelay.auth" config file
    $AuthFile = 'C:\ProgramData\E-MailRelay\emailrelay.auth'

    # Username (UPN) of the sending UserMailbox, like "mailrelay@example.com".
    $Username = ''

    # TenantID, as shown in App registration (or Enterprise App)
    $TenantId = ''

    # ApplicationID (Client) as shown in App Registration (or Enterprise App)
    $AppId = ''

    # Application Secret (Client secret); This will need to be MANUALLY renewed according to the expiration set during creation.
    $AppSecret = ''


### 4. Setup scheduled task (for automatic token renewal)

A scheduled task running `emailrelay-update-xoauth.ps1` (with pasted secrets) should be set up to run every ~45 minutes. Azure application tokens have a livetime of 60 minutes.

This can be done with two simple lines at the (Run-As-Administrator) command line:

    schtasks /create /sc MINUTE /mo 30 /ru System /rl HIGHEST /tn Update-XOauth-Token /tr "powershell.exe -File '<path to emailrelay-update-xoauth.ps1>'"
    schtasks /run /tn Update-XOauth-Token

## Thank you

We set this up because [E-MailRelay](https://emailrelay.sourceforge.net/) is our SMTP relay of choice, since Microsoft [dropped the SMTP services in Windows Server 2025](https://learn.microsoft.com/en-us/windows-server/get-started/removed-deprecated-features-windows-server). We are planning to use (and support) these scripts, as long as needed. We will gladly read (and most likely accept) PRs for patches, improvements and updates.

Thanks to the admins of [ugg.li](https://ugg.li) for their very friendly help and guidance and thanks to Microsoft for keeping us on our toes.

## License
Shall be used under [GPLv3](https://choosealicense.com/licenses/gpl-3.0/).
