# Simple Bash Script for Auto Installation ISP Config 3

## Variant 1 - variation-1/gpl-ispconfig-variation1.sh

Assume your domain is example.com

This script will doing this for you:

- Create Website ISPConfig at https://cp.example.com
- Create Website PHPMyAdmin at https://db.example.com
- Create Website Roundcube at https://mail.example.com
- FQDN set as server1.example.com
- Create DNS record: A example.com
- Create DNS record: A server1.example.com
- Create DNS record: CNAME cp.example.com
- Create DNS record: CNAME db.example.com
- Create DNS record: CNAME mail.example.com
- Create DNS record: MX example.com to server1.example.com
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

Suggest action:

- Buy domain name from your favourite registrar, then point Name Server to
  ns1.digitalocean.com, ns2.digitalocean.com, and ns3.digitalocean.com.
- Buy server (VPS) in DigitalOcean and select OS: Debian 11.
  ATTENTION: give name your droplet as FQDN, example: server1.example.com.
- Generate token API in DigitalOcean Control Panel.

Download and execute this script inside server.

```
git clone https://github.com/ijortengab/ispconfig-autoinstaller
cd ispconfig-autoinstaller/variation-1
chmod a+x *
./gpl-ispconfig-variation1.sh \
    example.com \
    --autopopulate-ip-address \
    --digitalocean-token=<token> \
    --letsencrypt=digitalocean
```

You'll see these result:

```
Report

PHPMyAdmin: https://db.bta.my.id
 - username: pma
   password: ...
 - username: roundcube
   password: ...
 - username: ispconfig
   password: ...

Roundcube: https://mail.bta.my.id
 - username: admin
   password: ...

ISPConfig: https://cp.bta.my.id
 - username: admin
   password: ...
```

## Addon domain

Assume your next domain is `other-example.com` and you want to add on existing domain (example.com).

Just execute this script agan inside server.

Download and execute this script inside server.

```
./gpl-ispconfig-variation1.sh \
    other-example.com \
    --autopopulate-ip-address \
    --digitalocean-token=<token> \
    --letsencrypt=digitalocean
```
