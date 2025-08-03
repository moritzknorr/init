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

  # Add authorized keys
  home.file.".ssh/authorized_keys" = { text = builtins.readFile ../authorized_keys; };

  # Add dotfiles from ../config
  home.file.".bashrc" = { source = ../config/bashrc.bashrc; force = true; };
  home.file.".gitconfig" = { source = ../config/gitconfig.gitconfig; force = true; };
  home.file.".tmux.conf" = { source = ../config/tmux.tmux.conf; force = true; };
  home.file.".vimrc" = { source = ../config/vimrc.vimrc; force = true; };

  # Add desktop environment configs from ../hypr/
  home.file.".config/hypr/hyprland.conf" = { source = ../hypr/hyprland.conf; force = true; };
  home.file.".config/hpyr/hyprlock.conf" = { source = ../hypr/hyprlock.conf; force = true; };
  home.file.".config/waybar/config" = { source = ../hypr/waybar.config; force = true; };
  home.file.".config/waybar/style.css" = { source = ../hypr/waybar.css; force = true; };


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
