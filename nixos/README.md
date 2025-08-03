# Alternatives
- OS: **Linux**, Windows, MacOS, ChromeOS
- Distro: **nixos**, arch, ubuntu
- Display Server: **wayland**, x
- Display Manager: **LightDM**, SDDM
- Window Manager: **hyprland**, sway
- Audio / Video Manager: **pipewire**, pulseaudio
- Taskbar: **waybar**, hyprpanel
- Application Starter: **wofi**, rofi
- Lock-Screen: **hyprlock**
- Clipboard Manager: **cliphist**
- Notifications: **mako**, dunst
- Default Shell: **bash**, sh, zsh, fish
# Prompt to generate configs:
```
Define a basic minimal configuration for nixos with flake and home-manager.
Generate files `configuration.nix`, `flake.nix` and `home.nix`
Do not add hyprland or bash configuration into `home.nix`, they will be managed in configuration files.
Do not add any quotes (e.g. [1], [1, 2] to the configuration files, only to the explanation.
Use the following setup:
- Hardware:
  - Graphics Card: ASUS Nvidia Geforce RTX 2060
  - Bluetooth: Available
  - Network: LAN-Cable
- Desktop Environment:
  - hostname: NZXT
  - Display Server: Wayland
  - Display Manager: LightDM
  - Window Manager: hyprland
  - Audio / Video Manager: pipewire
  - Taskbar: hyprbar
  - Application Starter: wofi
  - Lock-Screen: hyprlock
  - Clipboard-Manager: cliphist
  - Notification: mako
  - Default-Shell: bash
  - SSH Server: activated
- Additional Software:
  - Manage networks: NetworkManager with NMApplet
  - Manage audio: pavucontrol
  - Manage Bluetooth: blueman
  - File-Manager GUI: Thunar
  - File-Manager Shell: yazi
  - Browser: google-chrome (default browser)
  - IDE: vscode
  - Managing Logitech Bluetooth devices: Solaar
  - tmux
  - git
- User Configuration
  - name: knorr
  - full name: Moritz Knorr
  - configuration files: .tmux.conf, .bashrc, .gitconfig, .vim.rc, hyprland.conf
  - authorized keys file for SSH: authorized_keys
```
