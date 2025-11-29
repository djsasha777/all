en 

conf t 

hostname R3

vrf definition V1
 rd 100:1
 route-target export 100:1
 route-target import 100:1
 
 address-family ipv4
 exit-address-family

vrf definition V2
 rd 200:1
 route-target export 200:1
 route-target import 200:1
 
 address-family ipv4
 exit-address-family

mpls label range 3000 3999

interface Loopback0
 ip address 3.3.3.3 255.255.255.255

interface FastEthernet0/0
 ip address 10.23.0.3 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet0/1
 vrf forwarding V1
 ip address 172.16.34.3 255.255.255.0
 no shutdown

interface FastEthernet1/0
 vrf forwarding V2
 ip address 172.16.35.3 255.255.255.0
 no shutdown

router eigrp EIGRP1
 
 address-family ipv4 unicast vrf V2 autonomous-system 1
  
  topology base
   redistribute bgp 64512 metric 100000 100 255 1 1500
  exit-af-topology
  network 172.16.35.0 0.0.0.255
 exit-address-family

router ospf 200 vrf V1
 redistribute bgp 64512 subnets
 network 172.16.34.0 0.0.0.255 area 0

router ospf 1
 passive-interface Loopback0
 network 3.3.3.3 0.0.0.0 area 0
 network 10.23.0.0 0.0.0.255 area 0

router bgp 64512
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 1.1.1.1 remote-as 64512
 neighbor 1.1.1.1 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 1.1.1.1 activate
  neighbor 1.1.1.1 send-community extended
 exit-address-family
 
 address-family ipv4 vrf V1
  redistribute ospf 200
 exit-address-family
 
 address-family ipv4 vrf V2
  redistribute eigrp 1
 exit-address-family

end

wr