
en 

conf t

hostname PE2

ip vrf VRF1
 rd 1:13
 route-target export 1:13
 route-target import 1:11
 route-target import 1:12
 route-target import 2:11
 route-target import 2:12

ip vrf VRF2
 rd 1:22
 route-target export 1:22
 route-target import 1:21
 route-target import 2:21
 route-target import 2:22

interface Loopback0
 ip address 1.0.1.1 255.255.255.255

interface FastEthernet0/0
 ip vrf forwarding VRF1
 ip address 192.168.3.1 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip vrf forwarding VRF2
 ip address 192.168.2.1 255.255.255.0
 no shutdown

interface FastEthernet2/0
 ip address 172.21.2.1 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet3/0
 ip address 172.21.3.1 255.255.255.0
 mpls ip
 no shutdown

router ospf 13 vrf VRF1
 router-id 1.0.1.1
 redistribute bgp 1
 network 0.0.0.0 255.255.255.255 area 0

router ospf 22 vrf VRF2
 router-id 1.0.1.2
 redistribute bgp 1
 network 0.0.0.0 255.255.255.255 area 0

router ospf 1
 network 1.0.0.0 0.255.255.255 area 0
 network 172.21.0.0 0.0.255.255 area 0

router bgp 1
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 1.0.2.1 remote-as 1
 neighbor 1.0.2.1 update-source Loopback0
 neighbor 1.0.3.1 remote-as 1
 neighbor 1.0.3.1 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 1.0.2.1 activate
  neighbor 1.0.2.1 send-community extended
  neighbor 1.0.3.1 activate
  neighbor 1.0.3.1 send-community extended
 exit-address-family
 
 address-family ipv4 vrf VRF1
  redistribute ospf 13
 exit-address-family
 
 address-family ipv4 vrf VRF2
  redistribute ospf 22
 exit-address-family

end

wr