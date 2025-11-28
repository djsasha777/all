enable

conf t

hostname CEB3

interface Ethernet1/0
 ip address 192.168.23.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.24.1 255.255.255.0
 no shutdown

router rip
 network 192.168.23.0
 network 192.168.24.0
 no auto-summary

end

wr
