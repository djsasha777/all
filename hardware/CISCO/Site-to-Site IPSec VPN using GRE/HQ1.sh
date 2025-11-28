enable

conf t

hostname HQ1

crypto isakmp policy 10
 hash md5
 authentication pre-share

crypto isakmp policy 20
 encr 3des
 hash md5
 authentication pre-share
 group 2

crypto isakmp policy 30
 encr aes
 authentication pre-share
 group 2
crypto isakmp key cisco123 address 20.0.0.2       
crypto isakmp key cisco456 address 30.0.0.2       

crypto ipsec transform-set Trset10 esp-des esp-md5-hmac 
 mode tunnel
crypto ipsec transform-set Trset20 esp-3des esp-md5-hmac 
 mode tunnel
crypto ipsec transform-set Trset30 esp-aes esp-sha-hmac 
 mode tunnel

crypto map ToBR 10 ipsec-isakmp 
 set peer 20.0.0.2
 set transform-set Trset20 
 match address 101
crypto map ToBR 20 ipsec-isakmp 
 set peer 30.0.0.2
 set transform-set Trset30 
 match address 102

interface Tunnel0
 ip unnumbered FastEthernet3/0
 tunnel source 10.0.0.2
 tunnel destination 20.0.0.2

interface Tunnel1
 ip unnumbered FastEthernet3/0
 tunnel source 10.0.0.2
 tunnel destination 30.0.0.2

interface FastEthernet1/0
 ip address 10.0.0.2 255.255.255.0
 crypto map ToBR
 no shutdown

interface FastEthernet2/0
 ip address 192.168.8.1 255.255.255.0
 no shutdown

interface FastEthernet3/0
 ip address 192.168.0.1 255.255.255.0
 no shutdown

router ospf 1
 network 10.0.0.0 0.255.255.255 area 0

router ospf 2
 network 192.168.0.0 0.0.15.255 area 0

access-list 101 permit gre host 10.0.0.2 host 20.0.0.2
access-list 102 permit gre host 10.0.0.2 host 30.0.0.2

end

wr