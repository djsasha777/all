enable

conf t

hostname R2

interface FastEthernet0/0.10
 encapsulation dot1Q 10
 ip address 192.168.10.254 255.255.255.0
 no shutdown

interface FastEthernet0/0.20
 encapsulation dot1Q 20
 ip address 192.168.20.254 255.255.255.0
 no shutdown

interface FastEthernet0/0.30
 encapsulation dot1Q 30
 ip address 192.168.30.254 255.255.255.0
 no shutdown

router ospf 1
 network 0.0.0.0 255.255.255.255 area 0

end

wr