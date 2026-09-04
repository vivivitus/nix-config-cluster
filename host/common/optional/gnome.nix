{ pkgs, lib, ... }:

{
  # falscher ort, nur zum test
  programs.kdeconnect.enable = true;
  #programs.xwayland.enable = true;

  # some programs crash on open file
  environment.extraInit = ''
    export XDG_DATA_DIRS="$XDG_DATA_DIRS:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  '';

  # nautilus thumbnails etc.
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
    lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0"
      (
        with pkgs.gst_all_1;
        [
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
        ]
      );

  environment = {
    systemPackages = with pkgs; [
      ffmpeg-headless
      ffmpegthumbnailer
      libheif.bin
      libheif.out
      libavif
      libjxl
      webp-pixbuf-loader
      f3d

      gdk-pixbuf
      (writeTextFile {
        name = "raw-embedded-jpeg-thumbnailer";
        destination = "/share/thumbnailers/raw-embedded-jpeg.thumbnailer";
        text = ''
          [Thumbnailer Entry]
          TryExec=gdk-pixbuf-thumbnailer
          Exec=gdk-pixbuf-thumbnailer -s %s %u %o
          MimeType=image/x-canon-crw;image/x-canon-cr2;image/x-canon-cr3;image/x-adobe-dng;image/x-dng;
        '';
      })
    ];

    gnome.excludePackages = (
      with pkgs;
      [
        gnome-tour
        yelp
        epiphany
        geary
        cheese
        gnome-calculator
        gvfs
        gnome-characters
        gnome-weather
        gnome-clocks
      ]
    );
  };

  services = {
    udev.packages = with pkgs; [ gnome-settings-daemon ];
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    xserver = {
      excludePackages = [ pkgs.xterm ];
    };

    gnome = {
      # network sharing via DAV
      gnome-user-share.enable = true;

      gnome-settings-daemon.enable = true;
      gnome-online-accounts.enable = true;
      gnome-keyring.enable = true;
      evolution-data-server.enable = true;
    };

    colord.enable = true;
  };
}
