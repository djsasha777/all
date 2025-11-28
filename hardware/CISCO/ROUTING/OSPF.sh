#OSPF routing config

enable
conf t
router ospf 1
network 10.20.10.0 0.0.0.3 area 0
network 172.1.1.0 0.0.0.255 area 0
default-information originate
passive-interface FastEthernet 3/0
end
wr

#redistribution

redistribute static metric 200 subnets
redistribute rip metric 200 subnets
redistribute eigrp 1 metric 100 subnets