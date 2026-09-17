{ ... }: {

  boot.zfs.forceImportRoot = false;
  networking.interfaces.enp0s3.useDHCP = true;
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  # Trage hier deinen Public Key ein
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPqON/KlzvnuEAi2DknZm1PL7ypcGAqC7q6Pwr8DJyI vivian@vividesk-2021-12-10"
  ];
}
