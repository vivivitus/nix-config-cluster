{ pkgs, lib, ... }:

let
  pname = "org.freecadweb.FreeCAD.Link";
  arch = "x86_64";
  version = "py3.11-20231102";
  name = "${pname}-${arch}-${version}";

  src = pkgs.fetchurl {
    url = "https://github.com/realthunder/FreeCAD/releases/download/Tip/FreeCAD-Link-Tip-Linux-${arch}-${version}.AppImage";
    sha256 = "2c3ce69a466ee5331099ddacd9234585a5a6422ced78f93530480f17cc3e2510";
  };

  appimageContents = pkgs.appimageTools.extractType2 { inherit name src; };
in
pkgs.appimageTools.wrapType2 rec {
  inherit name src;

  extraInstallCommands = ''
    mv $out/bin/${name} $out/bin/${pname}
    install -m 444 -D ${appimageContents}/org.freecadweb.FreeCAD.Link.desktop $out/share/applications/${pname}.desktop

    install -m 444 -D ${appimageContents}/${pname}.png $out/share/icons/hicolor/512x512/apps/${pname}.png

    substituteInPlace $out/share/applications/${pname}.desktop \
    	--replace 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'
  '';

  meta = with lib; {
    description = "A friendly cross-platform Installer for Ubuntu Touch.";
    homepage = "https://devices.ubuntu-touch.io/installer";
    license = licenses.gpl3;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };
}