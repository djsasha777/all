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

ip route 192.168.0.0 255.255.240.0 FastEthernet1/0
ip route 192.168.16.0 255.255.240.0 FastEthernet1/0

access-list 100 permit ip 192.168.32.0 0.0.15.255 192.168.0.0 0.0.15.255
access-list 100 permit ip 192.168.32.0 0.0.15.255 192.168.16.0 0.0.15.255

end

wr