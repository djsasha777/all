# Script for checking global ip address and region
#!/bin/bash
apt update
apt install jq -y
ip=$(curl -s https://api.ipify.org)
echo "IP: $ip"
reg=$(curl -s http://ip-api.com/json/${ip} | jq -r '.countryCode')
echo "REGION: $reg"