Install [edk2-uefi firmware](https://github.com/edk2-porting/edk2-rk3588)
-
- Enter Maskrom mode by pressing **RST** shortly while **MASK** is pressed.
- Upload MiniLoader
  - ``` rkdeveloptool db MiniLoaderAll.bin ```
- Select EMMC
  - ``` rkdeveloptool cs 1 ```
- Flash edk2 image
  - ``` rkdeveloptool wl 0 <image> ```

Prepare for installation
-
- Boot [nixos ARM image](https://nixos.org/download/) from USB
- Change keyboard layout
  -  ``` loadkeys sg ```
- Set nixos user password
  -  ``` passwd ```
  -  ``` sudo su ```
- Create partitions
  - ``` fdisk /dev/mmcblk0 ```
  - ``` n ```, default, default, ``` +500M ```
  - ``` t ```, ``` 1 ```
  - ``` n ```, default, default, default
  - ``` w ```
- Format disks
  -  ``` mkfs.fat -F 32 -n BOOT /dev/mmcblk0p2 ```
  -  ``` mkfs.btrfs -L root /dev/mmcblk0p3 ```
- Create and mount subvolumes
  - ``` mkdir -p /mnt ```
  - ``` mount /dev/mmcblk0p3 /mnt ```
  - ``` btrfs subvolume create /mnt/root ```
  - ``` btrfs subvolume create /mnt/home ```
  - ``` btrfs subvolume create /mnt/nix ```
  - ``` umount /mnt ```
  - ``` mount -o compress=zstd,subvol=root /dev/mmcblk0p3 /mnt ```
  - ``` mkdir /mnt/{boot,home,nix} ```
  - ``` mount -o compress=zstd,subvol=home /dev/mmcblk0p3 /mnt/home ```
  - ``` mount -o compress=zstd,noatime,subvol=nix /dev/mmcblk0p3 /mnt/nix ```
  - ``` mount /dev/mmcblk0p2 /mnt/boot ```

Installation
-
- Apply configuration from git
  - ``` sudo nixos-install --flake github:vivivitus/nix-config-cluster#<machine> ```

After reboot (workaround)
-
- SSH to machine
- create or copy user age key for sops
  - ``` scp ... ```
  - ``` age-keygen -o ~/.config/sops/age/keys.txt ```
  - ``` age-keygen -y ~/.config/sops/age/keys.txt ```
- clone repo and add user key to sops.yaml ``` git clone https://github.com/vivivitus/nix-config-cluster.git ```
- add machine key to sops.yaml ``` nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age' ```
- update secrets ``` sops updatekeys secrets/secrets.yaml ```
