#Static NAT

enable
conf t

ip route 0.0.0.0 0.0.0.0 192.168.1.1
exit

int e0/0
ip address 10.0.0.1 255.255.255.0
ip nat inside
exit

int e1/1
ip address 192.168.1.197 255.255.255.0
ip nat outside
exit

access-list 1 permit 10.10.10.0 0.0.0.252
access-list 1 permit 10.20.10.0 0.0.0.252
access-list 1 permit 172.1.1.0 0.0.0.255

access-list 100 permit ip 0.0.0.0 255.255.255.255 any
#or access-list 1 permit ip 0.0.0.0 255.255.255.255 any

ip nat inside source list 100 interface e0/0 overload

end
wr

#Second version

enable
conf t

ip route 0.0.0.0 0.0.0.0 192.168.1.1
exit

int range e0/0, e1/1
ip nat enable
access-list 100 permit ip 0.0.0.0 255.255.255.255 any
ip nat source list 100 interface e0/0 overload

end
wr