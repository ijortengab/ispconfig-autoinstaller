# Simple Bash Script for Auto Installation ISP Config 3

Assume your domain is example.com

This script will doing this for you:

- Create Website ISPConfig at https://cp.example.com
- Create Website PHPMyAdmin at https://db.example.com
- Create Website Roundcube at https://mail.example.com
- FQDN set as $hostname.example.com
- Create DNS record: A example.com
- Create DNS record: A $hostname.example.com
- Create DNS record: CNAME cp.example.com
- Create DNS record: CNAME db.example.com
- Create DNS record: CNAME mail.example.com
- Create DNS record: MX example.com to $hostname.example.com
- Create DNS record: TXT DKIM for example.com
- Create DNS record: TXT DMARC for example.com
- Create DNS record: TXT SPF for example.com
- Create mailbox admin@example.com
- Create mailbox support@example.com
- Create mail alias webmaster@example.com destination to admin@example.com
- Create mail alias hostmaster@example.com destination to admin@example.com
- Create mail alias postmaster@example.com destination to admin@example.com
- Additional identities of admin@example.com for three aliases above.
- Roundcube and ISPConfig integration.

Thats all.

Suggest action:

- Buy domain name from your favourite registrar, then point Name Server to
  ns1.digitalocean.com, ns2.digitalocean.com, and ns3.digitalocean.com.
- Buy server (VPS) in DigitalOcean and select OS: `Debian 11`/`Ubuntu 22.04`.
  ATTENTION: give name your droplet as FQDN, example: $hostname.example.com.
- Generate token API in DigitalOcean Control Panel.

Download and execute this script inside server.

## Quick Mode Install

You will be prompt to some required value.

```
cd /tmp && wget -q https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/ispconfig-autoinstaller.sh -O ispconfig-autoinstaller.sh && sudo bash ispconfig-autoinstaller.sh
```

## Advanced Install

Alternative 1. Change binary directory.

```
cd /tmp
wget -q https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/ispconfig-autoinstaller.sh -O ispconfig-autoinstaller.sh
chmod a+x ispconfig-autoinstaller.sh
sudo BINARY_DIRECTORY=/usr/local/bin ./ispconfig-autoinstaller.sh
```

Alternative 2. Pass some argument to setup.

```
cd /tmp
wget -q https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/ispconfig-autoinstaller.sh -O ispconfig-autoinstaller.sh
chmod a+x ispconfig-autoinstaller.sh
sudo BINARY_DIRECTORY=/usr/local/bin ./ispconfig-autoinstaller.sh -- --timezone=Asia/Jakarta
```

Alternative 3. Fast version.

```
cd /tmp
wget -q https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/ispconfig-autoinstaller.sh -O ispconfig-autoinstaller.sh
chmod a+x ispconfig-autoinstaller.sh
sudo BINARY_DIRECTORY=/usr/local/bin ./ispconfig-autoinstaller.sh --fast
```
