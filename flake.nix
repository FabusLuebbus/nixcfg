{
  description = "NixOS + home-manager configuration";

  inputs = {
    # Stable channel, matching the 26.05 install ISO.
    # To move to rolling later, change this ONE line to:
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      system = "x86_64-linux";
      username = "fabian";

      # One nixosSystem per host, all sharing the same user/home-manager wiring.
      # Add a new host by dropping a `hosts/<hostname>/` directory (modeled on
      # an existing one) and adding one line below.
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;

        # Makes `inputs`, `username` and `hostname` available inside every module.
        specialArgs = { inherit inputs username hostname; };

        modules = [
          ./hosts/${hostname}

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = import ./home;
          }
        ];
      };
    in
    {
      nixosConfigurations.framenix = mkHost "framenix"; # laptop
      nixosConfigurations.desknix = mkHost "desknix"; # nvidia desktop
    };
}
