enable

conf t

hostname CustC2

interface FastEthernet0/0
 ip address 192.168.30.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.31.1 255.255.255.0
 no shutdown

router ospf 1
 network 192.168.30.0 0.0.0.255 area 0
 network 192.168.31.0 0.0.0.255 area 0

end

wr