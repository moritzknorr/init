{ config, pkgs, ... }:

{
  imports = [
    ./NZXT_hardware-configuration.nix
  ];

  # bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Configure Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hardware
  powerManagement.enable = false;
  # Enable uinput for solaar
  hardware.logitech.wireless.enable = true;
  hardware.uinput.enable = true;
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

  # Enable envs to get the illusion of an old file system, otherwise "#!/bin/bash" does not work
  services.envfs.enable = true;

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
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "lp" "uinput" "seat" "input" "docker"];
    shell = pkgs.bash;
  };
  security.sudo.extraRules = [
    {
      users = [ "knorr" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Add nix-ld to get vscode working:
  programs.nix-ld.enable = true;


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Setup file manager
  services.gvfs.enable = true; # Mount trash and other functionalities
  services.tumbler.enable = true; # Thumbnails
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
    thunar-volman
  ];

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };  

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # Hyprland ecosystem
    waybar
    wofi
    hyprpaper
    hyprlock
    mako
    # Clipboard
    cliphist
    wl-clipboard
    # System utilities
    networkmanagerapplet
    pavucontrol
    blueman
    kitty
    # Office
    libreoffice-qt
    # File managers
    yazi
    # Applications
    solaar
    awscli
    zip
    # Terminal tools
    htop
    btop
    tmux
    git
    vim
    jq
    nodejs_24
    # Screenshot tools
    satty
    slurp
    grim
    geeqie
    # Tools to monitor wayland
    wev
    # Nvidia Tools
    nvtopPackages.full
    # Logitech Options for solaar
    logiops
    # Misc tools to get a working system
    busybox
    toybox
    usbutils
    pciutils
    # Basic Python environment
    (python313.withPackages (ps: with ps; [
      python-dotenv
      requests
      tqdm
      numpy
      pandas
      boto3
      pyyaml
      pyzipper
      httpserver
      gql
      requests_toolbelt
      pydantic
    ]))
  ];
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 8000 8080 3000 ];
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
