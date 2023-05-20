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

## Prerequisite

```
sudo apt install wget
wget https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/installer.sh
chmod a+x installer.sh
./installer.sh
```

## Variation 1 (Debian 11)

```
export PATH=$HOME/bin:$PATH
gpl-ispconfig-setup-variation1.sh
```
