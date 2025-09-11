{ lib, inputs, outputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    #./k3s.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };
  security.sudo.wheelNeedsPassword = false;

  systemd.user.extraConfig = ''
    DefaultEnvironment="PATH=/run/current-system/sw/bin:LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib"
  '';

  nixpkgs = {
    config = {
      permittedInsecurePackages = [  ];
      allowBroken = true;
      allowUnfree = true;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  nix.extraOptions = ''
    min-free = ${toString (500 * 1024 * 1024)}
  '';

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = [ "root" "@wheel" ];
  };

  programs.nix-ld.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;
  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
}
