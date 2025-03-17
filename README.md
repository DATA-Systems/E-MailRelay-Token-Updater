# E-MailRelay-Token-Updater

A script to get and update the OAuth token from Microsoft 365 at the [E-MailRelay](https://emailrelay.sourceforge.net/) auth config.

## Usage

### Microsoft

Use the create-m365-app-principals.ps1 with an Administrator account script to create an App with permissions and everything ready for one user to send.
You need the AppID and AppSecret printed out at the end in the emailrelay-update-xoauth.ps1 script.
You will be promted for M365 Login after the installaiton of the modules two times.

### Script

Download the script.
Insert:
- Config file path (if nessesary)
- Username(UPN)
- Tenant ID
- App ID
- App Secret

### Setup job for renew of the token

job should run emailrelay-update-xoauth.ps1 about every 30-45 Minutes as the token has a livetime of one hour.

#### Windows Scheduler

Admin commandline

```bash
schtasks /create /sc MINUTE /mo 30  /ru System /rl HIGHEST /tn Update-XOauth-Token /tr "powershell.exe -File '<path to emailrelay-update-xoauth.ps1>'"
schtasks /run /tn Update-XOauth-Token
```
