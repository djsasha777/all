#!/bin/bash
yum update
yum install curl nano mc net-tools bind-utils network-scripts iptables-services chrony epel-release dnf-automatic iftop htop atop lsof wget bzip2 traceroute gdisk
sed 's/SELINUX=enabled/SELINUX=disabled/' /etc/sysconfig/selinux
setenforce 0
rm /etc/sysconfig/network-scripts/ifcfg-eth0
touch /etc/sysconfig/network-scripts/ifcfg-eth0
cat >> /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
TYPE="Ethernet"
BOOTPROTO="none"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
NAME="eth0"
DEVICE="eth0"
ONBOOT="yes"
IPADDR=192.168.1.117
DNS1=192.168.167.1
PREFIX=24
GATEWAY=192.168.167.1
EOF
systemctl restart network
systemctl stop firewalld
systemctl disable firewalld
rm '/etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service'
rm '/etc/systemd/system/basic.target.wants/firewalld.service'
systemctl enable iptables
touch /etc/iptables.sh
cat >> /etc/iptables.sh <<EOF
#!/bin/bash
# global intefrace
export WAN=eth0
export WAN_IP=192.168.1.117
# clean iptables
iptables -F
iptables -F -t nat
iptables -F -t mangle
iptables -X
iptables -t nat -X
iptables -t mangle -X
# drop all non cnown policies
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
# allow loopback trafic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# allow outgoing connection of a server
iptables -A OUTPUT -o $WAN -j ACCEPT
# drop non inicialized connections
iptables -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
# allow new connections
iptables -A OUTPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
# allow forward
iptables -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
# switch on fragmentation
iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
# drop invalid packets
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP
# drop
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A OUTPUT -p tcp ! --syn -m state --state NEW -j DROP
# allow ping 
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
# open ssh http https ports
iptables -A INPUT -i $WAN -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i $WAN -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i $WAN -p tcp --dport 443 -j ACCEPT
# logs
iptables -N undef_in
iptables -N undef_out
iptables -N undef_fw
iptables -A INPUT -j undef_in
iptables -A OUTPUT -j undef_out
iptables -A FORWARD -j undef_fw
iptables -A undef_in -j LOG --log-level info --log-prefix "-- IN -- DROP "
iptables -A undef_in -j DROP
iptables -A undef_out -j LOG --log-level info --log-prefix "-- OUT -- DROP "
iptables -A undef_out -j DROP
iptables -A undef_fw -j LOG --log-level info --log-prefix "-- FW -- DROP "
iptables -A undef_fw -j DROP
# save rules
/sbin/iptables-save  > /etc/sysconfig/iptables
EOF
chmod 0740 /etc/iptables.sh
cat "Port 25333" >> /etc/ssh/sshd_config
cat "PermitRootLogin yes." >> /etc/ssh/sshd_config
cat "iptables -A INPUT -i $WAN -p tcp --dport 22 -j ACCEPT" >> /etc/iptables.sh
systemctl restart sshd

timedatectl set-timezone Europe/Moscow
systemctl start chronyd
systemctl enable chronyd
systemctl enable --now dnf-automatic.timer

