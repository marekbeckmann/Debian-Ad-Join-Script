# Debian-Ad-Join-Script

**Should work on Debian 9,10,11 as well as Ubuntu 18.04,20.04 (LTS)**

## How to use

### 1. Download script

```
git clone https://github.com/marekbeckmann/Debian-Ad-Join-Script.git ~/join-ad
cd ~/join-ad && chmod +x join-ad.sh
```
### 2. Run the script

```
sudo ./join-ad.sh
```

You can run the script with the following parameters: 


| Option | Description |
|--|--|
| `-h` `--help` | Prints help message, that shows all options and a short description |
| `-d` `--ad-domain` `<domain>` | Specifies domain to join |
| `-u` `--admin-user` `<userName>` | Specifies privileged user for AD join |
| `-p` `--homedir` `<directory>` | Overrides home directory for SSSD config (Defaults to `/home/%u@%d`) |
| `-s` `--shell` `<shell>`| Overrides shell for SSSD config |
| `-m` `--umask` `<umask>` | Specify UMASK for the homedir of users |
| `-a` `--allow-user` `<user1,user2>` | Allow user(s) (comma seperated) |
| `-r` `--allow-group` `<group1,group2>` | Allow group(s) (comma seperated) |


**Example:**
```
sudo ./join-ad.sh  -u "admUser" -d "ad.your-company.org" -p "/home/%d/%u" -s "/bin/bash"
```
This will join the ad (realm ad.your-company.org), using the privileged user `admUser`and setting the home directory for new users to `/home/ad.your-company.org/userName` and overriding the shell for every user to `/bin/bash`

## 3. Important Notice

This script doesn't change the default UMASK of `pam_mkhomedir.so`, which uses a UMASK of 0022. For better privacy, use a UMASK of 0077
