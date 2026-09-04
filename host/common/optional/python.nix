{ pkgs, ... }:

let
  python-pkgs =
    ps: with ps; [
      gmsh
    ];
in
{
  environment.systemPackages = [
    (pkgs.python3.withPackages python-pkgs)
  ];
}
