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
    #../common/optional/adb-rules.nix
    #../common/optional/network-diag.nix
    ../common/optional/steam.nix
    ../common/virtualisation/libvirt.nix

  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";

  hardware.cpu.intel.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "powersave";

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "iomem=relaxed"
      "i915.force_probe=a7a0"
      "i915.enable_guc=2"
    ];
    extraModulePackages = [ ];

    initrd = {
      availableKernelModules = [
        "i915"
        "nvme"
        "xhci_pci"
        "ahci"
        "uas"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
      luks.devices."root".device = "/dev/disk/by-uuid/fd20514c-b8b7-48ca-ac37-5f7460c8565f";
    };

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
    };
  };

  # services.undervolt = {
  #   enable = true;
  #   verbose = true;
  #   uncoreOffset = -40;
  #   coreOffset = -40;
  #   gpuOffset= -40;
  #   analogioOffset = -40;
  # };

  # hardware.usb-modeswitch.enable = true;

  services = {

    libinput = {
      enable = true;
      mouse.accelProfile = "flat";
      touchpad = {
        clickMethod = "clickfinger";
        accelSpeed = "-0.15";
      };
    };
  };

  environment.sessionVariables = {
    STEAM_FORCE_DESKTOPUI_SCALING = "2";
  };

  environment.sessionVariables = {
    QT_AUTO_SCREEN_SCALE_FACTOR = "auto";
  };
}
