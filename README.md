# E-MailRelay-Token-Updater

A script to get and update the OAuth token from Microsoft 365 at the [E-MailRelay](https://emailrelay.sourceforge.net/) auth config.

## Usage

### Microsoft

To disconnect later you need this command
```powershell
```

#### Create Microsoft Application

*not complete*
```powershell
New-App -OrganizationApp
```

#### Create Microsoft service principal

*not complete*
```
# Install the module, can be skipped if already installed
Import-Module ExchangeOnlineManagement

# Will open your web-browser where you need to login.
Connect-ExchangeOnline


New-ServicePrincipal -appid <> -objectid <> -DisplayName <name>
Get-ServicePrincipal | fl
Add-MailboxPermission -identity <username(UPN)> -user <> -accessrights <Fullacces|>

# Disconnect
Disconnect-ExchangeOnline
```

### Script

Download the script.
Insert:
- Config file path (if nessesary)
- Username
- Tenant ID
- App ID
- App Secret (App key)

### Setup cronjob for renew of the token

coming soon
