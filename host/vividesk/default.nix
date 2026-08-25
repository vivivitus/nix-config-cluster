{ pkgs, inputs, modulesPath, ... }: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    (modulesPath + "/installer/scan/not-detected.nix")

    ./storage.nix
    ./lm_sensors.nix
    ./networking.nix
    ../common/global
    ../common/user/vivian
    ../common/optional/nix-ld.nix
    ../common/optional/python.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/gnome.nix
    ../common/optional/plymouth.nix
    ../common/optional/steam.nix
    ../common/virtualisation/libvirt.nix
    ../common/virtualisation/bottles.nix
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";

  hardware.enableAllFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  services.ratbagd.enable = true;
  services.xserver.enable = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    kernelModules = [ "kvm-amd" "nct6775" ];
    extraModulePackages = [ ];

    kernelParams = [ 
      "acpi_enforce_resources=lax"
    ];

    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "uas" "usb_storage" "sd_mod" ];
      kernelModules = [ "amdgpu" "dm-snapshot" ];
    };

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      systemd-boot.memtest86.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    amdgpu.overdrive.ppfeaturemask = "0xffffffff";
  };
  
  programs = {
    corectrl = {
      enable = true;
    };
  };

  nixpkgs.config.allowBroken = true;
}
