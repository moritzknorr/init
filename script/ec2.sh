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
cp init/config/bashrc.bashrc /home/knorr/.bashrc
cp init/config/vimrc.vimrc /home/knorr/.vimrc
cp init/config/gitconfig.gitconfig /home/knorr/.gitconfig
cp init/config/tmux.tmux.conf /home/knorr/.tmux.conf

# Alle Dateien in /home/knorr ownen
chown -R knorr:knorr /home/knorr

# Zeitzone einstellen:
echo 'TZ='Europe/Berlin'; export TZ' >> /home/knorr/.profile

# Instanz um 01:00 Uhr herunterfahren
crontab -l > cronjobs
echo "0 1 * * * /usr/sbin/shutdown now" >> cronjobs
crontab cronjobs
rm cronjobs

# Passwort für sudo bei User knorr nicht mehr abfragen
echo 'knorr ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Ready Datei anlegen
touch /home/knorr/ready_user

mkdir /home/knorr/.ssh
ssh-keyscan github.com > /home/knorr/.ssh/known_hosts

# Enable ssh login
rm /run/nologin

# Install Software
apt -yy update
apt -yy install $(cat init/script/software.txt)

# Install Docker with new "docker compose"
apt -yy remove docker docker-engine docker.io containerd runc
## https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
### Add Docker's official GPG key:
apt -yy install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
### Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt -yy update

# adduser to docker group
usermod -a -G docker knorr

# Software Ready Datei anlegen
touch /home/knorr/ready_software
