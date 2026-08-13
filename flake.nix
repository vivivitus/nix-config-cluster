{
inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, sops-nix, disko, impermanence, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
    in
    {
    inherit lib;

    nixosModules = import ./modules;
    overlays = import ./overlays {inherit inputs;};

    nixosConfigurations = {
      n1 = lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs outputs;
          hostName = "n1";
          ipv4Address = "10.0.2.50";
          ipv6Address = "2a02:168:5bab:2::50";
          ipv4Gateway = "10.0.2.1";
          ipv6Gateway = "2a02:168:5bab:2::1";
          ipv4Nameserver = "10.0.2.1";
          ipv6Nameserver = "2a02:168:5bab:2::1";
          interface = "enP4p65s0";
        };
        modules = [
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          ./host/n1
        ];
      };

      n2 = lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          ./host/n2
        ];
      };
      n3 = lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          ./host/n3
        ];
      };
    };

    homeConfigurations = {
      "vivian@n1" = lib.homeManagerConfiguration {
        modules = [
          ./home/vivian/n1.nix
        ];
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
      "vivian@n2" = lib.homeManagerConfiguration {
        modules = [
          ./home/vivian/n2.nix
        ];
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
      "vivian@n3" = lib.homeManagerConfiguration {
        modules = [
          ./home/vivian/n3.nix
        ];
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
    };
  };
}
