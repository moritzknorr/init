# home.nix
{ inputs, config, pkgs, ... }:

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
  home.packages = with pkgs; [
    google-chrome
    vscode-fhs
    dbeaver-bin
    spotify
    vlc
    localsend
    bruno
  ];
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  ## Add authorized keys does not work
  ## home.file.".ssh/authorized_keys" = { text = builtins.readFile /home/knorr/init/authorized_keys; force = true; mode = "0600"; };

  ## Add bash_profile to parse .bashrc
  ## This causes more problems than it solves
  ## home.file.".bash_profile" = { source = /home/knorr/init/desktop_environment/bash_profile.bash_profile; force = true; };

  # Add dotfiles from ../config
  home.file.".bashrc" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/config/bashrc.bashrc"; };
  home.file.".bash_profile" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/config/bash_profile.bash_profile"; };
  home.file.".gitconfig" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/config/gitconfig.gitconfig"; };
  home.file.".tmux.conf" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/config/tmux.tmux.conf"; };
  home.file.".vimrc" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/config/vimrc.vimrc"; };

  ## Add desktop environment configs from ../desktop_environment/
  home.file.".config/hypr" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/desktop_environment/hypr/"; };
  home.file.".config/waybar" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/desktop_environment/waybar/"; };
  home.file.".config/wofi" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/desktop_environment/wofi/"; };
  home.file.".config/kitty" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/desktop_environment/kitty/"; };
  home.file.".config/solaar" = { source = config.lib.file.mkOutOfStoreSymlink "/home/knorr/init/desktop_environment/solaar/"; };

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
  
  # Enable Cliphist for User
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    hyprcursor.enable = true;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "kora";
    };
    font = {
      name = "Noto Sans";
      size = 12;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

}
