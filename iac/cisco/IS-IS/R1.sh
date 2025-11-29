
hostname R1

interface FastEthernet0/0
 ip address 10.0.0.1 255.255.255.0
 ip router isis 
 no shutdown

interface FastEthernet0/1
 ip address 11.0.0.1 255.255.255.0
 ip router isis 
 no shutdown

router isis
 net 49.0001.0000.0000.0001.00
 is-type level-2-only

end