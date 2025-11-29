
en 

conf t

hostname P4

interface Loopback0
 ip address 2.0.3.1 255.255.255.255

interface FastEthernet0/0
 ip address 172.22.1.2 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet1/0
 ip address 172.22.3.2 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet2/0
 ip address 172.22.4.2 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet3/0
 ip address 172.31.0.2 255.255.255.0
 mpls bgp forwarding
 no shutdown

router ospf 1
 network 2.0.0.0 0.255.255.255 area 0
 network 172.22.0.0 0.0.255.255 area 0

router bgp 2
 bgp cluster-id 2
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 no bgp default route-target filter
 neighbor 2.0.0.1 remote-as 2
 neighbor 2.0.0.1 update-source Loopback0
 neighbor 2.0.1.1 remote-as 2
 neighbor 2.0.1.1 update-source Loopback0
 neighbor 2.0.2.1 remote-as 2
 neighbor 2.0.2.1 update-source Loopback0
 neighbor 172.31.0.1 remote-as 1
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 2.0.0.1 activate
  neighbor 2.0.0.1 send-community extended
  neighbor 2.0.0.1 route-reflector-client
  neighbor 2.0.0.1 next-hop-self
  neighbor 2.0.1.1 activate
  neighbor 2.0.1.1 send-community extended
  neighbor 2.0.1.1 route-reflector-client
  neighbor 2.0.1.1 next-hop-self
  neighbor 2.0.2.1 activate
  neighbor 2.0.2.1 send-community both
  neighbor 172.31.0.1 activate
  neighbor 172.31.0.1 send-community extended
 exit-address-family

end

wr