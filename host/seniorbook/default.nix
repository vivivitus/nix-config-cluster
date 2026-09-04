{ pkgs, inputs, ... }: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-gpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./storage.nix
    ./networking.nix
    ../common/global
    ../common/user/vivian
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/gnome.nix
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "26.05";

  hardware.cpu.intel.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "powersave";

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    kernelModules = [ "kvm-intel" ];
    kernelParams = [ ];
    extraModulePackages = [ ];

    initrd = {
      availableKernelModules = [
        "i915"
        "uhci_hcd"
        "ehci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
    };

    loader = {
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/sda";
    };
  };
}
