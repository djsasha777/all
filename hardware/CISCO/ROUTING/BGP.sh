#BGP routing

#EDGE Router
enable
conf t
router bgp 65001
no synchronization
no auto-summary
bgp log-neighbor-changes
network 10.10.10.0 mask 255.255.255.252
network 30.30.30.0 mask 255.255.255.252
neighbor 10.10.10.2 remote-as 65004
neighbor 50.50.50.2 remote-as 65002


#CORE Router Network OSPF
router ospf 1
router-id 2.2.2.2
redistribute static subnets
network 2.2.2.2 0.0.0.0 area 0
network 10.10.10.0 0.0.0.3 area 0
network 10.10.20.0 0.0.0.255 area 0
network 10.20.10.0 0.0.0.3 area 0
network 10.20.11.0 0.0.0.3 area 0
default-information originate

router bgp 65004
bgp log-neighbor-changes
network 2.2.2.2 mask 255.255.255.255
network 10.20.10.0 mask 255.255.255.252
neighbor 10.10.10.1 remote-as 65001
neighbor 10.20.10.2 remote-as 65004
default-information originate


#redistribution