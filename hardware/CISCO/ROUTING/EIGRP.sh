#EIGRP routing config

enable
conf t
router eigrp 1
no auto-summary
network 30.30.40.0 0.0.0.3
network 30.30.30.0 0.0.0.3
network 172.3.1.0 0.0.0.255
default-information originate
passive-interface fastethernet 0/1
end
wr


#redistribution

redistribute static
redistribute ospf 1
redistribute rip
default-metric 10000 100 255 1 1500