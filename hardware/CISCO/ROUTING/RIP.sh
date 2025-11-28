#aggregation router
#endpoint router need passive-interface

#first - init router script
#second - define ip addresses to interfaces


enable
conf t
router rip
no auto-summary
network 10.20.20.0
network 172.40.1.0
version 2
default-information originate
passive-interface e0/1
end
wr


#authentication mode
enable
conf t
key chain cisco
key 1
key-string 234

#rip authentication interface
ip rip authentication mode md5
ip rip authentication key-chain cisco

#redistribution

redistribute static metric 1
redistribute eigrp 1 metric 1
redistribute ospf 1