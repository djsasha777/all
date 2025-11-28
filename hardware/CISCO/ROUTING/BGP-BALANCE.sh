#Конфигурация маршрутизатора Cisco 2911 для подключения по BGP к двум (и более) провайдерам:

interface GigabitEthernet0/0
 description This is link on AS network
 ip address 11.12.13.14 255.255.255.0
 no ip proxy-arp
 duplex auto
 speed auto
 no keepalive
 no cdp enable

interface GigabitEthernet0/1
 description Channel on Provider # 1
 ip address 21.22.23.24 255.255.255.252
 no ip proxy-arp
 duplex auto
 speed auto
 no cdp enable

interface GigabitEthernet0/2
 description Channel on  on Provider # 2
 ip address 31.32.33.34 255.255.255.252
 duplex auto
 speed auto
 no cdp enable

router bgp 12345
 no synchronization
 bgp log-neighbor-changes
 bgp deterministic-med
 bgp dampening
 network 11.12.13.0
 redistribute connected
 redistribute static
 neighbor 21.22.23.24 remote-as 23456
 neighbor 21.22.23.24 description Provider #1
 neighbor 21.22.23.24 prefix-list provider1out out
 neighbor 21.22.23.24 filter-list 11 out
 neighbor 31.32.33.34 remote-as 34567
 neighbor 31.32.33.34 description Provider #2
 neighbor 31.32.33.34 prefix-list provider2out out
 neighbor 31.32.33.34 filter-list 11 out
 no auto-summary

ip forward-protocol nd

ip as-path access-list 11 permit ^(12345_)*$
ip as-path access-list 21 permit ^(12345_)*$
no ip http server
no ip http secure-server

ip route 10.0.0.0 255.0.0.0 Null0
ip route 172.16.0.0 255.240.0.0 Null0
ip route 192.168.0.0 255.255.0.0 Null0
ip route 11.12.13.0 255.255.255.0 Null0


ip prefix-list provider1out seq 5 permit 11.12.13.0/24

ip prefix-list provider2out seq 5 permit 11.12.13.0/24

no cdp run
