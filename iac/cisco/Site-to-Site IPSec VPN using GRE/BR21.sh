enable

conf t

hostname BR21

crypto isakmp policy 10
 encr aes
 authentication pre-share
 group 2
crypto isakmp key cisco456 address 10.0.0.2       

crypto ipsec transform-set Trset10 esp-aes esp-sha-hmac 
 mode tunnel

crypto map ToHQ 10 ipsec-isakmp 
 set peer 10.0.0.2
 set transform-set Trset10 
 match address 100

interface Tunnel0
 ip unnumbered FastEthernet3/0
 tunnel source 30.0.0.2
 tunnel destination 10.0.0.2

interface FastEthernet1/0
 ip address 30.0.0.2 255.255.255.0
 crypto map ToHQ
 no shutdown

interface FastEthernet2/0
 ip address 192.168.40.1 255.255.255.0
 no shutdown

interface FastEthernet3/0
 ip address 192.168.32.1 255.255.255.0
 no shutdown

router ospf 1
 network 30.0.0.0 0.255.255.255 area 0

router ospf 2
 network 192.168.32.0 0.0.15.255 area 0

access-list 100 permit ip host 30.0.0.2 host 10.0.0.2

end

wr
