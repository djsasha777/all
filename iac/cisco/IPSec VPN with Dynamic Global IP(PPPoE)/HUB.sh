enable

conf t

hostname HUB

crypto keyring VpnKeyring  
  pre-shared-key hostname SiteSPOKE1 key spoke1
  pre-shared-key hostname SiteSPOKE2 key spoke2

crypto isakmp policy 1
 hash md5
 authentication pre-share
 group 2
crypto isakmp profile ISAProfSPOKE1
   keyring VpnKeyring
   match identity host SiteSPOKE1
   virtual-template 1
crypto isakmp profile ISAProfSPOKE2
   keyring VpnKeyring
   match identity host SiteSPOKE2
   virtual-template 2

crypto ipsec transform-set TRSet esp-des esp-md5-hmac 
 mode tunnel

crypto ipsec profile IPSecProfSPOKE1
 set transform-set TRSet 
 set isakmp-profile ISAProfSPOKE1

crypto ipsec profile IPSecProfSPOKE2
 set transform-set TRSet 
 set isakmp-profile ISAProfSPOKE2

interface Loopback0
 ip address 192.168.127.1 255.255.255.252

interface Loopback1
 ip address 192.168.127.5 255.255.255.252

interface Ethernet1/0
 no ip address
 duplex half
 pppoe enable group global
 pppoe-client dial-pool-number 1
!
interface Ethernet1/1
 ip address 192.168.0.1 255.255.255.0
 ip nat inside
 ip virtual-reassembly in
 duplex half

interface Virtual-Template1 type tunnel
 ip unnumbered Loopback0
 tunnel mode ipsec ipv4
 tunnel protection ipsec profile IPSecProfSPOKE1

interface Virtual-Template2 type tunnel
 ip unnumbered Loopback1
 tunnel mode ipsec ipv4
 tunnel protection ipsec profile IPSecProfSPOKE2

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
 ppp chap hostname HUB1
 ppp chap password 0 HUB1PASS
 ppp ipcp dns request accept

router ospf 1
 network 192.168.0.0 0.0.0.255 area 0
 network 192.168.127.0 0.0.0.3 area 1
 network 192.168.127.4 0.0.0.3 area 2

ip nat inside source list 1 interface Dialer1 overload
ip route 0.0.0.0 0.0.0.0 Dialer1

access-list 1 permit 192.168.0.0 0.0.0.255
dialer-list 1 protocol ip permit

end

wr