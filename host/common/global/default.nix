{ inputs, outputs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./locales.nix
    ./nix.nix
    ./timezone.nix
  ]
  ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  nixpkgs = {
    #overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
}
