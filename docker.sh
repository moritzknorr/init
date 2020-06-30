#!/bin/bash

# Docker über Ubuntu-Repo installieren
sudo apt -yy update
sudo apt -yy remove docker docker-engine docker.io containerd runc
sudo apt -yy install docker.io curl
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
