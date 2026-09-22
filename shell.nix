{ nixpkgs }:

let
  pkgs = import nixpkgs {
    system = "x86_64-linux";

    config = {
      allowUnfree = true;
    };
  };

  vagrant = pkgs.vagrant.overrideAttrs (old: {
    doInstallCheck = false;

    postPatch = (old.postPatch or "") + ''
      substituteInPlace lib/ruby/gems/3.4.0/gems/vagrant-2.4.9/lib/vagrant/plugin/manager.rb \
        --replace-fail \
          "dir = '${placeholder "out"}/vagrant-plugins'" \
          'dir = ENV["VAGRANT_PLUGIN_DIR"]'
    '';
  });
in

pkgs.mkShell {
  packages = with pkgs; [
    jq
    vagrant
    openssh
    git
  ];

  shellHook = ''
    export NIX_CONFIG="experimental-features = nix-command flakes"

    export VAGRANT_HOME="''${VAGRANT_HOME:-$PWD/.vagrant-home}"
    export VAGRANT_PLUGIN_DIR="$VAGRANT_HOME/vagrant-plugins"

    mkdir -p "$VAGRANT_PLUGIN_DIR"

    if [ -n "''${WSL_DISTRO_NAME:-}" ]; then
      export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS=1
    fi

    echo
    echo "========================================"
    echo " NixOS deployment environment"
    echo "========================================"
    echo
    echo "  nix       $(nix --version)"
    echo "  jq        $(jq --version)"
    echo "  vagrant   $(vagrant --version)"
    echo "  ssh       $(ssh -V 2>&1)"
    echo "  git       $(git --version)"
    echo
  '';
}
