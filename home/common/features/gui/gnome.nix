{ pkgs, lib, ... }:

let
  mkTuple = lib.hm.gvariant.mkTuple;
in
{
  home.packages = with pkgs; [
    dconf-editor
    gnomeExtensions.appindicator
    gnomeExtensions.tiling-shell
    gnomeExtensions.caffeine
    gnomeExtensions.gsconnect
    gnomeExtensions.freon
   # gnomeExtensions.switch-workspaces-on-active-monitor
  ];

  dconf.settings = {

    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = false;
      tap-to-click = true;
    };

    "org/gnome/desktop/input-sources" = {
      sources = [ (mkTuple [ "xkb" "ch" ]) ];
    };

    "org/gnome/system/location" = {
      enabled = true;
    };

    "org/gnome/desktop/datetime" = {
      automatic-timezone = true;
    };

    "org/gnome/Console" = {
      theme = "auto";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "caffeine@patapon.info"
        "gsconnect@andyholmes.github.io"
        "freon@UshakovVasilii_Github.yahoo.com"
        "tilingshell@ferrarodomenico.com"
        ];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/list-view" = {
      default-zoom-level = "small";
    };

    # Swiss german formats like CHF, meters, etc.
    "system/locale" = {
      region = "de_CH.UTF-8";
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = ["Utilities" "YaST" "Games" "KDEConnect" ];
    };

    "org/gnome/desktop/app-folders/folders/Games" = {
      categories = [ "Game" ];
      name = "Games";
    };

    "org/gnome/desktop/app-folders/folders/KDEConnect" = {
      apps = [
        "org.kde.kdeconnect.app.desktop"
        "org.kde.kdeconnect.daemon.desktop"
        "org.kde.kdeconnect.handler.desktop"
        "org.kde.kdeconnect.nonplasma.desktop"
        "org.kde.kdeconnect_open.desktop"
        "org.kde.kdeconnect-settings.desktop"
        "org.kde.kdeconnect.sms.desktop"
      ];
      name = "KDE Connect";
    };
  };
}