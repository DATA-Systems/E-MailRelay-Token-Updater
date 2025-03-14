# E-MailRelay-Token-Updater

A script to get and update the OAuth token from Microsoft 365 at the [E-MailRelay](https://emailrelay.sourceforge.net/) auth config.

## Usage

### Microsoft

#### Create Microsoft Application

cooming soon

#### Create Microsoft service principal

```
# Install the module, can be skipped if already installed
Import-Module ExchangeOnlineManagement

# Will open your web-browser where you need to login.
Connect-ExchangeOnline

# ID´s found at entry > Applications > Organisation Applications > APP
New-ServicePrincipal -appid <appId> -objectid <objectId> -DisplayName <name>
Get-ServicePrincipal | fl
Add-MailboxPermission -identity <username(UPN)> -user <appId> -accessrights <Fullacces>

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
