{ pkgs, ... }:

{
  services.udev.packages = [ pkgs.picoscope.rules ];
  users.groups.pico = { };
  users.users.vivian.extraGroups = [ "pico" ];
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", MODE="0666",GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", MODE="0666",GROUP="plugdev"
  '';
}
