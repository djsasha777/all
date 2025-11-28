
enable

conf t

hostname BR11

crypto isakmp policy 10
 encr 3des
 hash md5
 authentication pre-share
 group 2
crypto isakmp key cisco123 address 10.0.0.2       

crypto ipsec transform-set Trset10 esp-3des esp-md5-hmac 
 mode tunnel

crypto map ToHQ 10 ipsec-isakmp 
 set peer 10.0.0.2
 set transform-set Trset10 
 match address 100

interface Tunnel0
 ip unnumbered FastEthernet3/0
 tunnel source 20.0.0.2
 tunnel destination 10.0.0.2

interface FastEthernet1/0
 ip address 20.0.0.2 255.255.255.0
 crypto map ToHQ
 no shutdown

interface FastEthernet2/0
 ip address 192.168.24.1 255.255.255.0
 no shutdown

interface FastEthernet3/0
 ip address 192.168.16.1 255.255.255.0
 no shutdown

router ospf 1
 network 20.0.0.0 0.255.255.255 area 0

router ospf 2
 network 192.168.16.0 0.0.15.255 area 0

access-list 100 permit gre host 20.0.0.2 host 10.0.0.2

end

wr
