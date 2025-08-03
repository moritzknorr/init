{ config, pkgs, ... }:

{
  imports = [
    # It is a good practice to import hardware-specific configurations.
    # You can find your hardware configuration by running: nixos-generate-config
    # and looking for a hardware-scan.nix file.
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable networking
  networking.hostName = "NZXT";
  networking.networkmanager.enable = true;

  # Configure Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hardware
  # Enable bluetooth
  hardware.bluetooth.enable = true;
  powerManagement.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Graphics Drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable Wayland and Hyprland
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  # Desktop Environment and Login Manager
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.gnome.enable = false; # Disable default desktop manager

  # Enable SSH Server
  services.openssh.enable = true;

  # Define a user account.
  users.users.knorr = {
    isNormalUser = true;
    description = "Moritz Knorr";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.bash;
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # Hyprland ecosystem
    hyprbar
    wofi
    hyprlock
    cliphist
    mako
    # System utilities
    networkmanagerapplet
    pavucontrol
    blueman
    # File managers
    thunar
    yazi
    # Applications
    google-chrome
    vscode
    solaar
    # Terminal tools
    tmux
    git
    vim
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
