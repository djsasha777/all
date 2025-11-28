#!/bin/bash

# Checking whether user has enough permission to run this script
sudo -n true
if [ $? -ne 0 ]
    then
        echo "This script requires user to have passwordless sudo access"
        exit
fi

dependency_check_deb() {
java -version
if [ $? -ne 0 ]
    then
        # Installing Java 13 if it's not installed
        sudo apt-get install openjdk-13-jre-headless -y
    # Checking if java installed is less than version 7. If yes, installing Java 7. As logstash & Elasticsearch require Java 7 or later.
    elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.7 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
        then
            sudo apt-get install openjdk-13-jre-headless -y
fi
}

dependency_check_rpm() {
    java -version
    if [ $? -ne 0 ]
        then
            #Installing Java 7 if it's not installed
            sudo yum install jre-13.0.2-openjdk -y
        # Checking if java installed is less than version 7. If yes, installing Java 7. As logstash & Elasticsearch require Java 7 or later.
        elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.7 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
            then
                sudo yum install jre-13.0.2-openjdk -y
    fi
}

debian_elk() {
    # resynchronize the package index files from their sources.
    sudo apt-get update
    # Downloading debian package of logstash
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/logstash/logstash-8.3.3-amd64.deb
    # Install logstash debian package
    sudo dpkg -i /opt/logstash*.deb
    # Downloading debian package of elasticsearch
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.3.3-amd64.deb
    # Install debian package of elasticsearch
    sudo dpkg -i /opt/elasticsearch*.deb
    # Download kibana tarball in /opt
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/kibana/kibana-8.3.3-amd64.deb
    # Extracting kibana tarball
    sudo dpkg -i /opt/kibana*.deb
    # Starting The Services
    sudo service logstash start
    sudo service elasticsearch start
    sudo service kibana start
}

rpm_elk() {
    #Installing wget.
    sudo yum install wget -y
    # Downloading rpm package of logstash
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/logstash/logstash-8.3.3-x86_64.rpm
    # Install logstash rpm package
    sudo rpm -ivh /opt/logstash*.rpm
    # Downloading rpm package of elasticsearch
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.3.3-x86_64.rpm
    # Install rpm package of elasticsearch
    sudo rpm -ivh /opt/elasticsearch*.rpm
    # Download kibana tarball in /opt
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/kibana/kibana-8.3.3-x86_64.rpm
    # Extracting kibana tarball
    sudo rpm -ivh /opt/kibana*.rpm
    # Starting The Services
    sudo systemctl enable logstash
    sudo systemctl start logstash
    sudo systemctl enable elasticsearch
    sudo systemctl start elasticsearch
    sudo systemctl enable kibana
    sudo systemctl start kibana
}

# Installing ELK Stack
if [ "$(grep -Ei 'debian|buntu|mint' /etc/*release)" ]
    then
        echo " It's a Debian based system"
        dependency_check_deb
        debian_elk
elif [ "$(grep -Ei 'fedora|redhat|centos' /etc/*release)" ]
    then
        echo "It's a RedHat based system."
        dependency_check_rpm
        rpm_elk
else
    echo "This script doesn't support ELK installation on this OS."
fi

#logstash configure
cp conf.d/* /etc/logstash/conf.d/
systemctl restart logstash