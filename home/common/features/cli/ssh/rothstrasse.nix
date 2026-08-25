{ ... }: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "n1" = {
        hostname = "10.0.2.50";
        user = "vivian";
      };

      "n2" = {
        hostname = "10.0.2.51";
        user = "vivian";
      };

      "n3" = {
        hostname = "10.0.2.52";
        user = "vivian";
      };

      "nix-init" = {
        hostname = "nix-init.lan";
        user = "vivian";
      };

      "oskar" = {
        hostname = "oskar.lan";
        user = "vivian";
      };

      "sopinian" = {
        hostname = "sopinian.lan";
        user = "vivian";
      };
    };
  };
}