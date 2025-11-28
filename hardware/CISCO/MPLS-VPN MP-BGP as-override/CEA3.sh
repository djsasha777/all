enable

conf t

hostname CEA3

interface Ethernet1/0
 ip address 192.168.13.2 255.255.255.0
  no shutdown

interface Ethernet1/1
 ip address 192.168.14.1 255.255.255.0
  no shutdown

router bgp 65530
 bgp log-neighbor-changes
 network 192.168.13.0
 network 192.168.14.0
 neighbor 192.168.13.1 remote-as 65000

end

wr

