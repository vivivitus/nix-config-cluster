# Deployment

This directory contains the scripts for deploying the physical NixOS hosts and the local VirtualBox test environment.

## Requirements

The following tools are required:

* Nix / NixOS
* `jq`
* `ssh`
* `vagrant`
* VirtualBox

## Windows / WSL2 Setup

This guide explains how to set up the NixOS deployment environment on Windows using WSL2 and VirtualBox.

### 1. Install VirtualBox

Install the latest version of VirtualBox on Windows.

### 2. Install NixOS on WSL2

Download the latest NixOS-WSL image from:
https://github.com/nix-community/NixOS-WSL/releases

Update WSL:

    wsl --update

Install the NixOS WSL distribution:

    wsl --install --from-file [nixos.wsl]

Start NixOS:

    wsl -d NixOS

### 3. Clone the repository

Inside the NixOS WSL environment:

    cd ~

Clone the repository:

    nix shell nixpkgs#git -c git clone https://github.com/vivivitus/nix-config-cluster.git

Enter the repository:

    cd nix-config-cluster



### 4. Deploy the VirtualBox test environment

The repository provides a development shell containing the required tools.

    nix develop

To deploy all three test VMs:

    ./deploy-cluster/deploy.sh deploy vm

You can also deploy an individual VM:

    ./deploy-cluster/deploy.sh deploy n1-vm

## Deploy directly with `deploy-nixos.sh`

`deploy-nixos.sh` can also be used standalone without `deploy.sh`.

It expects:

1. a host defined in the Nix flake
2. an existing bootstrap SSH key
3. a matching `extra-files/<node>` directory
4. the target host address as the second argument

Example:

```text
./deploy-nixos.sh n1 10.0.2.50
```

For a VM:

```text
./deploy-nixos.sh n1-vm 192.168.63.101
```

The script directly invokes `nixos-anywhere` and writes the deployment log to `deploy-log/`.

`deploy.sh` is the higher-level orchestrator. It handles target generation, bootstrap key management, VM preparation, and deployment orchestration.


## Reset deployment state

Remove the bootstrap SSH key and generated deployment targets:

```text
./deploy.sh clean
```

They will be recreated automatically during the next deployment.

## Logs

NixOS deployment logs are stored in:

```text
deploy-log/
```
