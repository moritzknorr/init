# init

Personal configuration repository — dotfiles, NixOS system config, desktop environment, and utility scripts.

## Structure

```
init/
├── nixos/          NixOS flake: system config, home-manager, hardware
├── dotfiles/       Shell, git, vim, tmux — deploy with install.sh
├── desktop/        Hyprland, waybar, wofi, kitty, solaar configs
├── scripts/        Utility scripts (AWS instance launcher)
└── authorized_keys SSH public key
```

## NixOS

Configuration is managed via flakes with home-manager. Host: `NZXT` (x86_64).

```bash
# Apply configuration
sudo nixos-rebuild switch --flake './init/nixos/.#NZXT' --impure

# Upgrade (update flake inputs first)
sudo nixos-rebuild switch --flake './init/nixos/.#NZXT' --impure --upgrade
```

## Dotfiles

For non-NixOS machines. Deploys `.bashrc`, `.gitconfig`, `.tmux.conf`, `.vimrc` to `$HOME`.

```bash
dotfiles/install.sh
```

## Scripts

### aws_instance.sh

Launches an EC2 instance interactively. Requires a local `scripts/aws_config.sh` (gitignored) with subnet and security group IDs — copy `aws_config.sh.example` to get started.

## Desktop

Hyprland compositor with waybar, wofi launcher, hyprlock, hyprpaper, kitty terminal, and solaar for Logitech peripherals.
