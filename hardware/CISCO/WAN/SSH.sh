#switch l2 telnet configure

enable
clock set 17:10:00 2 Sep 2020
conf t
ip domain name mydomain.ru
crypto key generate rsa

2048

service password-encryption
username admin privilege 15 password 12345
aaa new-model
line vty 0 4
transport input telnet
logging synchronous
exec-timeout 60 0
exit
enable password 12345
exit
wr

#l3 ssh configure

enable
clock set 17:10:00 2 Sep 2020
conf t
ip domain name mydomain.ru
crypto key generate rsa

2048

service password-encryption
username admin privilege 15 password 12345
aaa new-model
line vty 0 4
transport input ssh
logging synchronous
exec-timeout 60 0
exit
enable password 12345
exit
wr