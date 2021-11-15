# Simple Bash Script for Auto Installation ISP Config 3

## Variant 1 - debian10.digitalocean.sh

Assume your domain is example.com

This script will doing this for you:

- Create Website ISPConfig at https://cp.example.com
- Create Website PHPMyAdmin at https://db.example.com
- Create Website Roundcube at https://mail.example.com
- FQCDN set as server.example.com
- Create DNS record: A example.com
- Create DNS record: A server.example.com
- Create DNS record: CNAME cp.example.com
- Create DNS record: CNAME db.example.com
- Create DNS record: CNAME mail.example.com
- Create DNS record: MX example.com to server.example.com
- Create DNS record: TXT DKIM for example.com
- Create DNS record: TXT DMARC for example.com
- Create DNS record: TXT SPF for example.com
- Create mailbox admin@example.com
- Create mail alias webmaster@example.com destination to admin@example.com
- Create mail alias hostmaster@example.com destination to admin@example.com
- Create mail alias postmaster@example.com destination to admin@example.com
- Additional identities of admin@example.com for three aliases above.
- Roundcube and ISPConfig integration.

Thats all.

Required action:

- Buy domain name from your favourite registrar, then point Name Server to
  ns1.digitalocean.com, ns2.digitalocean.com, and ns3.digitalocean.com.
- Buy server (VPS) in DigitalOcean and select OS: Debian 10.
  ATTENTION: give name your droplet as FQCDN, example: server.example.com.
- Generate token API in DigitalOcean Control Panel.

Download and execute this script inside server.

```
wget https://raw.githubusercontent.com/ijortengab/ispconfig-autoinstaller/master/debian10.digitalocean.sh
bash debian10.digitalocean.sh
```

You'll see these result:

```
# Credentials
PHPMyAdmin: https://db.example.com
   - username: ispconfig
     password: -
   - username: pma
     password: -
   - username: roundcube
     password: -
Roundcube: https://mail.example.com
   - username: admin
     password: -
ISP Config: https://cp.example.com
   - username: admin
     password: -
```

## Add on domain

Assume your next domain is `other-example.com` and you want to add on existing domain (example.com).

Download and execute this script inside server.

```
wget https://raw.githubusercontent.com/ijortengab/ispconfig-autoinstaller/master/addon-mail.digitalocean.sh
bash addon-mail.digitalocean.sh
```
