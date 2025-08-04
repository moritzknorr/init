# home.nix
{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "knorr";
  home.homeDirectory = "/home/knorr";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # changes how options are defined.
  #
  # It‘s perfectly fine and recommended to leave this value at the release version
  # of the first install of this system. Before changing this value read the
  # documentation for this option (e.g. man home-configuration.nix or on
  # https://nixos.wiki/wiki/Home_Manager).
  home.stateVersion = "24.05";

  # The star of the show. You can configure anything you want here.
  home.packages = [
    # User specific packages can be installed here
  ];

  # Add authorized keys does not work
  # home.file.".ssh/authorized_keys" = { text = builtins.readFile ../authorized_keys; force = true; mode = "0600"; };

  # Add bash_profile to parse .bashrc
  home.file.".bash_profile" = { source = ../desktop_environment/bash_profile.bash_profile; force = true; };

  # Add dotfiles from ../config
  home.file.".bashrc" = { source = ../config/bashrc.bashrc; force = true; };
  home.file.".gitconfig" = { source = ../config/gitconfig.gitconfig; force = true; };
  home.file.".tmux.conf" = { source = ../config/tmux.tmux.conf; force = true; };
  home.file.".vimrc" = { source = ../config/vimrc.vimrc; force = true; };

  # Add desktop environment configs from ../desktop_environment/
  home.file.".config/hypr/hyprland.conf" = { source = ../desktop_environment/hyprland.conf; force = true; };
  home.file.".config/hypr/hyprlock.conf" = { source = ../desktop_environment/hyprlock.conf; force = true; };
  home.file.".config/hypr/hyprpaper.conf" = { source = ../desktop_environment/hyprpaper.conf; force = true; };
  home.file.".config/wofi/style.css" = { source = ../desktop_environment/wofi_style.css; force = true; };
  home.file.".config/waybar/config" = { source = ../desktop_environment/waybar.config; force = true; };
  home.file.".config/waybar/style.css" = { source = ../desktop_environment/waybar.css; force = true; };
  home.file.".config/kitty/kitty.conf" = { source = ../desktop_environment/kitty.conf; force = true; };
  home.file.".config/solaar/config.yaml" = { source = ../desktop_environment/solaar.config.yaml; force = true; };



  # Set default browser
  xdg.mimeApps.defaultApplications = {
    "text/html" = "google-chrome.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
    "x-scheme-handler/about" = "google-chrome.desktop";
    "x-scheme-handler/unknown" = "google-chrome.desktop";
  };

  # Let home-manager manage shell configuration.
  programs.home-manager.enable = true;
}
