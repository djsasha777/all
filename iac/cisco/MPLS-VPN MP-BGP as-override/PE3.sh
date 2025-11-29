enable

conf t

hostname PE3

ip vrf VA3
 rd 65000:13
 route-target export 65000:10
 route-target import 65000:10

ip vrf VB3
 rd 65000:23
 route-target export 65000:20
 route-target import 65000:20

interface Loopback0
 ip address 10.0.0.5 255.255.255.255

interface Ethernet1/0
 ip address 10.10.3.2 255.255.255.0
 mpls ip
  no shutdown

interface Ethernet1/1
 ip vrf forwarding VA3
 ip address 192.168.13.1 255.255.255.0
  no shutdown

interface Ethernet1/2
 ip vrf forwarding VB3
 ip address 192.168.23.1 255.255.255.0
  no shutdown

router ospf 1
 network 10.0.0.0 0.255.255.255 area 0

router rip
 
 address-family ipv4 vrf VB3
  redistribute bgp 65000 metric 1
  network 192.168.23.0
  no auto-summary
 exit-address-family

router bgp 65000
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 10.0.0.4 remote-as 65000
 neighbor 10.0.0.4 update-source Loopback0
 neighbor 10.0.0.11 remote-as 65000
 neighbor 10.0.0.11 update-source Loopback0
 neighbor 10.0.0.12 remote-as 65000
 neighbor 10.0.0.12 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 10.0.0.4 activate
  neighbor 10.0.0.4 send-community extended
  neighbor 10.0.0.11 activate
  neighbor 10.0.0.11 send-community extended
  neighbor 10.0.0.12 activate
  neighbor 10.0.0.12 send-community extended
 exit-address-family
 
 address-family ipv4 vrf VA3
  neighbor 192.168.13.2 remote-as 65530
  neighbor 192.168.13.2 activate
 exit-address-family
 
 address-family ipv4 vrf VB3
  redistribute rip
 exit-address-family

end

wr

