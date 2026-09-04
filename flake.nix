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

      clusterConfigs = {
        prod = {
          gitRepository = "git@gitlab.com:kubernarnold/the-cluster.git";
          gitBranch = "main";
          bootstrapRootApp = "root-app-prod.yaml";
        };

        staging = {
          gitRepository = "git@gitlab.com:kubernarnold/the-cluster.git";
          gitBranch = "developing-config";
          bootstrapRootApp = "root-app-staging.yaml";
        };
      };

      hostConfigs = {
        n1 = {
          clusterTarget = "staging";
          clusterBootstrap = true;
          ipv4Address = "10.0.2.50";
          ipv6Address = "2a02:168:5bab:2::50";
        };

        n2 = {
          clusterTarget = "staging";
          ipv4Address = "10.0.2.51";
          ipv6Address = "2a02:168:5bab:2::51";
        };

        n3 = {
          clusterTarget = "staging";
          ipv4Address = "10.0.2.52";
          ipv6Address = "2a02:168:5bab:2::52";
        };
        n1-vm = {
          isVirtualMachine = true;
          clusterTarget = "staging";
          clusterBootstrap = true;
          interface = "enp0s3";
          ipv4Address = "192.168.56.101";
          ipv4Gateway = "192.168.56.1";
          ipv4Nameserver = "8.8.8.8";
          ipv6Address = "fd42:42:42::101";
        };

        n2-vm = {
          isVirtualMachine = true;
          clusterTarget = "staging";
          interface = "enp0s3";
          ipv4Address = "192.168.56.102";
          ipv4Gateway = "192.168.56.1";
          ipv4Nameserver = "8.8.8.8";
          ipv6Address = "fd42:42:42::102";
        };

        n3-vm = {
          isVirtualMachine = true;
          clusterTarget = "staging";
          interface = "enp0s3";
          ipv4Address = "192.168.56.103";
          ipv4Gateway = "192.168.56.1";
          ipv4Nameserver = "8.8.8.8";
          ipv6Address = "fd42:42:42::103";
        };
      };

      networkDefaults = {
        ipv4Gateway = "10.0.2.1";
        ipv6Gateway = "2a02:168:5bab:2::1";
        ipv4Nameserver = "10.0.2.1";
        ipv6Nameserver = "2a02:168:5bab:2::1";
        interface = "enP4p65s0";
      };

      hostDefaults = {
        isFallback = false;
        isVirtualMachine = false;
        clusterBootstrap = false;
      };

      mkHostArgs =
        hostName:
        let
          hostConfig = hostDefaults // hostConfigs.${hostName};
          clusterConfig = clusterConfigs.${hostConfig.clusterTarget};
          networkConfig = networkDefaults // hostConfig;
        in
        {
          inherit
            inputs
            outputs
            hostName
            clusterConfig
            ;

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
            ;

          allHosts = hostConfigs;
        };
    in
    {
      inherit lib;

      nixosModules = import ./modules;

      overlays = import ./overlays {
        inherit inputs;
      };

      nixosConfigurations = {
        n1 = lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = mkHostArgs "n1";
          modules = [
            ./host/n1
          ];
        };

        n2 = lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = mkHostArgs "n2";
          modules = [
            ./host/n2
          ];
        };

        n3 = lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = mkHostArgs "n3";
          modules = [
            ./host/n3
          ];
        };
        n1-vm = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = mkHostArgs "n1-vm";
          modules = [
            ./host/n1
          ];
        };

        n2-vm = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = mkHostArgs "n2-vm";
          modules = [
            ./host/n2
          ];
        };

        n3-vm = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = mkHostArgs "n3-vm";
          modules = [
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
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n2" = lib.homeManagerConfiguration {
          modules = [
            ./home/vivian/n2.nix
          ];
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n3" = lib.homeManagerConfiguration {
          modules = [
            ./home/vivian/n3.nix
          ];
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };
        "vivian@n1-vm" = lib.homeManagerConfiguration {
          modules = [
            ./home/vivian/n1.nix
          ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n2-vm" = lib.homeManagerConfiguration {
          modules = [
            ./home/vivian/n2.nix
          ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };

        "vivian@n3-vm" = lib.homeManagerConfiguration {
          modules = [
            ./home/vivian/n3.nix
          ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
        };
      };
    };
}
