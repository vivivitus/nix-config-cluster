{ lib, inputs, outputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./networking.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  # Keine Passwort-Eingabe für sudo
  home-manager.extraSpecialArgs = { inherit inputs outputs; };
  security.sudo.wheelNeedsPassword = false;

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
      permittedInsecurePackages = [  ];
      allowBroken = true;
      allowUnfree = true;
    };
  };

  # Wöchentlicher garbage collect, um das System sauber zu halten
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.irqbalance.enable = true;

  # Teil des RAMs wird als zstd komprimierter swap genutzt
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Volatiler journal, um Festplatte zu schonen
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=64M
    MaxRetentionSec=1day
  '';

  # default tmpfs im ram halten, um Festplatte zu schonen
  boot = {
    tmp.useTmpfs = true;
    tmp.tmpfsSize = "25%";
  };

  # Minimaler verbleibender Speicher
  nix.extraOptions = ''
    min-free = ${toString (500 * 1024 * 1024)}
  '';

  nix.settings = {
    auto-optimise-store = true;
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

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # sops-nix Konfiguration mit verweis auf /persist, da der key beim booten sonst nicht vorhanden ist
  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;
  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
}