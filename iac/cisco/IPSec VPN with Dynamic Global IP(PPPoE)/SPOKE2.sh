enable

conf t

hostname SPOKE2

crypto isakmp policy 1
 hash md5
 authentication pre-share
 group 2

crypto isakmp peer address 100.1.1.1
 set aggressive-mode password spoke2
 set aggressive-mode client-endpoint fqdn SiteSPOKE2 

crypto ipsec transform-set TRSet esp-des esp-md5-hmac 
 mode tunnel

crypto ipsec profile IPSecProf
 set transform-set TRSet 

interface Loopback0
 ip address 192.168.127.6 255.255.255.252

interface Tunnel0
 ip unnumbered Loopback0
 tunnel source Ethernet1/0
 tunnel mode ipsec ipv4
 tunnel destination 100.1.1.1
 tunnel protection ipsec profile IPSecProf

interface Ethernet1/0
 ip address 192.168.250.2 255.255.255.0
 ip mtu 1454
 no shutdown

interface Ethernet1/1
 ip address 192.168.2.1 255.255.255.0
 no shutdown

router ospf 1
 network 192.168.2.0 0.0.0.255 area 2
 network 192.168.127.4 0.0.0.3 area 2

ip route 0.0.0.0 0.0.0.0 192.168.250.1

end

wr