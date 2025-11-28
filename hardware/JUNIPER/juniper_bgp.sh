# Because the Juniper device blocks traffic by default, we'll also need to allow BGP traffic and ICMP for testing.

 set security zones security-zone trust interfaces em5
 set security zones security-zone trust interfaces em6
 set security zones security-zone trust host-inbound-traffic system-services ping
 set security zones security-zone trust host-inbound-traffic protocols bgp

 # configure BGP

 set routing-options router-id 10.10.11.2
 set routing-options autonomous-system 234
 #
 set protocols bgp group pc-group type internal
 set protocols bgp group pc-group local-address 10.10.11.2
 set protocols bgp group pc-group peer-as 234
 set protocols bgp group pc-group neighbor 10.10.11.2 export redistribute-connected
 #
 set policy-options policy-statement redistribute-connected from protocol direct
 set policy-options policy-statement redistribute-connected then accept
 #
 commit and-quit


 ############

 #Настройка BGP:
 #создаем свою BGP
set routing-options autonomous-system 65783

# ADD BGP NEIGHBOUR
root@ set protocols bgp peer-as 25405

#подключаем соседнюю as 25405
root@ set protocols bgp group TEST neighbor 192.168.1.1 preference 150
#подключаем соседа по адресу  neighbor 192.168.1.1 с AD 150
root@ set protocols bgp group TEST neighbor 192.168.2.2
#подключаем соседа по адресу  neighbor 192.168.2.2
root@ set protocols bgp group TEST multipath
#делаем возможность использовать несколько путей для передачи данных в bgp (основной и резервный канал)

#Создадим prefix-list с сетями, которые будут анонсироваться через BGP.
root@set policy-options prefix-list TEST 10.10.10.0/24
#анонсируем сеть 10.10.10.0/24

#создаем политику где prefix-list при совпадении будет анонсироватся в BGP
root@set policy-options policy-statement TESTPolicy term ACCEPT from prefix-list TEST
root@set policy-options policy-statement TESTPolicy term ACCEPT then accept
root@set policy-options policy-statement TESTPolicy then reject 

root@set protocols bgp group TEST export TESTPolicy
#включим экспорт в BGP.




Включить трейсы (дэбаг):
set protocols bgp traceoptions file bgp.log
set protocols bgp traceoptions file size 1m
set protocols bgp traceoptions file files 5
set protocols bgp log-updown


Определить собственный номер AS:
set routing-options autonomous-system 65041
Если для поднятие BGP сессии используется не directly connected сеть, желательно прописать статические маршруты на BGP neighbor-a.

Как парсить маршруты по номерах АС:
show route aspath-regex ".*59583" | count

Настройка самого протокола BGP:
set protocols bgp group UPSTREAM type external
set protocols bgp group UPSTREAM neighbor 77.222.151.xxx description UPSTREAM-ISP-1v4
set protocols bgp group UPSTREAM neighbor 77.222.151.xxx import ISP-1-IMPORT
set protocols bgp group UPSTREAM neighbor 77.222.151.xxx export ISP-1-EXPORT
set protocols bgp group UPSTREAM neighbor 77.222.151.xxx peer-as 21219
set protocols bgp group UPSTREAM neighbor 2a01:xxx:fff6:1:0:0:0:1 description UPSTREAM-ISP-2v6
set protocols bgp group UPSTREAM neighbor 2a01:xxx:fff6:1:0:0:0:1 import ISP-2-IMPORT
set protocols bgp group UPSTREAM neighbor 2a01:xxx:fff6:1:0:0:0:1 export ISP-2-EXPORT
set protocols bgp group UPSTREAM neighbor 2a01:xxx:fff6:1:0:0:0:1 peer-as 21011

Использование политик:

Для анонсирования своих подсетей выше стоящему провайдеру мы можем добавить данные сети в  routing-options aggregate и они будут отображаться в RIB.

set routing-options aggregate route 192.162.208.0/22
set routing-options aggregate route 176.97.56.0/21
set routing-options aggregate route 109.197.166.0/23

show route protocol aggregate
109.197.166.0/23   *[Aggregate/130] 02:30:41
                      Reject
176.97.56.0/21     *[Aggregate/130] 02:30:41
                      Reject
192.162.208.0/22   *[Aggregate/130] 02:30:41
                      Reject

Либо создать для них отдельный prefix-list если они уже присутствуют в RIB (оконечены на интерфейсах, etc.).
set policy-options prefix-list NATIVE-NETWORKS-v4 185.95.22.0/23
set policy-options prefix-list NATIVE-NETWORKS-v6 2a01:89a0:4000::/34

Принимать только default ipv6:
set policy-options policy-statement DEFAULT-v6-P term ACCEPT from route-filter ::/0 exact
set policy-options policy-statement DEFAULT-v6-P term ACCEPT then accept
set policy-options policy-statement DEFAULT-v6-P term REJECT then reject

Принимать только default ipv4:
set policy-options policy-statement DEFAULT-v4-P term ACCEPT from route-filter 0.0.0.0/0 exact
set policy-options policy-statement DEFAULT-v4-P term ACCEPT then accept
set policy-options policy-statement DEFAULT-v4-P term REJECT then reject

set policy-options policy-statement ISP-1-IMPORT term DEFAULT from policy DEFAULT-v4-P
set policy-options policy-statement ISP-1-IMPORT term DEFAULT then local-preference 210
set policy-options policy-statement ISP-1-IMPORT term DEFAULT then accept
set policy-options policy-statement ISP-1-IMPORT term ORIGIN_UAIX from as-path as_Datagroup
set policy-options policy-statement ISP-1-IMPORT term ORIGIN_UAIX from as-path as_Datagroup_UAIX
set policy-options policy-statement ISP-1-IMPORT term ORIGIN_UAIX then local-preference 250
set policy-options policy-statement ISP-1-IMPORT term ORIGIN_UAIX then accept
set policy-options policy-statement ISP-1-IMPORT term OTHER from as-path as_Datagroup_OTHER
set policy-options policy-statement ISP-1-IMPORT term OTHER then local-preference 230
set policy-options policy-statement ISP-1-IMPORT term OTHER then accept
set policy-options policy-statement ISP-1-IMPORT term REJECT then reject

set policy-options policy-statement ISP-1-EXPORT term ORIGIN from prefix-list NATIVE-NETWORKS-v4
set policy-options policy-statement ISP-1-EXPORT term ORIGIN then community set comm_Datagroup_UAIX
set policy-options policy-statement ISP-1-EXPORT term ORIGIN then accept
set policy-options policy-statement ISP-1-EXPORT term default then reject

set policy-options policy-statement ISP-2-IMPORT term DEFAULT from policy DEFAULT_V6_permit
set policy-options policy-statement ISP-2-IMPORT term DEFAULT then local-preference 210
set policy-options policy-statement ISP-2-IMPORT term DEFAULT then accept
set policy-options policy-statement ISP-2-IMPORT term ORIGIN_UAIX from as-path as_Topnet
set policy-options policy-statement ISP-2-IMPORT term ORIGIN_UAIX from as-path as_Topnet_UAIX
set policy-options policy-statement ISP-2-IMPORT term ORIGIN_UAIX then local-preference 250
set policy-options policy-statement ISP-2-IMPORT term ORIGIN_UAIX then accept
set policy-options policy-statement ISP-2-IMPORT term OTHER from as-path as_Topnet_OTHER
set policy-options policy-statement ISP-2-IMPORT term OTHER then local-preference 230
set policy-options policy-statement ISP-2-IMPORT term OTHER then accept
set policy-options policy-statement ISP-2-IMPORT term REJECT then reject

set policy-options policy-statement ISP-2-EXPORT term ORIGIN from prefix-list NATIVE-NETWORKS-v6
set policy-options policy-statement ISP-2-EXPORT term ORIGIN then community set comm_Topnet_UAIX
set policy-options policy-statement ISP-2-EXPORT term ORIGIN then accept
set policy-options policy-statement ISP-2-EXPORT term default then reject


set policy-options policy-statement grey_AS from as-path as_GREY
set policy-options policy-statement grey_AS then reject

set policy-options policy-statement grey_PREFIX from route-filter 127.0.0.0/8 orlonger
set policy-options policy-statement grey_PREFIX from route-filter 10.0.0.0/8 orlonger
set policy-options policy-statement grey_PREFIX from route-filter 172.16.0.0/12 orlonger
set policy-options policy-statement grey_PREFIX from route-filter 192.168.0.0/16 orlonger
set policy-options policy-statement grey_PREFIX from route-filter 169.254.0.0/16 orlonger
set policy-options policy-statement grey_PREFIX from route-filter 224.0.0.0/4 orlonger
set policy-options policy-statement grey_PREFIX from route-filter 240.0.0.0/4 orlonger
set policy-options policy-statement grey_PREFIX then reject

set policy-options community comm_Datagroup_UAIX members 64701:15645

set policy-options as-path as_UAIX 15645+
set policy-options as-path as_ORIGIN "()"
set policy-options as-path as_Datagroup "^21219$"
set policy-options as-path as_Datagroup_UAIX "15645 21219$"
set policy-options as-path as_Datagroup_OTHER .*
set policy-options as-path as_GREY 64512-65535

Немного о политиках маршрутизации в Интернете

Правила community должны быть записаны в формате RPSL и выложены во whois базе регионального регистратора (для Европы и СНГ это RIPE).

Кроме создаваемых вручную, RFC1997 опредяет 3 общеизвестных community:



1) NO_EXPORT (0xFFFFFF01) — не отдавать префиксы полноценными eBGP пирам, но отдавать eBGP пирам внутри конфедерации

2) NO_ADVERTISE (0xFFFFFF02) — не отдавать префиксы никому

3) NO_EXPORT_SUBCONFED (0xFFFFFF03) — не отдавать префиксы никаким eBGP пирам, включая конфедерацию
