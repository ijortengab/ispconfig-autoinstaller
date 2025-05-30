# ISPConfig Auto Installer

The extension of `rcm`.

Assume your domain is `example.com` and hostname is `server1`, this extension will doing this for you:

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

Download `rcm` from Github, then set script as executable, then put anywhere in `$PATH`.

Use one liner command below:

```
wget git.io/rcm && chmod a+x rcm && mv rcm -t /usr/local/bin
```

Verify by execute the `rcm` command.

```
rcm
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

## DNS records

### VPS Generic

You have to add DNS records manually (except DigitalOcean VPS):

- A Record of `example.com` point to your VPS IP Address
- A Record of `server1.example.com` point to your VPS IP Address
- CNAME Record of `cp.example.com` alias to `example.com`
- CNAME Record of `db.example.com` alias to `example.com`
- CNAME Record of `mail.example.com` alias to `example.com`
- MX Record of `example.com` handled by `server1.example.com`

### VPS DigitalOcean

If you use VPS from DigitalOcean and use DigitalOcean DNS, there some additional
action automatically:

- Create DNS record: A example.com
- Create DNS record: A server1.example.com
- Create DNS record: CNAME cp.example.com
- Create DNS record: CNAME db.example.com
- Create DNS record: CNAME mail.example.com
- Create DNS record: MX example.com to server1.example.com
- Create DNS record: TXT DKIM for example.com
- Create DNS record: TXT DMARC for example.com
- Create DNS record: TXT SPF for example.com

Prerequisite action:

- Buy domain name from your favourite registrar, then point Name Server to
  ns1.digitalocean.com, ns2.digitalocean.com, and ns3.digitalocean.com.
- Buy server (VPS) in DigitalOcean and select OS: `Debian 12`/`Ubuntu 22.04`.
  ATTENTION: give name your droplet as FQDN, example: server1.example.com for
  correct PTR record.
- Generate token API in DigitalOcean Control Panel.

## Add On Domain

Assume your next domain is `example.org`, this extension will doing this for you:

- Create Website ISPConfig at https://cp.example.org
- Create Website PHPMyAdmin at https://db.example.org
- Create Website Roundcube at https://mail.example.org
- Create mailbox admin@example.org
- Create mailbox support@example.org
- Create mail alias webmaster@example.org destination to admin@example.org
- Create mail alias hostmaster@example.org destination to admin@example.org
- Create mail alias postmaster@example.org destination to admin@example.org
- Additional identities of admin@example.org for three aliases above.
- Roundcube and ISPConfig integration.

You have to add DNS records manually (except DigitalOcean VPS):

- A Record of `example.org` point to your VPS IP Address
- CNAME Record of `cp.example.org` alias to `example.org`
- CNAME Record of `db.example.org` alias to `example.org`
- CNAME Record of `mail.example.org` alias to `example.org`

Attention for MX Record, pointing MX record to your primary server.
- MX Record of `example.org` handled by `server1.example.com`
