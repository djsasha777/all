en 

conf t 

hostname R7

mpls label range 7000 7999

interface Loopback0
 ip address 7.7.7.7 255.255.255.255

interface FastEthernet0/0
 ip address 10.67.0.7 255.255.255.0
 ip router isis 
 mpls ip
 no shutdown

interface FastEthernet0/1
 ip address 10.78.0.7 255.255.255.0
 ip router isis 
 mpls ip
 no shutdown

router isis
 net 49.0001.0000.0000.0007.00
 is-type level-2-only
 passive-interface Loopback0

end

wr