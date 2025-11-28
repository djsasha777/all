enable

conf t

hostname BR12

interface FastEthernet0/0
 ip address 192.168.16.2 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 192.168.17.1 255.255.255.0
 no shutdown

router ospf 1
 network 192.168.16.0 0.0.15.255 area 0

end

wr
