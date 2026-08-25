{ config, pkgs, inputs, ... }: {

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";

    # profiles.vivian = {
    #   id = 0;
    #   name = "vivian";
    #   isDefault = true;

    #   # HIER DIE ÄNDERUNG: .packages anhängen
    #   extensions.packages = let
    #     addons = inputs.firefox-addons.packages.${pkgs.system};
    #   in [
    #     addons.ublock-origin
    #     addons.canvasblocker
    #     addons.gsconnect
    #   ];

    #   settings = {
    #     "extensions.autoDisableScopes" = 0;
    #   };
    # };
  };
}