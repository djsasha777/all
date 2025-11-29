enable

conf t

username admin privilege 15 secret 0 cisco
service password-encryption
enable secret gorizont
aaa new-model
ip domain name local.domain
ip name-server 8.8.8.8
no ip domain-lookup
ip ssh ver 2
crypto key generate rsa general-keys modulus 1024
line console 0
password cisco
line vty 0 4
password cisco
aaa authentication login vty local
aaa authorization network default if-authenticated
line vty 0 4
transport input ssh

hostname EDGE1

no ip domain lookup
ip domain name local.domain
ip name-server 8.8.8.8

ip cef
ip cef load-sharing algorithm include-ports source destination

interface Loopback0
 ip address 10.0.0.3 255.255.255.255

interface Ethernet0/0
 ip address 80.80.80.1 255.255.255.0

interface Ethernet0/1
 bandwidth 9000
 ip address 175.2.0.2 255.255.255.0
 ip nat outside
 ip virtual-reassembly in

interface Ethernet0/2
 bandwidth 3000
 ip address 174.1.0.2 255.255.255.0
 ip nat outside
 ip virtual-reassembly in

interface Ethernet1/0
 ip address 173.1.0.1 255.255.255.0
 ip nat inside
 ip virtual-reassembly in

interface Ethernet1/1
 ip address 173.2.0.1 255.255.255.0
 ip nat inside
 ip virtual-reassembly in

router ospf 1
 network 77.77.0.0 0.0.255.255 area 1
 network 10.0.0.0 0.0.0.255 area 1
 network 80.80.80.0 0.0.0.255 area 1
 network 173.1.0.0 0.0.0.255 area 1
 network 173.2.0.0 0.0.0.255 area 1
 default-information originate

router bgp 56789
 bgp router-id 10.0.0.3
 bgp log-neighbor-changes
 bgp bestpath as-path multipath-relax
 bgp dmzlink-bw
 network 10.0.0.0 mask 255.255.255.0
 network 21.1.1.0 mask 255.255.255.0
 network 22.2.2.0 mask 255.255.255.0
 network 10.10.20.0 mask 255.255.255.0
 network 90.0.0.0 mask 255.255.255.0
 network 91.0.0.0 mask 255.255.255.0
 neighbor 10.0.0.4 remote-as 56789
 neighbor 10.0.0.4 update-source Loopback0
 neighbor 10.0.0.5 remote-as 56789
 neighbor 10.0.0.5 update-source Loopback0
 neighbor 10.0.0.5 next-hop-self
 neighbor 10.0.0.6 remote-as 56789
 neighbor 10.0.0.6 update-source Loopback0
 neighbor 10.0.0.6 next-hop-self
 neighbor 174.1.0.1 remote-as 3890
 neighbor 174.1.0.1 password 7 00292A36256838
 neighbor 174.1.0.1 prefix-list PREF-DEF in
 neighbor 174.1.0.1 filter-list 100 out
 neighbor 174.1.0.1 dmzlink-bw
 neighbor 175.2.0.1 remote-as 65783
 neighbor 175.2.0.1 password 7 00292A36256838
 neighbor 175.2.0.1 prefix-list PREF-DEF in
 neighbor 175.2.0.1 filter-list 100 out
 neighbor 175.2.0.1 dmzlink-bw
 maximum-paths 2
 default-information originate

ip as-path access-list 100 permit ^$

ip nat pool NATUSERS1 21.1.1.1 21.1.1.254 netmask 255.255.255.0
ip nat inside source list 10 pool NATUSERS1 overload
ip nat inside source list 1 pool NATUSERS1 overload

ip nat pool NATUSERS2 22.2.2.1 22.2.2.254 netmask 255.255.255.0
ip nat inside source list 30 pool NATUSERS2 overload

ip route 21.1.1.0 255.255.255.0 Null0
ip route 22.2.2.0 255.255.255.0 Null0

ip prefix-list PREF-DEF seq 10 permit 0.0.0.0/0

access-list 1 permit 10.0.0.0 0.0.0.255
access-list 10 permit 10.10.10.0 0.0.0.255
access-list 30 permit 10.10.30.0 0.0.0.255

no cdp log mismatch duplex

end

wr
