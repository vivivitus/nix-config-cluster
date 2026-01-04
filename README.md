### Preparation

(Temporary until a better solution is found)

Installation of the [edk2-uefi firmware](https://github.com/edk2-porting/edk2-rk3588):

- Enter Maskrom mode by pressing **RST** shortly while **MASK** is pressed.
- Upload MiniLoader ``` rkdeveloptool db Downloads/MiniLoaderAll.bin ```
- Select EMMC ``` rkdeveloptool cs 1 ```
- Flash edk2 image ``` rkdeveloptool wl 0 /home/vivian/Downloads/nanopc-cm3588-nas_UEFI_Debug_824e6c1.img ```

Boot [nixos ARM image](https://nixos.org/download/) from USB
