#!/bin/bash 
export DEBIAN_FRONTEND=noninteractive

# Disable ssh login
echo "Still starting up" | sudo tee /run/nologin

# User Ubuntu durch knorr ersetzen
usermod -l knorr ubuntu
groupmod -n knorr ubuntu
usermod -d /home/knorr -m knorr
usermod -c "Moritz Knorr" knorr

# Init holen
cd /home/knorr/
git clone https://github.com/moritzknorr/init.git
cp init/bashrc.bashrc /home/knorr/.bashrc
cp init/vimrc.vimrc /home/knorr/.vimrc
cp init/gitconfig.gitconfig /home/knorr/.gitconfig

# Alle Dateien in /home/knorr ownen
chown -R knorr:knorr /home/knorr

# Zeitzone einstellen:
echo 'TZ='Europe/Berlin'; export TZ' >> /home/knorr/.profile

# Instanz um 01:00 Uhr herunterfahren
crontab -l > cronjobs
echo "0 1 * * * shutdown -t now" >> cronjobs
crontab cronjobs
rm cronjobs

# Passwort für sudo bei User knorr nicht mehr abfragen
echo 'knorr ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Ready Datei anlegen
touch /home/knorr/ready_user

# Enable ssh login
rm /run/nologin

apt -yy update

# cleanup for fresh docker installation
apt -yy remove docker docker-engine docker.io containerd runc
# install docker-compose via old mechanism
# curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose
# ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

apt -yy install $(cat init/software.txt)

# adduser to docker group
usermod -a -G docker knorr

# Software Ready Datei anlegen
touch /home/knorr/ready_software
