{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      home-manager,
      ...
    }@inputs:

    let
      inherit (self) outputs;

      lib = nixpkgs.lib // home-manager.lib;

      inventory = import ./inventory.nix;
      inherit (inventory) admins clusters hosts;

      networkDefaults = {
        interface = "enP4p65s0";
        dhcpInterface = null;
        ipv4Gateway = null;
        ipv6Gateway = null;
        ipv4Nameserver = null;
        ipv6Nameserver = null;
      };

      hostDefaults = {
        isFallback = false;
        isVirtualMachine = false;
        clusterBootstrap = false;
      };

      mkHostConfig = hostName: hostDefaults // hosts.${hostName};

      mkNetworkConfig = hostConfig: networkDefaults // hostConfig;

      diskoPatched = nixpkgs.legacyPackages.x86_64-linux.applyPatches {
        name = "disko-patched";
        src = inputs.disko;
        patches = [
          ./patches/disko-umount.patch
        ];
      };

      mkHostArgs =
        hostName:
        let
          hostConfig = mkHostConfig hostName;
          clusterConfig = clusters.${hostConfig.clusterTarget};
          networkConfig = mkNetworkConfig hostConfig;
        in
        {
          inherit
            inputs
            outputs
            hostName
            clusterConfig
            ;

          diskoModule = "${diskoPatched}/module.nix";

          inherit (hostConfig)
            isFallback
            isVirtualMachine
            clusterTarget
            clusterBootstrap
            ipv4Address
            ipv6Address
            ;

          inherit (networkConfig)
            ipv4Gateway
            ipv6Gateway
            ipv4Nameserver
            ipv6Nameserver
            interface
            dhcpInterface
            ;

          allHosts = hosts;
        };

      deployTargets = lib.mapAttrs (
        hostName: _:
        let
          hostConfig = mkHostConfig hostName;
          networkConfig = mkNetworkConfig hostConfig;
        in
        {
          inherit hostName;

          inherit (hostConfig)
            system
            isFallback
            isVirtualMachine
            clusterTarget
            clusterBootstrap
            ipv4Address
            ipv6Address
            ;

          inherit (networkConfig)
            ipv4Gateway
            ipv6Gateway
            ipv4Nameserver
            ipv6Nameserver
            interface
            dhcpInterface
            ;
        }
      ) hosts;
    in
    {
      inherit lib;
      inherit deployTargets;

      devShells = {
        x86_64-linux.default = import ./shell.nix {
          inherit nixpkgs;
          system = "x86_64-linux";
        };
      };

      nixosModules = import ./modules;

      overlays = import ./overlays {
        inherit inputs;
      };

      nixosConfigurations = {

        n1 = lib.nixosSystem {
          system = hosts.n1.system;
          specialArgs = mkHostArgs "n1";
          modules = [ ./host/n1 ];
        };

        n2 = lib.nixosSystem {
          system = hosts.n2.system;
          specialArgs = mkHostArgs "n2";
          modules = [ ./host/n2 ];
        };

        n3 = lib.nixosSystem {
          system = hosts.n3.system;
          specialArgs = mkHostArgs "n3";
          modules = [ ./host/n3 ];
        };

        n1-vm = lib.nixosSystem {
          system = hosts.n1-vm.system;
          specialArgs = mkHostArgs "n1-vm";
          modules = [ ./host/n1 ];
        };

        n2-vm = lib.nixosSystem {
          system = hosts.n2-vm.system;
          specialArgs = mkHostArgs "n2-vm";
          modules = [ ./host/n2 ];
        };

        n3-vm = lib.nixosSystem {
          system = hosts.n3-vm.system;
          specialArgs = mkHostArgs "n3-vm";
          modules = [ ./host/n3 ];
        };
      };

      homeConfigurations = {
        "vivian@n1" = lib.homeManagerConfiguration {
          modules = [ ./home/user/vivian/production.nix ];
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n2" = lib.homeManagerConfiguration {
          modules = [ ./home/user/vivian/production.nix ];
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n3" = lib.homeManagerConfiguration {
          modules = [ ./home/user/vivian/production.nix ];
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n1-vm" = lib.homeManagerConfiguration {
          modules = [ ./home/user/vivian/development.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n2-vm" = lib.homeManagerConfiguration {
          modules = [ ./home/user/vivian/staging.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n3-vm" = lib.homeManagerConfiguration {
          modules = [ ./home/user/vivian/staging.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "alex@n1-vm" = lib.homeManagerConfiguration {
          modules = [ ./home/user/alex/staging.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "alex@n2-vm" = lib.homeManagerConfiguration {
          modules = [ ./home/user/alex/staging.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "alex@n3-vm" = lib.homeManagerConfiguration {
          modules = [ ./home/user/alex/staging.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };
      };
    };
}
