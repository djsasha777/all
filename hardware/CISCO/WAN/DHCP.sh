#DHCP on router

enable
conf t
ip dhcp excluded-address 192.168.1.1
ip dhcp excluded-address 192.168.2.1
ip dhcp pool pool1
network 192.168.1.0 255.255.255.0
default-router 192.168.1.1
dns-server 8.8.8.8 8.8.4.4
ip dhcp pool pool2
network 192.168.2.0 255.255.255.0
default-router 192.168.2.1
dns-server 8.8.8.8 8.8.4.4
end
wr
