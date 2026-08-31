{
  lib,
  inputs,
  outputs,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./impermanence.nix
    ./networking.nix
  ]
  ++ (builtins.attrValues outputs.nixosModules);

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

  # sops-nix Konfiguration mit verweis auf /persist, da der key beim booten sonst nicht vorhanden ist
  sops = {
    age = {
      sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
    defaultSopsFile = ../../../secrets/secrets.yaml;
  };

  programs.ssh.extraConfig = ''
    Include /etc/ssh/ssh_config.d/*.conf
  '';
}
