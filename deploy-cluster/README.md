# Deployment

This directory contains the scripts for deploying the physical NixOS hosts and the local VirtualBox test environment.

## Requirements

The following tools are required:

* Nix / NixOS
* `jq`
* `ssh`
* `vagrant`
* VirtualBox

## List deployment targets

Deployment targets are generated directly from the Nix flake:

```text
./deploy.sh targets
```

This creates `.deploy-targets.json`.

## Deploy physical hosts

Deploy a single host:

```text
./deploy.sh deploy n1
```

The same applies to `n2` and `n3`.

## Deploy a single VM

A single VM is automatically prepared and then deployed with NixOS:

```text
./deploy.sh deploy n1-vm
```

The same applies to `n2-vm` and `n3-vm`.

## Deploy the complete VM stack

All VMs defined in `deployTargets` are started and then deployed in parallel:

```text
./deploy.sh deploy vm
```

## Prepare VMs only

`deploy-vbox.sh` can also be used directly.

Prepare and start a single VM:

```text
./deploy-vbox.sh n1-vm
```

Prepare and start all VMs:

```text
./deploy-vbox.sh vm
```

The script builds the VirtualBox image, creates the Vagrant box, and starts the requested VMs.

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

For example:

```text
deploy-log/n1.log
deploy-log/n1-vm.log
deploy-log/n2-vm.log
deploy-log/n3-vm.log
```
