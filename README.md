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

Installation on Windows with VirtualBox and WSL2:

install VirtualBox
download latest wsl image: (e.g. https://github.com/nix-community/NixOS-WSL/releases/download/2605.7.2/nixos.wsl)
wsl -update
wsl --install --from-file [nixos.wsl]
(optional) passwd
(optional) wsl -s NixOS
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
change into home or whatever folder you want: cd ~
nix shell nixpkgs#git -c git clone https://github.com/vivivitus/nix-config-cluster.git
./nix-config-cluster/deploy-cluster/deploy.sh vbox extra-files/


virtualbox
wsl