Install [edk2-uefi firmware](https://github.com/edk2-porting/edk2-rk3588)
-
- Enter Maskrom mode by pressing **RST** shortly while **MASK** is pressed.
- Upload MiniLoader
  - ``` rkdeveloptool db MiniLoaderAll.bin ```
- Select EMMC
  - ``` rkdeveloptool cs 1 ```
- Flash edk2 image
  - ``` rkdeveloptool wl 0 <image> ```

Installation

nix run github:nix-community/nixos-anywhere -- --extra-files ./n1 --build-on-remote --flake github:vivivitus/nix-config-cluster#n1 root@10.0.2.50
