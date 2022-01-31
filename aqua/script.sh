#!/bin/bash

sudo apt install openjdk-11-jdk -y 
sudo apt install maven -y
sudo apt install gnupg2 python3-pip pass -y
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo apt-get install docker-ce=5:20.10.12~3-0~ubuntu-bionic docker-ce-cli=5:20.10.12~3-0~ubuntu-bionic containerd.io
sudo apt update -y && sudo apt upgrade -y

sudo systemctl enable docker.service 


sudo cat <<EOF >> /etc/environment
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export JAVA_HOME
export PATH=$JAVA_HOME/bin:$PATH
EOF


sudo cat <<EOF >> ~/.bashrc
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export JAVA_HOME
export PATH=$JAVA_HOME/bin:$PATH
  
EOF

sudo cat <<EOF >> /etc/profile
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export JAVA_HOME
export PATH=$JAVA_HOME/bin:$PATH
EOF
