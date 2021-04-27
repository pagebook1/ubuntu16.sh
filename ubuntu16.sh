#!/bin/sh
#COMMAND: sudo wget https://www.dropbox.com/s/1fq093z0gxcvsv1/ubuntu16.sh && chmod +x ubuntu16.sh && bash ./ubuntu16.sh
echo "ServerAliveInterval 60" >> /etc/ssh/ssh_config && service ssh restart && service sshd restart
IPADDRESS=$(wget -qO- ipv4.icanhazip.com)
IPADD="s/ipaddresxxx/$IPADDRESS/g";
# clean repo
apt-get clean
# update repo
echo \> Updating the System...
apt-get update > /dev/null
# full upgrade
apt-get -y full-upgrade > /dev/null
echo \> Done!!
echo "Enter your Server Name: "
read servername
echo "Enter your Email Address: "
read email
#install webmin
sed -i '$ a deb http://download.webmin.com/download/repository sarge contrib' /etc/apt/sources.list
wget http://www.webmin.com/jcameron-key.asc
sudo apt-key add jcameron-key.asc
sudo apt-get update
# install needs
echo \> Installing Openvpn..
apt-get -y install openvpn > /dev/null
echo \> Done..
sleep 1
echo \> Installing Easy-RSA..
apt-get -y install easy-rsa > /dev/null
echo \> Done..
sleep 1
echo \> Installing UFW..
apt-get -y install ufw > /dev/null
echo \> Done..
sleep 1
echo \> Installing Python..
apt-get -y install python
echo \> Done..
sleep 1
echo \> Installing Squid..
apt-get -y install squid > /dev/null
echo \> Done..
sleep 1
echo \> Installing ZIP..
apt-get -y install zip > /dev/null
echo \> Done..
sleep 1
echo \> Installing webmin
sudo apt-get install -y webmin
echo \> Done!!
sleep 1
echo \> Installing lighthttpd
sudo apt-get -y install lighttpd
echo \> Done..
sleep 1

#changing ssh port
echo \> Changing SSH PORT for Security
sed -i '5d' /etc/ssh/sshd_config
echo 'Port = 1025' >> /etc/ssh/sshd_config
echo \> Done...
sleep 1
# openvpn
echo \> Configuring OpenVPN Server Certificate...
cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir /etc/openvpn/easy-rsa/keys
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="PH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="LUC"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="Lucena City"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_ORG="KEV"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="'$email'"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyOrganizationalUnit"|export KEY_OU="kevinbeetle"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="'$servername'"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU=changeme|export KEY_OU='$servername'|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_SIZE=2048|export KEY_SIZE=1024|' /etc/openvpn/easy-rsa/vars
# create diffie-helman pem
openssl dhparam -out /etc/openvpn/dh1024.pem 1024 2> /dev/null
# create pki
if [ ! -f /etc/openvpn/easy-rsa/openssl.cnf ]
then
    cp /etc/openvpn/easy-rsa/openssl-0.9.8.cnf /etc/openvpn/easy-rsa/openssl.cnf
    else
    echo openssl.cnf exists!
    fi 
cd /etc/openvpn/easy-rsa
. ./vars > /dev/null
./clean-all
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $* > /dev/null 2>&1
# create key server
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server > /dev/null 2>&1
# setting key cn
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" client > /dev/null 2>&1
cd
# copy /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn
cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn/server.crt
cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn/server.key
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt
sleep 1
echo \> Done!!
# setting TCP server
sleep 1
echo \> Configuring OPENVPN TCP Server
cat > /etc/openvpn/tcp-server.conf <<-END
port 110
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh1024.pem
client-cert-not-required
username-as-common-name
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
server 192.168.100.0 255.255.255.0
ifconfig-pool-persist ipp.txt
persist-key
persist-tun
status openvpn-status.log
log openvpn.log
verb 0
cipher none
auth none
keepalive 1 10
reneg-sec 0
tcp-nodelay
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
END
echo \> Done!..
sleep 1
echo \> Configuring OPENVPN UDP Server
# setting UDP server
cat > /etc/openvpn/udp-server.conf <<-END
port 443
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh1024.pem
client-cert-not-required
username-as-common-name
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
server 192.168.110.0 255.255.255.0
ifconfig-pool-persist ipp.txt
persist-key
persist-tun
status openvpn-status.log
log openvpn.log
verb 0
cipher none
auth none
keepalive 1 10
reneg-sec 0
tcp-nodelay
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
END
echo \> Done !!!
sleep 1
echo \> Generating OPENVPN TCP Client Config
# create TCP openvpn config
cat > /root/tcp-client.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS
port 110
persist-key
persist-tun
dev tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
http-proxy $IPADDRESS 8085

END
echo '<ca>' >> /root/tcp-client.ovpn
cat /etc/openvpn/easy-rsa/keys/ca.crt >> /root/tcp-client.ovpn
echo '</ca>' >> /root/tcp-client.ovpn
echo '<cert>' >> /root/tcp-client.ovpn
awk 'NR>51' /etc/openvpn/easy-rsa/keys/client.crt >> /root/tcp-client.ovpn
echo '</cert>' >> /root/tcp-client.ovpn
echo '<key>' >> /root/tcp-client.ovpn
cat /etc/openvpn/easy-rsa/keys/client.key >> /root/tcp-client.ovpn
echo '</key>' >> /root/tcp-client.ovpn
echo \> Done!!!
sleep 1
echo \> Generating OPENVPN UDP Config
# create UDP openvpn config
cat > /root/udp-client.ovpn <<-END
client
dev tun
proto udp
remote $IPADDRESS
port 443
persist-key
persist-tun
dev tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0

END
echo '<ca>' >> /root/udp-client.ovpn
cat /etc/openvpn/easy-rsa/keys/ca.crt >> /root/udp-client.ovpn
echo '</ca>' >> /root/udp-client.ovpn
echo '<cert>' >> /root/udp-client.ovpn
awk 'NR>51' /etc/openvpn/easy-rsa/keys/client.crt >> /root/udp-client.ovpn
echo '</cert>' >> /root/udp-client.ovpn
echo '<key>' >> /root/udp-client.ovpn
cat /etc/openvpn/easy-rsa/keys/client.key >> udp-client.ovpn
echo '</key>' >> /root/udp-client.ovpn
echo \> DONE!
sleep 1
# setting iptables
cat > /etc/iptables.up.rules <<-END
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -j SNAT --to-source ipaddresxxx
-A POSTROUTING -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.1.0.0/24 -o eth0 -j MASQUERADE
COMMIT

*filter
:INPUT ACCEPT [19406:27313311]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [9393:434129]
:fail2ban-ssh - [0:0]
-A FORWARD -i eth0 -o ppp0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i ppp0 -o eth0 -j ACCEPT
-A INPUT -p ICMP --icmp-type 8 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 53 -j ACCEPT
-A INPUT -p tcp --dport 1025  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 110  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 110  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 8085  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 8085  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 443  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 443  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 3111  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 3111  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 4111  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 4111  -m state --state NEW -j ACCEPT
COMMIT

*raw
:PREROUTING ACCEPT [158575:227800758]
:OUTPUT ACCEPT [46145:2312668]
COMMIT

*mangle
:PREROUTING ACCEPT [158575:227800758]
:INPUT ACCEPT [158575:227800758]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [46145:2312668]
:POSTROUTING ACCEPT [46145:2312668]
COMMIT
END
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i $IPADD /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules
# disable ipv6
echo \> Disabling IPV6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
echo \> Done
sleep 1
# add dns server ipv4
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf
sed -i '$ i\echo "nameserver 1.1.1.1" > /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 1.0.0.1" >> /etc/resolv.conf' /etc/rc.local
sed -i '$ i\sleep 10' /etc/rc.local
sed -i '$ i\for p in $(pgrep openvpn); do renice -n -20 -p $p; done' /etc/rc.local
# set time GMT +8
ln -fs /usr/share/zoneinfo/Asia/Manila /etc/localtime
# set ipv4 forward
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
# restart apps
service openvpn stop
service openvpn start
# tcp tweaks
echo "fs.file-max = 51200" >> /etc/sysctl.conf
echo "net.core.rmem_max = 67108864" >> /etc/sysctl.conf
echo "net.core.wmem_max = 67108864" >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog = 250000" >> /etc/sysctl.conf
echo "net.core.somaxconn = 4096" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 1200" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 10000 65000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 8192" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 5000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
echo "net.ipv4.tcp_mem = 25600 51200 102400" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 67108864" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 67108864" >> /etc/sysctl.conf
echo "net.ipv4.tcp_mtu_probing = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = hybla" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_all=1" >> /etc/sysctl.conf

# configure squid
cat > /etc/squid/squid.conf <<-END
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst ipaddresxxx-ipaddresxxx/32
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 8085
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname $servername
END
sed -i $IPADD /etc/squid/squid.conf;
echo /> Configure webmin
rm -f /etc/webmin/miniserv.conf
cat > /etc/webmin/miniserv.conf <<-END
port=3111
root=/usr/share/webmin
mimetypes=/usr/share/webmin/mime.types
addtype_cgi=internal/cgi
realm=Webmin Server
logfile=/var/webmin/miniserv.log
errorlog=/var/webmin/miniserv.error
pidfile=/var/webmin/miniserv.pid
logtime=168
ssl=0
no_ssl2=1
no_ssl3=1
no_tls1=1
no_tls1_1=1
ssl_honorcipherorder=1
no_sslcompression=1
env_WEBMIN_CONFIG=/etc/webmin
env_WEBMIN_VAR=/var/webmin
atboot=1
logout=/etc/webmin/logout-flag
listen=10000
denyfile=\.pl$
log=1
blockhost_failures=5
blockhost_time=60
syslog=1
ipv6=1
session=1
premodules=WebminCore
server=MiniServ/1.973
userfile=/etc/webmin/miniserv.users
keyfile=/etc/webmin/miniserv.pem
passwd_file=/etc/shadow
passwd_uindex=0
passwd_pindex=1
passwd_cindex=2
passwd_mindex=4
passwd_mode=0
preroot=authentic-theme
passdelay=1
cipher_list_def=1
failed_script=/etc/webmin/failed.pl
logout_script=/etc/webmin/logout.pl
login_script=/etc/webmin/login.pl
sudo=1
error_handler_404=404.cgi
error_handler_403=403.cgi
error_handler_401=401.cgi
nolog=\/stats\.cgi\?xhr\-stats\=general

END
echo CONFIGURE WEBSERVER
cat > /etc/web.sh <<-END
#!/bin/sh
service openvpn@udp-server start && service openvpn@tcp-server start
END
echo "@reboot root sh /etc/./web.sh" >> /etc/crontab
sleep 1
#webserver enable and change port
echo \> CONFIGURE WEB SERVER
sed -i '15d' /etc/lighttpd/lighttpd.conf
echo 'server.port                 = 4111' >> /etc/lighttpd/lighttpd.conf
sudo systemctl start lighttpd
sudo systemctl enable lighttpd
echo  \> Disable Ping
sleep 1
echo Applying Menu..
cd /usr/local/bin/
wget "https://github.com/pagebook1/ubuntu16.sh/raw/main/premiummenu.zip" 
unzip premiummenu.zip
chmod +x /usr/local/bin/premiummenu/*
echo "export PATH=$PATH:/usr/local/bin/premiummenu/" >> /etc/profile

echo \> Remove password Complexity
sed -i '25,26p' /etc/pam.d/common-password
sed -i " 25i password        [success=1 default=ignore]      pam_unix.so minlen=1 sha512" /etc/pam.d/common-password

cd /root/
zip /var/www/html/openvpnconfig.zip tcp-client.ovpn udp-client.ovpn
cp udp-client.ovpn /var/www/html/udp-client.ovpn && cp tcp-client.ovpn /var/www/html/tcp-client.ovpn
#make html download files
cat > /var/www/html/index.html <<-END
<p>Download your zip <a href="/openvpnconfig.zip">Files Here</p>
<p>Download your <a href="/tcp-client.ovpn">TCP Files Here</p>
<p>Download your <a href="/udp-client.ovpn">UDP Files Here</p>
END
echo =============== VPS DESCRIPTION =======================
echo SSH: 1025
echo OPENVPN: TCP 110 UDP 443
echo Squid: 8085
echo WEBMIN: $IPADDRESS:3111
echo Download Configs: $IPADDRESS:4111
echo \> Press Enter to Reboot
read reboot
reboot
