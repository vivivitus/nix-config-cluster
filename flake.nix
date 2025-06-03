{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
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
          ./host/test-node
        ];
      };
      test-node2 = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./host/test-node
        ];
      };
      test-node3 = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./host/test-node
        ];
      };
      n1 = lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          nixos-hardware.nixosModules.rockchip
          ./host/n1
        ];
      };
    };

    homeConfigurations = {
      "vivian@test-node1" = lib.homeManagerConfiguration {
        modules = [ ./home/vivian/test-node.nix ];
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
      "vivian@test-node2" = lib.homeManagerConfiguration {
        modules = [ ./home/vivian/test-node.nix ];
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
      "vivian@test-node3" = lib.homeManagerConfiguration {
        modules = [ ./home/vivian/test-node.nix ];
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
      "vivian@n1" = lib.homeManagerConfiguration {
        modules = [ ./home/vivian/n1.nix ];
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
    };
  };
}
