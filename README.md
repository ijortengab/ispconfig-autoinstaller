# ISPConfig Auto Installer

The extension of `rcm`.

Assume your domain is `ijortengab.id` and hostname is `server1`

This script will doing this for you:

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

Login as root, then make sure `wget` command is exist.

```
apt update
apt install -y wget
```

If you start from empty virtual machine instance, it is recommend to upgrade
then restart machine to avoid interruption because of kernel update.

```
apt upgrade -y
init 6
```

## Install

Download `rcm` from Github.

```
wget git.io/rcm
chmod a+x rcm
```

You can put `rcm` file anywhere in $PATH:

```
mv rcm -t /usr/local/bin
```

## Install ISPConfig Extension

Install `ispconfig` extension.

```
rcm install ispconfig
```

Enter value for `--url` option:

```
https://github.com/ijortengab/ispconfig-autoinstaller
```

Skip value for `--path` option. We use the default value.

## How to Use

Feels free to execute `ispconfig` command. You will be prompt to some required value.

```
rcm ispconfig
```

## Tips

Always fast.

```
alias rcm='rcm --fast'
```
