{ pkgs, ... }:

{
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  users.extraGroups.vboxusers.members = [ "vivian" ];
  environment.systemPackages = [
    pkgs.linuxKernel.packages.linux_zen.virtualbox
  ];
}
