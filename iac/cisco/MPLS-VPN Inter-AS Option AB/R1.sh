en 

conf t 

hostname R1

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

mpls label range 1000 1999

interface Loopback0
 ip address 1.1.1.1 255.255.255.255

interface FastEthernet0/0
 ip address 10.100.0.1 255.255.255.0
 mpls bgp forwarding
 no shutdown

interface FastEthernet0/1
 ip address 10.12.0.1 255.255.255.0
 mpls ip
 no shutdown

router ospf 1
 passive-interface Loopback0
 network 1.1.1.1 0.0.0.0 area 0
 network 10.12.0.0 0.0.0.255 area 0

router bgp 64512
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 3.3.3.3 remote-as 64512
 neighbor 3.3.3.3 update-source Loopback0
 neighbor 10.100.0.6 remote-as 64513
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 3.3.3.3 activate
  neighbor 3.3.3.3 send-community extended
  neighbor 3.3.3.3 next-hop-self
  neighbor 10.100.0.6 activate
  neighbor 10.100.0.6 send-community extended
 exit-address-family

end

wr