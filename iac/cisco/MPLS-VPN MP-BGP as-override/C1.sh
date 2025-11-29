enable

conf t

hostname R13

ip vrf V1
 rd 65530:13

interface Loopback0
 ip vrf forwarding V1
 ip address 10.0.0.13 255.255.255.255

interface Ethernet1/0
 ip vrf forwarding V1
 ip address 192.168.2.2 255.255.255.0
 no shutdown

router ospf 1 vrf V1
 network 10.0.0.0 0.0.0.255 area 0
 network 192.168.2.0 0.0.0.255 area 0

router bgp 65530
 bgp router-id 10.0.0.13
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 
 address-family ipv4 vrf V1
  neighbor 10.0.0.6 remote-as 65530
  neighbor 10.0.0.6 update-source Loopback0
  neighbor 10.0.0.6 activate
 exit-address-family

end

wr

---

interface Ethernet0/0
 ip vrf forwarding V1
 ip address 192.169.0.1 255.255.255.0
 no shutdown

router ospf 1 vrf V1
 network 192.169.0.0 0.0.0.255 area 0