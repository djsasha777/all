enable

conf t

hostname R3

interface FastEthernet0/0
 ip address 192.168.23.3 255.255.255.0
 no shutdown

ip route 192.168.12.0 255.255.255.0 192.168.23.2

end

wr