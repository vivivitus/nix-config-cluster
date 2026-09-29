{
  lib,
  inputs,
  outputs,
  diskoModule,
  clusterTarget,
  hostName,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    # inputs.disko.nixosModules.disko
    diskoModule
    inputs.impermanence.nixosModules.impermanence
    ./impermanence.nix
    ./networking.nix
  ]
  ++ (builtins.attrValues outputs.nixosModules);

  # inputs und outputs an home-manager weiterreichen
  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  # Passwort für sudo benötigt
  security.sudo.wheelNeedsPassword = true;

  # Damit VS-Code via SSH funktioniert
  programs.nix-ld.enable = true;
  systemd.user.extraConfig = ''
    DefaultEnvironment="PATH=/run/current-system/sw/bin:LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib"
  '';

  # Damit nixos-rebuild switch ausgeführt werden kann mit einem ro root Filesystem
  systemd.sockets.nix-daemon = {
    socketConfig.ListenStream = "/run/nix/daemon-socket/socket";
  };

  # Kein Gemeckere bei gewissen Paketen
  nixpkgs = {
    config = {
      permittedInsecurePackages = [ ];
      allowBroken = true;
      allowUnfree = true;
    };
  };

  # Wöchentlicher garbage collect, um das System sauber zu halten
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    extraOptions = ''
      min-free = ${toString (500 * 1024 * 1024)}
    '';
    settings = {
      auto-optimise-store = true;
      experimental-features = lib.mkDefault "nix-command flakes";
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  sops = {
    age = {
      keyFile = "/persist/var/lib/sops-nix/key.txt";
    };
  };

  sops.secrets = {
    password-alex = {
      sopsFile = ../../../secrets/common/admins.yaml;
      neededForUsers = true;
    };

    password-vivian = {
      sopsFile = ../../../secrets/common/admins.yaml;
      neededForUsers = true;
    };

    cluster-join-token = {
      sopsFile = ../../../secrets/${clusterTarget}/cluster.yaml;
    };

    cluster-deploy-key = {
      sopsFile = ../../../secrets/${clusterTarget}/cluster.yaml;
    };

    gitlab-vault-token = {
      sopsFile = ../../../secrets/${clusterTarget}/cluster.yaml;
    };

    gitlab-argocd-token = {
      sopsFile = ../../../secrets/${clusterTarget}/cluster.yaml;
    };

    ssh-host-private-key = {
      sopsFile = ../../../secrets/${clusterTarget}/hosts/${hostName}.yaml;
      mode = "0600";
    };
  };

  programs.ssh.extraConfig = ''
    Include /etc/ssh/ssh_config.d/*.conf
  '';
}
