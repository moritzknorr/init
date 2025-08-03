{ config, pkgs, ... }:

{
  imports = [
    ./NZXT_hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Configure console keymap
  console.keyMap = "de";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable networking
  networking.hostName = "NZXT";
  networking.networkmanager.enable = true;

  # Configure Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hardware
  powerManagement.enable = false;
  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Graphics Drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };

  # Enable Wayland and Hyprland
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  # Enable SSH Server
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # Define a user account.
  users.users.knorr = {
    isNormalUser = true;
    description = "Moritz Knorr";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "lp" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdkYyl7z53CxVnxHGYxCC8f/1U7hZeilSONexi2VP5Cfbg8BgR+ZmwK0KrCBis5sB+mSyCC41KxYfyDHcSwIBYiVgAiFEXiTN+8Ers6HYri9EYxx32JqKKaFCL7euvIQqrukaVR2Jd14nVctaUakzAHPJ/hak3dwb/e5zhZ2Hdd4zQGbuV20cEAJEBS0SqW5uzNm9PN67+7s0zQPNtpSuolrLPf6uK/JqMqdV0ljMZYUKwlAhYiidQQU0n/8sn/0AkZC8EqI3Q3lbNGIcrn10mWBa0UN09cqBm4CrLZX40Y3EBJGxL+pYBIN8ZmzK+1A8pyorbZy2FErFSFPYYwKjN moritzknorr"
    ]
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # Hyprland ecosystem
    waybar
    wofi
    hyprlock
    cliphist
    mako
    # System utilities
    networkmanagerapplet
    pavucontrol
    blueman
    kitty
    # File managers
    nemo
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
