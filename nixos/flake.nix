# flake.nix
{
  description = "A basic NixOS configuration with flakes and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    solaar = { url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.NZXT = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit home-manager; };
      modules = [
        ./configuration.nix
        solaar.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.knorr = import ./home.nix;
        }
      ];
    };
  };
}
