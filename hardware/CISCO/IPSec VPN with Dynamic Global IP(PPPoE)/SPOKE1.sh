enable

conf t

hostname SPOKE1

crypto isakmp policy 1
 hash md5
 authentication pre-share
 group 2

crypto isakmp peer address 100.1.1.1
 set aggressive-mode password spoke1
 set aggressive-mode client-endpoint fqdn SiteSPOKE1 

crypto ipsec transform-set TRSet esp-des esp-md5-hmac 
 mode tunnel

crypto ipsec profile IPSecProf
 set transform-set TRSet 

interface Loopback0
 ip address 192.168.127.2 255.255.255.252

interface Tunnel0
 ip unnumbered Loopback0
 tunnel source Dialer1
 tunnel mode ipsec ipv4
 tunnel destination 100.1.1.1
 tunnel protection ipsec profile IPSecProf

interface Ethernet1/0
 no ip address
 pppoe enable group global
 pppoe-client dial-pool-number 1
 no shutdown

interface Ethernet1/1
 ip address 192.168.1.1 255.255.255.0
 ip nat inside
 ip virtual-reassembly in
 no shutdown

interface Dialer1
 ip address negotiated
 ip mtu 1454
 ip nat outside
 ip virtual-reassembly in
 encapsulation ppp
 dialer pool 1
 dialer idle-timeout 0
 dialer-group 1
 ppp authentication chap callin
 ppp chap hostname SPOKE1
 ppp chap password 0 SPOKE1PASS
 ppp ipcp dns request accept

router ospf 1
 network 192.168.1.0 0.0.0.255 area 1
 network 192.168.127.0 0.0.0.3 area 1

ip nat inside source list 1 interface Dialer1 overload
ip route 0.0.0.0 0.0.0.0 Dialer1

access-list 1 permit 192.168.1.0 0.0.0.255
dialer-list 1 protocol ip permit

end

wr