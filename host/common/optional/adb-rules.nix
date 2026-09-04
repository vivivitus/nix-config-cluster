{ pkgs, ... }:

{
  programs.adb.enable = true;
  users.users.vivian.extraGroups = [ "adbusers" ];

  services.udev.packages = [
    pkgs.android-udev-rules
  ];
}
