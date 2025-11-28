enable

conf t

hostname R1

interface FastEthernet0/0
 ip address 192.168.12.1 255.255.255.0
 no shutdown

ip route 192.168.23.0 255.255.255.0 192.168.12.2

end

wr