{ pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [
    virt-manager
    spice-gtk
  ];
  security.wrappers.spice-client-glib-usb-acl-helper.owner = "root";
  security.wrappers.spice-client-glib-usb-acl-helper.group = "root";
  security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
}
