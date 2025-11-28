#ser hostname
set system host-name ROUTER2

# Create user
set system login user root class super-user authentication plain-text-password
set system login user DJSASHA777 class operator authentication plain-text-password

#set ssh
set system services ssh
set system services ssh protocol-version v2
set system services ssh root-login deny
set system services ssh connection-limit 10
set system services ssh rate-limit 5
set system services telnet connection-limit 10
set system services telnet rate-limit 5

# SSH access limit for some network
set interfaces em0 unit 0 family inet filter input SSH
set firewall family inet filter SSH term SSH-accept from source-address 192.168.1.0/24
set firewall family inet filter SSH term SSH-accept from protocol tcp
set firewall family inet filter SSH term SSH-accept from destination-port ssh
set firewall family inet filter SSH term SSH-accept then accept
set firewall family inet filter SSH term SSH-deny from destination-port ssh
set firewall family inet filter SSH term SSH-deny then count Discard-SSH-Packets
set firewall family inet filter SSH term SSH-deny then discard

#set domain
set system domain-name example.domain.com

# set dns
set system name-server 8.8.8.8

# set password
# user - root, password - my common new password
set system root-authentication plain-text-password

