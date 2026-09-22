
# Deployment

This directory contains the scripts for deploying the physical NixOS hosts and the local VirtualBox test environment.

## Requirements

The following tools are required:

* NixOS / Nix (native or via WSL2)
* VirtualBox on host (Linux / Windows / macOS)
* `jq`
* `ssh`
* `vagrant`

## Deployment Scripts

The deployment directory contains three scripts. Each script has a specific responsibility, but they can also be used independently.

### deploy.sh

`deploy.sh` is the parent script that calls `deploy-vbox.sh` and `deploy-nixos.sh`. It simplifies deployment by adding another level of abstraction. When necessary, it creates the bootstrap SSH key and generates the deployment targets from the Nix flake.


    deploy.sh
        |
        +-- deploy-vbox.sh
        |       |
        |       +-- Build VirtualBox image
        |       +-- Create Vagrant box
        |       +-- Start VM(s)
        |
        +-- deploy-nixos.sh
                |
                +-- Run nixos-anywhere
                +-- Write deployment log

**Deploy a single host:**

    ./deploy.sh deploy n1-vm

If a host is a physical target or a VM is defined in the flake by the specialArgs attribute `isVirtualMachine`. For a VM target, `deploy.sh` automatically calls `deploy-vbox.sh` first to prepare and start the VM, and then calls `deploy-nixos.sh` to install NixOS.

**Deploy all VirtualBox test machines:**

    ./deploy.sh deploy vm

Running this command does the following:

1. Builds the VirtualBox image.
2. Creates the Vagrant box.
3. Starts all configured VM targets.
4. Deploys NixOS to all VMs in parallel.

**Remove the generated bootstrap key and deployment target file:**

    ./deploy.sh clean

The files will be recreated automatically during the next deployment.

### deploy-vbox.sh

`deploy-vbox.sh` is responsible for preparing the VirtualBox test environment. It builds the NixOS VirtualBox image, converts it into a Vagrant box, installs the box into Vagrant, and starts the requested VM or complete VM stack. It is normally called automatically by `deploy.sh`, but can also be used directly.

**Prepare and start a single VM:**

    ./deploy-vbox.sh n1-vm

The target must be a VirtualBox target defined in the deployment configuration.

The script will:

1. Build the `vbox-vm` NixOS configuration.
2. Inject the bootstrap public SSH key.
3. Extract the generated OVA.
4. Create a Vagrant `.box` file.
5. Replace the existing `nixos-vbox` Vagrant box.
6. Destroy the existing target VM if necessary.
7. Start the requested VM.

**Prepare and start all VMs:**

    ./deploy-vbox.sh vm

This prepares the VirtualBox image once and starts all configured VirtualBox targets. The VMs are started in parallel.

### deploy-nixos.sh

`deploy-nixos.sh` performs the actual NixOS installation. It is a thin wrapper around `nixos-anywhere`. It takes a host from the Nix flake, a target IP address, and the corresponding host-specific `extra-files` directory. Unlike `deploy.sh`, it does not prepare VirtualBox VMs or generate deployment targets.

**Deploy a NixOS on a host:**

    ./deploy-nixos.sh n1-vm 192.168.63.101

The script automatically maps VM hosts to their corresponding node name when looking up `extra-files`.

For example:

    n1     -> extra-files/n1/
    n1-vm  -> extra-files/n1/

#### Deployment logs

Each deployment gets its own log file:

    deploy-log/<host>.log

The complete `nixos-anywhere` output is redirected to the corresponding log file.

## Windows / WSL2 Setup

This guide explains how to set up the NixOS deployment environment on Windows using WSL2 and VirtualBox.

### Requirements

Install the [latest version of VirtualBox](https://www.virtualbox.org/wiki/Downloads) on Windows.

Download the [NixOS-WSL image](https://github.com/nix-community/NixOS-WSL/releases) and install it with:

    wsl --install --from-file [nixos.wsl]

Start the installed WSL image with:

    wsl -d NixOS

### Prepare the environment

Inside the NixOS WSL environment:

    cd ~

Clone the repository:

    nix shell nixpkgs#git -c git clone https://github.com/vivivitus/nix-config-cluster.git

Enter the repository:

    cd nix-config-cluster


### Deploy the VirtualBox test environment

Run the development shell containing the required tools:

    nix develop

Add your host keys to extra-files (see [Host key provisioning](./extra-files/README.md))

    cp [path to host key directories] ./deploy/cluster/extra-files

Spin up all three test VMs:

    ./deploy-cluster/deploy.sh deploy vm
