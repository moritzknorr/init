# REPO IS PUBLIC

only ec2.sh is copied onto host.

## Install Stadia
[Link to reddit post](https://www.reddit.com/r/Stadia/comments/e02zj9/stadia_on_ubuntu/)

Install chromium with vaapi
`sudo snap install --channel=candidate/vaapi chromium`

Enabel override `software rendering list` flag
Go to `chrome://flags`

Desktop File:
Place in `/usr/share/application/stadia.desktop`
Place in for xubuntu `/usr/share/application/stadias.desktop`

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

## Install DisplayLink
[Link to installation](https://www.displaylink.com/downloads/ubuntu)
