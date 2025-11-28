
en 

conf t

hostname P1

interface Loopback0
 ip address 1.0.2.1 255.255.255.255

interface FastEthernet0/0
 ip address 172.21.0.2 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet1/0
 ip address 172.21.2.2 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet2/0
 ip address 172.30.0.1 255.255.255.0
 mpls bgp forwarding
 no shutdown

interface FastEthernet3/0
 ip address 172.21.4.1 255.255.255.0
 mpls ip
 no shutdown

router ospf 1
 network 1.0.0.0 0.255.255.255 area 0
 network 172.21.0.0 0.0.255.255 area 0

router bgp 1
 bgp cluster-id 1
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 no bgp default route-target filter
 neighbor 1.0.0.1 remote-as 1
 neighbor 1.0.0.1 update-source Loopback0
 neighbor 1.0.1.1 remote-as 1
 neighbor 1.0.1.1 update-source Loopback0
 neighbor 1.0.3.1 remote-as 1
 neighbor 1.0.3.1 update-source Loopback0
 neighbor 172.30.0.2 remote-as 2
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 1.0.0.1 activate
  neighbor 1.0.0.1 send-community extended
  neighbor 1.0.0.1 route-reflector-client
  neighbor 1.0.0.1 next-hop-self
  neighbor 1.0.1.1 activate
  neighbor 1.0.1.1 send-community extended
  neighbor 1.0.1.1 route-reflector-client
  neighbor 1.0.1.1 next-hop-self
  neighbor 1.0.3.1 activate
  neighbor 1.0.3.1 send-community extended
  neighbor 172.30.0.2 activate
  neighbor 172.30.0.2 send-community extended
 exit-address-family

end

wr