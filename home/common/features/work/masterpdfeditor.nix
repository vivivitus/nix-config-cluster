{ pkgs, ... }:

let
  masterpdfeditor = pkgs.stdenv.mkDerivation {
    pname = "masterpdfeditor";
    version = "5.9.99";

    src = pkgs.fetchurl {
      url = "https://code-industry.net/public/master-pdf-editor-5.9.99-qt6.x86_64.tar.gz";
      hash = "sha256-Y7fXvjfPrGDFCt4+6tK7wtK/4WNonv8JKy4L4SO3S30=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.qt6.wrapQtAppsHook
    ];

    buildInputs = [
      (pkgs.lib.getLib pkgs.stdenv.cc.cc)
      pkgs.cups
      pkgs.qt6.qtbase
      pkgs.qt6.qtsvg
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qt5compat
      pkgs.libinput
      pkgs.mtdev
      pkgs.nss
      pkgs.pkcs11helper
      pkgs.sane-backends
    ];

    dontStrip = true;

    installPhase = ''
      runHook preInstall

      substituteInPlace usr/share/applications/net.code-industry.masterpdfeditor5.desktop \
        --replace-fail "Exec=/opt/master-pdf-editor-5/masterpdfeditor5" "Exec=masterpdfeditor5" \
        --replace-fail "Path=/opt/master-pdf-editor-5" "Path=$out/share/masterpdfeditor" \
        --replace-fail "/opt/master-pdf-editor-5/masterpdfeditor5.png" "masterpdfeditor5"

      cp -r usr $out

      install -Dm755 masterpdfeditor5 -t $out/share/masterpdfeditor

      cp -r stamps templates lang fonts $out/share/masterpdfeditor

      mkdir -p $out/bin
      ln -s $out/share/masterpdfeditor/masterpdfeditor5 \
        $out/bin/masterpdfeditor5

      runHook postInstall
    '';

    preFixup = ''
      patchelf $out/share/masterpdfeditor/masterpdfeditor5 \
        --add-needed libsmime3.so
    '';

    meta = {
      description = "Master PDF Editor";
      homepage = "https://code-industry.net/free-pdf-editor/";
      license = pkgs.lib.licenses.unfreeRedistributable;
      platforms = [ "x86_64-linux" ];
      mainProgram = "masterpdfeditor5";
    };
  };
in
{
  home.packages = [
    masterpdfeditor
  ];
}
