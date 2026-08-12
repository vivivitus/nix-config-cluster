{ lib, inputs, outputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };
  security.sudo.wheelNeedsPassword = false;

  systemd.user.extraConfig = ''
    DefaultEnvironment="PATH=/run/current-system/sw/bin:LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib"
  '';

  systemd.sockets.nix-daemon = {
    socketConfig.ListenStream = "/run/nix/daemon-socket/socket";
  };

  nixpkgs = {
    config = {
      permittedInsecurePackages = [  ];
      allowBroken = true;
      allowUnfree = true;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.irqbalance.enable = true;

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=64M
    MaxRetentionSec=1day
  '';

  boot = {
    tmp.useTmpfs = true;
    tmp.tmpfsSize = "25%";
  };

  nix.extraOptions = ''
    min-free = ${toString (500 * 1024 * 1024)}
  '';

  nix.settings = {
    auto-optimise-store = false;
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = [ "root" "@wheel" ];
  };

  services.fail2ban = {
    enable = true;
    bantime-increment = {
      enable = true;
      maxtime = "24h";
    };
    ignoreIP = [
      "10.0.1.1/24" "2a02:168:5bab:1::1/64"
      "10.0.10.1/24" "2a02:168:5bab:10::1/64"
    ];
  };

  programs.nix-ld.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # use persist storage, because otherwise the key isn't ready when sops is
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;
  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
}