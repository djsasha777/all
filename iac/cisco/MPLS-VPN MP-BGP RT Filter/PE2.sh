enable

conf t

hostname PE2

ip vrf VA2
 rd 65001:1
 route-target export 65001:1
 route-target import 65001:1

ip vrf VB2
 rd 65002:1
 route-target export 65002:1
 route-target import 65002:1

mpls label range 4000 4999

interface Loopback0
 ip address 10.0.0.4 255.255.255.255

interface Ethernet1/0
 ip address 10.10.2.2 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/1
 ip vrf forwarding VA2
 ip address 192.168.11.1 255.255.255.0
 no shutdown

interface Ethernet1/2
 ip vrf forwarding VB2
 ip address 192.168.21.1 255.255.255.0
 no shutdown

router eigrp 1
 
 address-family ipv4 vrf VB2 autonomous-system 21
  redistribute bgp 65000 metric 10000 1000 255 1 1500
  network 192.168.21.0
 exit-address-family

router ospf 10 vrf VA2
 redistribute bgp 65000 subnets
 network 192.168.11.0 0.0.0.255 area 2

router ospf 1
 network 10.0.0.0 0.255.255.255 area 0

router bgp 65000
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 10.0.0.3 remote-as 65000
 neighbor 10.0.0.3 update-source Loopback0
 neighbor 10.0.0.5 remote-as 65000
 neighbor 10.0.0.5 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 10.0.0.3 activate
  neighbor 10.0.0.3 send-community extended
  neighbor 10.0.0.5 activate
  neighbor 10.0.0.5 send-community extended
 exit-address-family
 
 address-family ipv4 vrf VA2
  redistribute ospf 10
 exit-address-family

 address-family ipv4 vrf VB2
  redistribute eigrp 21
 exit-address-family

end

wr
