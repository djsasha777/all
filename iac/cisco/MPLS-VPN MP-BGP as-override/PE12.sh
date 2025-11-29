enable

conf t

hostname PE12

ip vrf V12
 rd 65000:2
 route-target export 65000:10
 route-target import 65000:10

interface Loopback0
 ip address 10.0.0.12 255.255.255.255

interface Ethernet1/0
 ip address 10.10.12.2 255.255.255.0
 mpls ip
  no shutdown

interface Ethernet1/1
 ip vrf forwarding V12
 ip address 192.168.1.1 255.255.255.0
  no shutdown

router ospf 1
 network 10.0.0.0 0.255.255.255 area 0

router bgp 65000
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 10.0.0.4 remote-as 65000
 neighbor 10.0.0.4 update-source Loopback0
 neighbor 10.0.0.5 remote-as 65000
 neighbor 10.0.0.5 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 10.0.0.4 activate
  neighbor 10.0.0.4 send-community extended
  neighbor 10.0.0.5 activate
  neighbor 10.0.0.5 send-community extended
 exit-address-family
 
 address-family ipv4 vrf V12
  neighbor 192.168.1.2 remote-as 65530
  neighbor 192.168.1.2 activate
 exit-address-family

end

wr

