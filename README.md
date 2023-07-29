# Simple Bash Script for Auto Installation ISP Config 3

Assume your domain is `example.com` and hostname is `server1`

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
- Create mailbox support@example.com
- Create mail alias webmaster@example.com destination to admin@example.com
- Create mail alias hostmaster@example.com destination to admin@example.com
- Create mail alias postmaster@example.com destination to admin@example.com
- Additional identities of admin@example.com for three aliases above.
- Roundcube and ISPConfig integration.

Thats all.

Required action:

- Buy domain name from your favourite registrar, then point Name Server to
  ns1.digitalocean.com, ns2.digitalocean.com, and ns3.digitalocean.com.
- Buy server (VPS) in DigitalOcean and select OS: `Debian 12`/`Ubuntu 22.04`.
  ATTENTION: give name your droplet as FQDN, example: server1.example.com for
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

Login as root.

```
sudo su
```

Download.

```
mkdir -p ~/bin
cd ~/bin
wget -q https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/ispconfig-autoinstaller.sh -O ispconfig-autoinstaller.sh
chmod a+x ispconfig-autoinstaller.sh
cd - >/dev/null
```

Make sure that directory `~/bin` has been include as `$PATH` in `~/.profile`.

```
command -v ispconfig-autoinstaller.sh >/dev/null || {
    PATH="$HOME/bin:$PATH"
    cat << 'EOF' >> ~/.profile
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
EOF
}
```

then feels free to execute command. You will be prompt to some required value.

```
ispconfig-autoinstaller.sh --fast
```

## Advanced Install

**Example 1.**

Save script to `/usr/local/bin`.

Download and execute.

```
cd /usr/local/bin
wget -q https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/ispconfig-autoinstaller.sh -O ispconfig-autoinstaller.sh
chmod a+x ispconfig-autoinstaller.sh
cd -
ispconfig-autoinstaller.sh --fast
```

All dependency script will be download to same location of `ispconfig-autoinstaller.sh`.
If you wish to store dependency to other location, use the environment variable
`BINARY_DIRECTORY` before execute the command.

Example: Store all script to `$HOME/bin`, then execute.

```
mkdir -p $HOME/bin
BINARY_DIRECTORY=$HOME/bin ispconfig-autoinstaller.sh --fast
```

**Example 2.**

Avoid prompt with non interractive mode with passing all required
argument of command `rcm-ispconfig-setup-variation{n}.sh` using double dash as
separator `--`.

```
ispconfig-autoinstaller.sh --fast \
    --variation 1
    -- \
    --timezone=Asia/Jakarta \
    --domain=systemix.id \
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
