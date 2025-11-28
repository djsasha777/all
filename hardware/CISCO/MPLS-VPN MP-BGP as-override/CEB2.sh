enable

conf t

hostname CEB2

interface Loopback0
 ip address 10.0.0.8 255.255.255.255

interface Ethernet1/0
 ip address 192.168.21.2 255.255.255.0
  no shutdown

interface Ethernet1/1
 ip address 192.168.22.1 255.255.255.0
  no shutdown

router eigrp 21
 network 192.168.21.0
 network 192.168.22.0

end

wr

