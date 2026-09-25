{ nixpkgs, system }:

let
  pkgs = import nixpkgs {
    inherit system;

    config = {
      allowUnfree = true;
    };
  };
in

pkgs.mkShell {
  packages = with pkgs; [
    jq
    openssh
    git
  ];

  shellHook = ''
    export NIX_CONFIG="experimental-features = nix-command flakes"

    echo
    echo "========================================"
    echo " NixOS deployment environment"
    echo "========================================"
    echo
    echo "  nix       $(nix --version)"
    echo "  jq        $(jq --version)"
    echo "  ssh       $(ssh -V 2>&1)"
    echo "  git       $(git --version)"
    echo
  '';
}
