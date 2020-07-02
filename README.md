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
