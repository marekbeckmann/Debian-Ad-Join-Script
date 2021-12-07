#!/bin/bash

function init() {
    getParams "$@"
    if [ "$(whoami)" = "root" ]; then
        if [[ -n "$realm" ]]; then
            installPackages
            adJoin
            enableSudo
            summary
        else
            logToScreen "Please provide a REALM to join"
            helpMsg
            exit 1
        fi
    else
        logToScreen "Please run as root" --error
    fi
}

function summary() {
    logToScreen "
Succesfully joined the following Realm: 
Realm: $realm
Homedir: $homedir [/home/%u@%d]
Default Shell: $shell [/bin/bash]
Joined with: $adminuser
"
}

function installPackages() {
    apt -y update
    apt -y install realmd sssd sssd-tools sssd-ad libnss-sss libpam-sss adcli samba-common-bin packagekit libpam-google-authenticator || logToScreen "Couldn't install Packages!" --error
    systemctl stop sssd
    cp /usr/lib/x86_64-linux-gnu/sssd/conf/sssd.conf /etc/sssd/.
    chmod 600 /etc/sssd/sssd.conf
    systemctl enable sssd
    systemctl start sssd
}

function adJoin() {
    logToScreen "Do you want to join the following REALM? To proceed, enter your credentials"
    realm discover "$realm" || logToScreen "Can't discover realm" --error
    realm join "$realm" -U "$adminuser" || logToScreen "Can't join AD" --error
    if [[ -n "$homedir" ]]; then
        echo "override_homedir = $homedir" | tee -a /etc/sssd/sssd.conf
    fi
    if [[ -n "$shell" ]]; then
        sed -i '/default_shell/d' /etc/sssd/sssd.conf
        echo "default_shell = $shell" | tee -a /etc/sssd/sssd.conf
    fi
    sed -i '/use_fully_qualified_names/d' /etc/sssd/sssd.conf
    echo "use_fully_qualified_names = False" | tee -a /etc/sssd/sssd.conf
    systemctl restart sssd
    pam-auth-update --enable mkhomedir --force
    if [[ -n "$umask" ]]; then
        sed -i "/.*pam_mkhomedir.so.*/ s/$/ umask=${umask}/" /etc/pam.d/common-session
    fi
    id "$adminuser" || logToScreen "AD Join failed" --error
    if [[ -n "$permUser" ]]; then
        IFS=',' read -ra ADDR <<<"$permUser"
        for i in "${ADDR[@]}"; do
            realm permit "$i"
        done

    fi

    if [[ -n "$permGroup" ]]; then
        IFS=',' read -ra ADDR <<<"$permGroup"
        for j in "${ADDR[@]}"; do
            realm permit -g "$j"
        done
    fi
}

function logToScreen() {
    clear
    if [[ "$2" = "--success" ]]; then
        printf '%s\n' "$(tput setaf 2)$1 $(tput sgr 0)"
    elif [[ "$2" = "--error" ]]; then
        printf '%s\n' "$(tput setaf 1)$1 $(tput sgr 0)"
        exit 1
    else
        printf '%s\n' "$(tput setaf 3)$1 $(tput sgr 0)"
    fi
    sleep 1
}

function enableSudo {
if [[ -n "$sudoUsers" ]]; then
        IFS=',' read -ra ADDR <<<"$sudoUsers"
        for i in "${ADDR[@]}"; do
            tee /etc/sudoers.d/adm_"$i" >/dev/null <<EOT
${i}   ALL=(ALL:ALL) ALL
EOT
        done

    fi
}

function helpMsg() {
    logToScreen "Help for AD Setup Script (Debian 10/11)
You can use the following Options:
  [-h] => Help Dialog
  [-u] [--adminuser] => Admin User for authentication
  [-d] [--ad-domain] => Realm you want to join
  [-p] [--homedir] => Overrides the home directory path
  [-s] [--shell] => Overrides the default shell
  [-m] [--umask] => Specify UMASK for the homedir of users
  [-a] [--allow-user] => Allow user(s) (comma seperated)
  [-r] [--allow-group] => Allow group(s) (comma seperated)
  [-e] [--enable-sudo] => Allow user(s) to have root privileges (SUDO)
More Documentation can be found on Github: https://github.com/marekbeckmann/debian-ad-join-script"
}

function getParams() {
    while test $# -gt 0; do
        case "$1" in
        -h | --help)
            helpMsg
            ;;
        -u | --adminuser)
            adminuser="$2"
            ;;
        -d | --ad-domain)
            realm="$2"
            ;;
        -p | --homedir)
            homedir="$2"
            ;;
        -s | --shell)
            shell="$2"
            ;;
        -m | --umask)
            umask="$2"
            ;;
        -a | --allow-user)
            permUser="$2"
            ;;
        -r | --allow-group)
            permGroup="$2"
            ;;
        --*)
            logToScreen "Unknown option $1" --error
            helpMsg
            exit 1
            ;;
        -e | --enable-sudo)
            sudoUsers="$2"
            ;;
        -*)
            logToScreen "Unknown option $1" --error
            helpMsg
            exit 1
            ;;
        esac
        shift
    done
}

init "$@"
