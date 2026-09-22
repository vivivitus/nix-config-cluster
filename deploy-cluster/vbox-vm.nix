{
  pkgs,
  lib,
  ...
}:

let
  bootstrapPublicKeyFile = builtins.getEnv "BOOTSTRAP_PUBLIC_KEY_FILE";

  bootstrapPublicKey =
    if bootstrapPublicKeyFile != "" then
      builtins.readFile bootstrapPublicKeyFile
    else
      throw ''
        BOOTSTRAP_PUBLIC_KEY_FILE is not set.
        This configuration is intended to be built by deploy-vbox.sh.
      '';
in
{

  virtualisation.vmVariant.virtualisation.memorySize = 3072;
  virtualisation.diskSize = 16384;
  virtualisation.virtualbox.guest.enable = true;

  boot.initrd.systemd = {
    enable = true;

    services."dev-disk-by\\x2dlabel-nixos.device".unitConfig = {
      JobRunningTimeoutSec = "300s";
    };
  };

  networking.hostName = "vagrant-nixos";

  environment.systemPackages = with pkgs; [
    net-tools
  ];

  services.openssh = {
    enable = true;

    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  users.users.root = {
    shell = lib.mkForce pkgs.bash;

    openssh.authorizedKeys.keys = [
      bootstrapPublicKey
    ];
  };

  system.stateVersion = "26.05";
}
