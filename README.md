# ISPConfig Auto Installer

The extension of `rcm`.

## Prerequisite

Login as root.

```
su -
```

If you start from empty virtual machine instance, it is recommend to upgrade
then restart machine to avoid interruption because of kernel update.

```
apt update -y
apt upgrade -y
init 6
```

Make sure `wget` command is exist.

```
apt install -y wget
```

## Install

### rcm

Download `rcm` from Github.

```
wget git.io/rcm
chmod a+x rcm
```

You can put `rcm` file anywhere in `$PATH`:

```
mv rcm -t /usr/local/bin
```

Always fast.

```
alias rcm='rcm --fast'
```

### rcm-ispconfig

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

Assume your domain is `example.com` and hostname is `node1`

This script will doing this for you:

- Create Website ISPConfig at https://cp.example.com
- Create Website PHPMyAdmin at https://db.example.com
- Create Website Roundcube at https://mail.example.com
- Create mailbox admin@example.com
- Create mailbox support@example.com
- Create mail alias webmaster@example.com destination to admin@example.com
- Create mail alias hostmaster@example.com destination to admin@example.com
- Create mail alias postmaster@example.com destination to admin@example.com
- Additional identities of admin@example.com for three aliases above.
- Roundcube and ISPConfig integration.

Thats all.

## VPS DigitalOcean

If you use VPS from DigitalOcean and use DigitalOcean DNS, there some additional
action:

- Create DNS record: A example.com
- Create DNS record: A node1.example.com
- Create DNS record: CNAME cp.example.com
- Create DNS record: CNAME db.example.com
- Create DNS record: CNAME mail.example.com
- Create DNS record: MX example.com to node1.example.com
- Create DNS record: TXT DKIM for example.com
- Create DNS record: TXT DMARC for example.com
- Create DNS record: TXT SPF for example.com

Note:

- Buy domain name from your favourite registrar, then point Name Server to
  ns1.digitalocean.com, ns2.digitalocean.com, and ns3.digitalocean.com.
- Buy server (VPS) in DigitalOcean and select OS: `Debian 12`/`Ubuntu 22.04`.
  ATTENTION: give name your droplet as FQDN, example: node1.example.com for
  correct PTR record.
- Generate token API in DigitalOcean Control Panel.

Download and execute this command inside server.
