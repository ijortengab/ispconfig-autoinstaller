# Simple Bash Script for Auto Installation ISP Config 3

Assume your domain is `ijortengab.id` and hostname is `server1`

This script will doing this for you:

- FQDN set as server1.ijortengab.id
- Create Website ISPConfig at https://cp.ijortengab.id
- Create Website PHPMyAdmin at https://db.ijortengab.id
- Create Website Roundcube at https://mail.ijortengab.id
- Create mailbox admin@ijortengab.id
- Create mailbox support@ijortengab.id
- Create mail alias webmaster@ijortengab.id destination to admin@ijortengab.id
- Create mail alias hostmaster@ijortengab.id destination to admin@ijortengab.id
- Create mail alias postmaster@ijortengab.id destination to admin@ijortengab.id
- Additional identities of admin@ijortengab.id for three aliases above.
- Roundcube and ISPConfig integration.

Thats all.

## VPS DigitalOcean

If you use VPS from DigitalOcean, there some additional action:

- Create DNS record: A ijortengab.id
- Create DNS record: A server1.ijortengab.id
- Create DNS record: CNAME cp.ijortengab.id
- Create DNS record: CNAME db.ijortengab.id
- Create DNS record: CNAME mail.ijortengab.id
- Create DNS record: MX ijortengab.id to server1.ijortengab.id
- Create DNS record: TXT DKIM for ijortengab.id
- Create DNS record: TXT DMARC for ijortengab.id
- Create DNS record: TXT SPF for ijortengab.id

Required action:

- Buy domain name from your favourite registrar, then point Name Server to
  ns1.digitalocean.com, ns2.digitalocean.com, and ns3.digitalocean.com.
- Buy server (VPS) in DigitalOcean and select OS: `Debian 12`/`Ubuntu 22.04`.
  ATTENTION: give name your droplet as FQDN, example: server1.ijortengab.id for
  correct PTR record.
- Generate token API in DigitalOcean Control Panel.

Download and execute this script inside server.

## Prerequisite

Login as root.

```
apt update
apt install wget -y
```

To avoid interruption because of kernel update, it is recommend to restart
machine after upgrade if you start from empty virtual machine instance.

```
apt upgrade -y
init 6
```

## Quick Mode Install

Login as root. Download then put in PATH (`/usr/local/bin`).

```
sudo su
wget -q https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/ispconfig-autoinstaller.sh -O ispconfig-autoinstaller.sh
chmod a+x ispconfig-autoinstaller.sh
mv ispconfig-autoinstaller.sh -t /usr/local/bin
```

then feels free to execute command. You will be prompt to some required value.

```
ispconfig-autoinstaller.sh --fast
```

## Dependency Storage Location

All dependency script will be download to same location of `ispconfig-autoinstaller.sh`.
If you wish to store dependency to other location, use the environment variable
`BINARY_DIRECTORY` before execute the command.

Example: Store all script to `$HOME/bin`, then execute.

```
mkdir -p $HOME/bin
BINARY_DIRECTORY=$HOME/bin ispconfig-autoinstaller.sh --fast
```

## Non Interactive Mode

Avoid prompt with non interractive mode with passing all required
argument of command `rcm-ispconfig-setup-variation{n}.sh` using double dash as
separator `--`.

```
ispconfig-autoinstaller.sh --fast \
    --variation 1
    -- \
    --timezone=Asia/Jakarta \
    --domain=ijortengab.id \
    --hostname=server1 \
    --ip-address=auto \
    --digitalocean-token=$TOKEN \
    --non-interactive
```

## Available Variation

**Variation 1**

 > Variation 1.
 > Debian 11, ISPConfig 3.2.7, PHPMyAdmin 5.2.0, Roundcube 1.6.0, PHP 7.4,
 > DigitalOcean DNS.

**Variation 2**

 > Variation 2.
 > Ubuntu 22.04, ISPConfig 3.2.7, PHPMyAdmin 5.2.0, Roundcube 1.6.0, PHP 7.4,
 > DigitalOcean DNS.

**Variation 3**

 > Variation 3.
 > Debian 12, ISPConfig 3.2.10, PHPMyAdmin 5.2.1, Roundcube 1.6.2, PHP 8.1,
 > DigitalOcean DNS.
