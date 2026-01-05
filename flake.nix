{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, sops-nix, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
    in
    {
    inherit lib;

    nixosModules = import ./modules;
    overlays = import ./overlays {inherit inputs;};

    nixosConfigurations = {
      test-node1 = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./host/test-node1
          sops-nix.nixosModules.sops
        ];
      };
      test-node2 = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./host/test-node2
          sops-nix.nixosModules.sops
        ];
      };
      test-node3 = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./host/test-node3
          sops-nix.nixosModules.sops
        ];
      };
      n1 = lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./host/n1
          sops-nix.nixosModules.sops
        ];
      };
      n2 = lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./host/n2
          sops-nix.nixosModules.sops
        ];
      };
      n3 = lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./host/n3
          sops-nix.nixosModules.sops
        ];
      };
    };

    homeConfigurations = {
      "vivian@test-node1" = lib.homeManagerConfiguration {
        modules = [
          ./home/vivian/test-node1.nix
        ];
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
      "vivian@test-node2" = lib.homeManagerConfiguration {
        modules = [
          ./home/vivian/test-node1.nix
        ];
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
      "vivian@test-node3" = lib.homeManagerConfiguration {
        modules = [
          ./home/vivian/test-node1.nix
        ];
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
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
