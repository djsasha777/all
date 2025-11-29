enable

conf t

hostname PE1

ip vrf VRF1
 rd 1:110
 route-target export 1:110
 route-target import 1:120
 route-target import 1:110

ip vrf VRF2
 rd 1:210
 route-target export 1:210
 route-target import 1:220
 route-target import 1:210

ip vrf VRF3
 rd 1:310
 route-target export 1:310
 route-target import 1:320
 route-target import 1:310

ip vrf VRF4
 rd 1:120
 route-target export 1:120
 route-target import 1:110
 route-target import 1:120

ip vrf VRF5
 rd 1:220
 route-target export 1:220
 route-target import 1:210
 route-target import 1:220

ip vrf VRF6
 rd 1:320
 route-target export 1:320
 route-target import 1:310
 route-target import 1:320

interface Loopback0
 ip address 10.1.0.1 255.255.255.255

interface FastEthernet0/0
 ip vrf forwarding VRF1
 ip address 192.168.0.1 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 192.168.255.1 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet1/0
 ip vrf forwarding VRF2
 ip address 192.168.0.1 255.255.255.0
 no shutdown

interface FastEthernet2/0
 ip vrf forwarding VRF3
 ip address 192.168.0.1 255.255.255.0
 no shutdown

interface FastEthernet3/0
 ip vrf forwarding VRF4
 ip address 192.168.10.1 255.255.255.0
 no shutdown

interface FastEthernet4/0
 ip vrf forwarding VRF5
 ip address 192.168.20.1 255.255.255.0
 no shutdown

interface FastEthernet5/0
 ip vrf forwarding VRF6
 ip address 192.168.30.1 255.255.255.0
 no shutdown

router eigrp 1
 
 address-family ipv4 vrf VRF5 
  redistribute bgp 1 metric 100000 10000 100 1 1500
  network 192.168.20.0
  auto-summary
  autonomous-system 220
 exit-address-family
 
 address-family ipv4 vrf VRF1 
  redistribute bgp 1 metric 100000 10000 255 1 1500
  network 192.168.0.0
  auto-summary
  autonomous-system 110
 exit-address-family
 auto-summary

router ospf 210 vrf VRF2
 redistribute bgp 1
 network 192.168.0.0 0.0.0.255 area 0

router ospf 320 vrf VRF6
 redistribute bgp 1
 network 192.168.30.0 0.0.0.255 area 0

router ospf 255
 network 10.1.0.1 0.0.0.0 area 0
 network 192.168.255.0 0.0.0.255 area 0

router rip
 
 address-family ipv4 vrf VRF4
  redistribute bgp 1 metric 1
  network 192.168.10.0
  no auto-summary
  version 2
 exit-address-family
 
 address-family ipv4 vrf VRF3
  redistribute bgp 1 metric 1
  network 192.168.0.0
  no auto-summary
  version 2
 exit-address-family

router bgp 1
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 10.1.0.2 remote-as 1
 neighbor 10.1.0.2 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 10.1.0.2 activate
  neighbor 10.1.0.2 send-community extended
 exit-address-family
 
 address-family ipv4 vrf VRF1
  redistribute eigrp 110
 exit-address-family
 
 address-family ipv4 vrf VRF2
  redistribute ospf 210
 exit-address-family
 
 address-family ipv4 vrf VRF3
  redistribute rip
 exit-address-family
 
 address-family ipv4 vrf VRF4
  redistribute rip
 exit-address-family
 
 address-family ipv4 vrf VRF5
  redistribute eigrp 220
 exit-address-family
 
 address-family ipv4 vrf VRF6
  redistribute ospf 320
 exit-address-family

end

wr