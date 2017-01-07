#run as root
#for ubuntu 16.04

echo "please type domain name:"
read domain
echo "enter postfix password:"
read password

#set timezone to UTC
sudo  timedatectl set-timezone Etc/UTC

apt-get update

#install curl
apt-get install -y curl

#install git
apt-get install -y git

#install node version manager
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
source ~/.bashrc

#install node lts
nvm install --lts
#set as default
nvm alias default node

#install yarn package manager
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn

#install mongodb
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org
cat <<EOF >/lib/systemd/system/mongod.service
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
Documentation=https://docs.mongodb.org/manual

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target
EOF
systemctl enable mongod
systemctl start mongod


debconf-set-selections <<< "postfix postfix/mailname string main.$domain.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix


#setup domain key verification
sudo apt-get install -y opendkim opendkim-tools

cat <<EOF >/etc/opendkim.conf
root@main:/etc/dkimkeys# nano /etc/default/opendkim
root@main:/etc/dkimkeys# nano /etc/postfix/main.cf
root@main:/etc/dkimkeys# nano /etc/postfix/main.cf
root@main:/etc/dkimkeys# cat /etc/opendkim.conf


# This is a basic configuration that can easily be adapted to suit a standard
# installation. For more advanced options, see opendkim.conf(5) and/or
# /usr/share/doc/opendkim/examples/opendkim.conf.sample.

# Log to syslog
Syslog			yes
# Required to use local socket with MTAs that access the socket as a non-
# privileged user (e.g. Postfix)
UMask			002

# Sign for example.com with key in /etc/dkimkeys/dkim.key using
# selector '2007' (e.g. 2007._domainkey.example.com)
Domain			$domain
KeyFile			/etc/dkimkeys/dkim.key
Selector		mail

# Commonly-used options; the commented-out versions show the defaults.
Canonicalization	simple
#Mode			sv
#SubDomains		no
AutoRestart		yes
DNSTimeout		5


# Always oversign From (sign using actual From and a null From to prevent
# malicious signatures header fields (From and/or others) between the signer
# and the verifier.  From is oversigned by default in the Debian pacakge
# because it is often the identity key used by reputation systems and thus
# somewhat security sensitive.
OversignHeaders		From

##  ResolverConfiguration filename
##      default (none)
##
##  Specifies a configuration file to be passed to the Unbound library that
##  performs DNS queries applying the DNSSEC protocol.  See the Unbound
##  documentation at http://unbound.net for the expected content of this file.
##  The results of using this and the TrustAnchorFile setting at the same
##  time are undefined.
##  In Debian, /etc/unbound/unbound.conf is shipped as part of the Suggested
##  unbound package

# ResolverConfiguration     /etc/unbound/unbound.conf

##  TrustAnchorFile filename
##      default (none)
##
## Specifies a file from which trust anchor data should be read when doing
## DNS queries and applying the DNSSEC protocol.  See the Unbound documentation
## at http://unbound.net for the expected format of this file.

TrustAnchorFile       /usr/share/dns/root.key
EOF

cat <<EOF >/etc/default/opendkim
# Command-line options specified here will override the contents of
# /etc/opendkim.conf. See opendkim(8) for a complete list of options.
#DAEMON_OPTS=""
#
# Uncomment to specify an alternate socket
# Note that setting this will override any Socket value in opendkim.conf
# default:
#SOCKET="local:/var/run/opendkim/opendkim.sock"
# listen on all interfaces on port 54321:
#SOCKET="inet:54321"
# listen on loopback on port 12345:
SOCKET="inet:8891@localhost"
# listen on 192.0.2.1 on port 12345:
#SOCKET="inet:12345@192.0.2.1"
EOF

cat <<EOF >>/etc/postfix/main.cf

# DKIM
milter_default_action = accept
milter_protocol = 2
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
EOF

mkdir /etc/dkimkeys
cd /etc/dkimkeys
opendkim-genkey -t -s mail -d "$domain"

#start services
systemctl service opendkim enable
sudo service postfix restart
systemctl service postfix enable


#uncomment this to enable SMTP remotely
# postfix tls enable-server
# postfix tls enable-client
# sudo postconf -e 'smtpd_sasl_auth_enable = yes'

# cat <<EOF >/etc/postfix/sasl_passwd
# $domain mailer:$password
# EOF
# chown root:root /etc/postfix/sasl_passwd && chmod 600 /etc/postfix/sasl_passwd
# postmap hash:/etc/postfix/sasl_passwd

cat /etc/dkimkeys/dkim.key

echo "create the preceding txt record!";


