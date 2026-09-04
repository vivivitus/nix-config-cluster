{ pkgs, ... }: {
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      glib
      xorg.libX11
      # Hier kannst du weitere Bibliotheken ergänzen, falls eine Extension danach verlangt
    ];
  };
}
