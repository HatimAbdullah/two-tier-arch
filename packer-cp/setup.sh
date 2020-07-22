#!/bin/bash

sudo apt-get update
lsb_release -a
sudo apt-get install -y make jq vim curl 
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER 
export K3S_KUBECONFIG_MODE="644"
curl -sfL https://get.k3s.io | sh -
sed -i 's+iaintshit+'"$(sudo cat /var/lib/rancher/k3s/server/node-token)"'+g' default.conf
sudo docker image build -t small-ws .
sudo docker create --name hola -p 6969:80 small-ws
sudo systemctl enable webserver
