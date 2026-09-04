{
  description = "Personal NixOS and Home-Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    hardware = {
      url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;

      hosts = {
        vividesk = {
          arch = "x86_64-linux";
          users = [ "vivian" ];
        };
        vivibook = {
          arch = "x86_64-linux";
          users = [ "vivian" ];
        };
        crapbook = {
          arch = "x86_64-linux";
          users = [ "vivian" ];
        };
        seniorbook = {
          arch = "x86_64-linux";
          users = [ "vivian" ];
        };
        sopinian = {
          arch = "x86_64-linux";
          users = [ "vivian" ];
        };
      };

      architectures = lib.lists.unique (lib.mapAttrsToList (name: host: host.arch) hosts);
      perArchitecture = f: lib.genAttrs architectures (arch: f nixpkgs.legacyPackages.${arch});

      mkSystem =
        hostname: hostConfig:
        lib.nixosSystem {
          system = hostConfig.arch;
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./host/${hostname}
          ];
        };

      mkHome = hostname: hostConfig: username: {
        name = "${username}@${hostname}";
        value = lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${hostConfig.arch};
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home/${username}/${hostname}.nix ];
        };
      };

      generateAllHomes = lib.mapAttrsToList (
        hostname: hostConfig: map (username: mkHome hostname hostConfig username) hostConfig.users
      );

    in
    {
      inherit lib;

      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
      overlays = import ./overlays { inherit inputs outputs; };
      packages = perArchitecture (pkgs: import ./pkgs { inherit pkgs; });

      nixosConfigurations = lib.mapAttrs mkSystem hosts;
      homeConfigurations = lib.listToAttrs (lib.concatLists (generateAllHomes hosts));
    };
}
