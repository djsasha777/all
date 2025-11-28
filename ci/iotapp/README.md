# IOt project

My iot project with CI/CD integration and running in Kubernetes cluster

# Building

1. Create credentials for Jenkins Docker hub

2. Build and Push Docker image using Jenkins

# Preparations

install HElm

    curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm

install kubens

    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

clote git

    git clone https://github.com/djsasha777/IOT.git
    cd IOT

# Project use Helm charts:

    helm repo add bitnami https://charts.bitnami.com/bitnami

    helm repo add metallb https://metallb.github.io/metallb

# Run project

    kubectl create ns metallb

    kubens metallb

Change ip address range in helm_values_metal.yaml file

    helm install metallb metallb/metallb -f helm_values_metal.yaml

    kubectl create ns iot

Change pv volumes in file pv.yaml, by default project use /home/iot folder for storage data

    kubectl apply -f pv.yaml

    kubens iot

    helm install mymongo --values helm_config_mongo.yaml bitnami/mongodb

    kubectl apply -f app.yaml

    kubectl apply -f mongo_express.yaml

# Port redirecting for Router:

kubernetes dashboard(https)-------> https://172.22.7.185:1100
    
    iptables -t nat -A PREROUTING -d 172.22.7.185 -p tcp --dport 1100 -j DNAT --to-destination 192.168.1.111:443

MongoExpress(http)-------> https://172.22.7.185:8081
    
    iptables -t nat -A PREROUTING -d 172.22.7.185 -p tcp --dport 8081 -j DNAT --to-destination 192.168.1.113:8081

# Testing API:

    curl -X POST -H "Content-Type: application/json" \
        -d '{"device": 21592, "relay1": false, "relay2": false, "power_mode": 4, "transfer_mode": 3}' \
        77.223.98.80:8088/addrelay/
    
    curl -X PUT -H "Content-Type: application/json" \
        -d '{"power_mode": 77, "transfer_mode": 77}' \
        172.22.196.117:8088/setrelay/10025

    curl -X POST -H "Content-Type: application/json" -d '{"device": 21592, "relay1": false, "relay2": false, "power_mode": 4, "transfer_mode": 3}' https://jadu.ga/addrelay/