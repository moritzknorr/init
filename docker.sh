#!/bin/bash

# ref: https://askubuntu.com/a/30157/8698
if ! [ $(id -u) = 0 ]; then
       echo "The script need to be run as root." >&2
          exit 1
fi


# Docker über Ubuntu-Repo installieren
apt -yy update
apt -yy remove docker docker-engine docker.io containerd runc
apt -yy install docker.io curl
curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

usermod -a -G docker knorr
