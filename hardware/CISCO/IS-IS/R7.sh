
hostname R7

interface FastEthernet0/0
 ip address 172.16.0.7 255.255.255.0
 ip router isis 
 no shutdown

interface FastEthernet0/1
 ip address 12.0.0.7 255.255.255.0
 no shutdown

router eigrp 10
 network 13.0.0.0 0.0.0.255
 redistribute isis level-1 metric 100000 100 255 1 1500
!
router ospf 1
 redistribute isis level-1 subnets
 network 12.0.0.0 0.0.0.255 area 0
 default-information originate
!
router isis
 net 49.0003.0000.0000.0007.00
 is-type level-1
 redistribute eigrp 10 level-1
 redistribute ospf 1 level-1

end