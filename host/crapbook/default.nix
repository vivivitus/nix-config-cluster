{ pkgs, inputs, ... }: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    # inputs.hardware.nixosModules.common-gpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./storage.nix
    ./networking.nix
    ./hibernate.nix
    ../common/global
    ../common/user/vivian
    ../common/optional/python.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/gnome.nix
    ../common/optional/plymouth.nix
    ../common/optional/adb-rules.nix
    ../common/optional/network-diag.nix
    ../common/optional/steam.nix
    ../common/optional/build-env.nix
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";

  hardware.cpu.intel.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "powersave";

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
      luks.devices."root".device = "/dev/disk/by-uuid/5aafefc9-e0f9-46ee-a217-7b453219f36e";
    };

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
    };
  };
}
