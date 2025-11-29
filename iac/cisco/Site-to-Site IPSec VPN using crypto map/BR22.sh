enable

conf t

hostname BR22

interface FastEthernet0/0
 ip address 192.168.32.2 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 192.168.33.1 255.255.255.0
 no shutdown

router ospf 1
 network 192.168.32.0 0.0.15.255 area 0

ip route 0.0.0.0 0.0.0.0 192.168.32.1

end

wr
