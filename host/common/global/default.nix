{ config, lib, inputs, outputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./impermanence.nix
    ./networking.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  # inputs und outputs an home-manager weiterreichen
  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  # Keine Passwort-Eingabe für sudo
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

  # # Volatiler journal, um Festplatte zu schonen
  # services.journald.extraConfig = ''
  #   Storage=volatile
  #   RuntimeMaxUse=64M
  #   MaxRetentionSec=1day
  # '';

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

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # sops-nix Konfiguration mit verweis auf /persist, da der key beim booten sonst nicht vorhanden ist
  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;
  sops.defaultSopsFile = ../../../secrets/secrets.yaml;

  # key damit das private git vom cluster geclont werden kann
  sops.secrets.cluster-deploy-key = {
    path = "/etc/ssh/cluster-deploy-key";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  programs.ssh.extraConfig = ''
    Include /etc/ssh/ssh_config.d/*.conf
  '';
  
  environment.etc."ssh/ssh_config.d/cluster-deploy-key.conf".text = ''
    Host gitlab.com-the-cluster
      HostName gitlab.com
      User git
      IdentityFile ${config.sops.secrets.cluster-deploy-key.path}
      IdentitiesOnly yes
  '';

  # # Mögliche Fixes für das NVME Problem
  # boot.kernelParams = [
  #   "nvme_core.default_ps_max_latency_us=0"
  # ];

  # boot.kernelParams = [
  #   "pcie_aspm=off"
  # ];
}