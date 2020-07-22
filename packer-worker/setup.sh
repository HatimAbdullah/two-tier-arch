#!/bin/bash

sudo apt-get update
lsb_release -a
sudo apt-get install -y make jq vim curl 
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
chmod +x run-time.sh
sudo systemctl enable token

