#primary L3 ROUTER configuration

enable
clock set 12:10:00 20 Jun 2021
conf t
hostname switch55
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
exit
line vty 0 4
password cisco
exit
aaa authentication login vty local
aaa authorization network default if-authenticated
line vty 0 4
transport input ssh
end
wr