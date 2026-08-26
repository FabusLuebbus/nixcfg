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

      # One nixosSystem per host, all sharing the same NixOS/home-manager
      # wiring. Add a new host by dropping a `hosts/<hostname>/` directory
      # (modeled on an existing one) and adding one line below.
      # `homeModule` picks which home-manager config the host's user gets —
      # desktops use the full GUI-heavy ./home, headless boxes pass a
      # slimmer one instead (see ./home/server.nix).
      mkHost = hostname: homeModule: nixpkgs.lib.nixosSystem {
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
            home-manager.users.${username} = import homeModule;
          }
        ];
      };
    in
    {
      nixosConfigurations.framenix = mkHost "framenix" ./home; # laptop
      nixosConfigurations.desknix = mkHost "desknix" ./home; # nvidia desktop
      nixosConfigurations.servnix = mkHost "servnix" ./home/server.nix; # old laptop turned file/media server
    };
}
