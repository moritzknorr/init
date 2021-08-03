**REPO IS PUBLIC**

# Information

only ec2.sh is copied onto host.

## Desktop Files
Desktop File:
Place in `/usr/share/application/stadia.desktop`
Place in for xubuntu `/usr/share/application/stadias.desktop`
[List of categories](https://specifications.freedesktop.org/menu-spec/latest/apas02.html)

## Install DisplayLink
[Link to installation](https://www.displaylink.com/downloads/ubuntu)

[Link to lid closed issue](https://gitlab.freedesktop.org/xorg/xserver/-/issues/1028)

[Link to Patch to prevent lag, when Laptop-Lid closed](https://displaylink.org/forum/showthread.php?p=90093)

[Prevent Patch from being updated 1](https://askubuntu.com/questions/18654/how-to-prevent-updating-of-a-specific-package)
`sudo apt-mark hold xserver-xorg-core`

[Prevent Patch from being updated 2](https://askubuntu.com/questions/1300775/ubuntu-20-04-displaylink-patch-for-xorg)

## Disable WiFi when ethernet conneted
[Link to description](https://askubuntu.com/questions/1271491/disable-wifi-if-lan-is-connected)


## Barrier Keybinding
[Link to thread](https://github.com/debauchee/barrier/issues/437)
```
setxkbmap -device `xinput list | grep "Virtual core XTEST keyboard" | sed -e 's/.\+=\([0-9]\+\).\+/\1/'` de
```

## Install Stadia
[Link to reddit post](https://www.reddit.com/r/Stadia/comments/e02zj9/stadia_on_ubuntu/)

Install chromium with vaapi
`sudo snap install --channel=candidate/vaapi chromium`

Go to `chrome://flags`

Enabel override `software rendering list` flag

Icon: https://uxwing.com/google-stadia-icon/

```
[Desktop Entry]
Version=1.0
Name=Stadia
GenericName=Google Stadia
Comment=Play with Google Stadia
Exec=/snap/bin/chromium --ignore-gpu-blacklist --disable-gpu-vsync http://stadia.google.com/
StartupNotify=true
Terminal=false
Icon=/usr/share/icons/stadia.png
Type=Application
Categories=Game;ActionGame;
```

## Install TeamSpeak

goto: https://teamspeak.com/en/downloads/

download and execute .run file.

Icon: https://ya-webdesign.com/image/teamspeak-3-icon-png/364526.html

```
[Desktop Entry]
Version=1.0
Name=TeamSpeak 3 Client
GenericName=TeamSpeak
Comment=Start the Teamspeak 3 Client
Exec=/usr/bin/TeamSpeak3-Client-linux_amd64/ts3client_runscript.sh
StartupNotify=true
Terminal=false
Icon=/usr/bin/TeamSpeak3-Client-linux_amd64/teamspeak.png
Type=Application
Categories=Network;Telephony;
```

# Backup xfce4

Create backup: `tar -C .config/ -czvf xfce4.tar.gz xfce4/`

Extract backup: `rm -rf ~/.config/xfce4/ && tar -xvf xfce4.tar.gz && mv xfce4 ~/.config/ && sudo reboot now`

# Disable bluetooth on startup
`sudo sed -i 's/AutoEnable=true/AutoEnable=false/g' /etc/bluetooth/main.conf`
