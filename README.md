# NixOS K3s Cluster

A declarative NixOS configuration for deploying a small, reproducible **K3s cluster**.

The project is designed to run on both bare-metal systems and VirtualBox VMs managed with Vagrant. It uses [NixOS Anywhere](https://github.com/nix-community/nixos-anywhere) for provisioning, [Disko](https://github.com/nix-community/disko) for declarative disk configuration, [SOPS-Nix](https://github.com/Mic92/sops-nix) for secret management, and [Impermanence](https://github.com/nix-community/impermanence) to keep the system largely stateless.

## Overview

The flake provides the following NixOS configurations and bootstrap artifacts:

| Output | Platform | Purpose |
|---|---|---|
| `iso` | x86_64 | Bootstrap installation ISO for bare-metal deployment |
| `vbox-vm` | x86_64 | Base VirtualBox image for Vagrant |
| `n1` | aarch64 | Bare-metal cluster node 1 |
| `n2` | aarch64 | Bare-metal cluster node 2 |
| `n3` | aarch64 | Bare-metal cluster node 3 |
| `n1-vm` | x86_64 | Virtual cluster node 1 |
| `n2-vm` | x86_64 | Virtual cluster node 2 |
| `n3-vm` | x86_64 | Virtual cluster node 3 |

The host configurations share the same node modules where possible. Hardware and networking differences are passed into the configuration through `specialArgs`. iso and vbox-vm are both intended solely as initial media that, using a local bootstrap key, allow NixOS Anywhere to deploy the actual configuration.

## Cluster Environments

The flake currently defines two cluster targets, prod and staging which are declared in flake.nix:

```text
clusterConfigs = {
  prod = {
    gitRepository = "git@gitlab.com:kubernarnold/the-cluster.git";
    gitBranch = "main";
    bootstrapRootApp = "root-app-prod.yaml";
  };

  staging = {
    gitRepository = "git@gitlab.com:kubernarnold/the-cluster.git";
    gitBranch = "developing-config";
    bootstrapRootApp = "root-app-staging.yaml";
  };
};
```

Each target specifies the Git repository, branch and Argo CD root application used to configure the Kubernetes cluster. This keeps the NixOS host configuration separate from the Kubernetes application configuration.

## Flake Outputs

The main NixOS configurations are:

| Configuration | Platform | Purpose                        |
| ------------- | -------- | ------------------------------ |
| `iso`         | x86_64   | Minimal NixOS installation ISO |
| `vbox-vm`     | x86_64   | VirtualBox base VM             |
| `n1`          | aarch64  | Bare-metal cluster node 1      |
| `n2`          | aarch64  | Bare-metal cluster node 2      |
| `n3`          | aarch64  | Bare-metal cluster node 3      |
| `n1-vm`       | x86_64   | Virtual cluster node 1         |
| `n2-vm`       | x86_64   | Virtual cluster node 2         |
| `n3-vm`       | x86_64   | Virtual cluster node 3         |

## `specialArgs`

The host configurations share the same reusable modules where possible. Hardware- and environment-specific values are passed into these modules using `specialArgs`. This keeps the modules generic while allowing each node to provide its own configuration without duplicating module logic.

The values passed through `specialArgs` include information such as:

1. global flake values,
2. host-specific configuration,
3. host defaults, and
4. network defaults.

### Available `specialArgs`

| Argument           | Default     | Description                                                                                                                               |
| ------------------ | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `inputs`           | —           | All flake inputs, including `nixpkgs`, `sops-nix`, `disko`, `impermanence`, `home-manager`, and other dependencies.                       |
| `outputs`          | —           | The outputs of the current flake. This allows modules to access other configurations, modules, overlays, or outputs defined by the flake. |
| `hostName`         | —           | Name of the current host configuration, e.g. `n1`, `n2`, `n3`, `n1-vm`, etc.                                                              |
| `clusterConfig`    | —           | Configuration of the selected cluster target. Contains `gitRepository`, `gitBranch`, and `bootstrapRootApp`.                              |
| `isFallback`       | `false`     | Indicates whether the host is using a fallback configuration.                                                                             |
| `isVirtualMachine` | `false`     | Indicates whether the host is a virtual machine. Bare-metal hosts default to `false`; VM hosts override this to `true`.                   |
| `clusterTarget`    | —           | Name of the cluster environment assigned to the host, currently `prod` or `staging`.                                                      |
| `clusterBootstrap` | `false`     | Indicates whether this host is responsible for bootstrapping the K3s cluster. Currently enabled for `n1` and `n1-vm`.                     |
| `ipv4Address`      | —           | Static IPv4 address assigned to the host.                                                                                                 |
| `ipv6Address`      | —           | Static IPv6 address assigned to the host.                                                                                                 |
| `ipv4Gateway`      | `null`      | IPv4 default gateway. Bare-metal hosts override this with their gateway address.                                                          |
| `ipv6Gateway`      | `null`      | IPv6 default gateway. Bare-metal hosts override this with their gateway address.                                                          |
| `ipv4Nameserver`   | `null`      | IPv4 DNS nameserver.                                                                                                                      |
| `ipv6Nameserver`   | `null`      | IPv6 DNS nameserver.                                                                                                                      |
| `interface`        | `enP4p65s0` | Network interface used for the cluster network on bare-metal systems. VM hosts override this with `enp0s8`.                               |
| `dhcpInterface`    | `null`      | Optional network interface used for DHCP. Bare-metal hosts do not define one; VM hosts use `enp0s3`.                                      |
| `allHosts`         | —           | Complete `hostConfigs` attribute set containing the configuration of all cluster nodes.                                                   |

### Example

A bare-metal node such as `n2` only defines the values that are specific to that node:

```nix
n2 = {
  clusterTarget = "staging";
  ipv4Address = "10.0.2.51";
  ipv6Address = "2a02:168:5bab:2::51";
  ipv4Gateway = "10.0.2.1";
  ipv6Gateway = "2a02:168:5bab:2::1";
  ipv4Nameserver = "10.0.2.1";
  ipv6Nameserver = "2a02:168:5bab:2::1";
};
```

## Secrets

Secrets are managed using **SOPS-Nix**. The nodes' persistent SSH host keys are also used as `age` identities. This allows the deployed machines to decrypt secrets without requiring a separate age key to be manually provisioned on every node.

```text
deploy-cluster/extra-files/
├── n1/
├── n2/
└── n3/
```

See the corresponding [`deploy-cluster/extra-files/README.md`](deploy-cluster/extra-files/README.md) for details.

## Impermanence

The system uses **Impermanence** to keep the root filesystem ephemeral. Instead of treating the root filesystem as persistent state, required data is explicitly declared and persisted. This makes rebuilding or reinstalling a node predictable and reproducible while keeping only the necessary state across reboots.

## Provisioning

The cluster can be deployed either to physical bare-metal systems or to VirtualBox virtual machines managed by Vagrant.

Both deployment methods use **NixOS Anywhere** to install the actual NixOS host configuration. The difference is only in how the initial bootstrap environment is provided.

### Bare-Metal Deployment

The bare-metal deployment follows these steps:

1. Build a minimal NixOS installation ISO using [`nix-generators`](https://github.com/nix-community/nixos-generators).

2. Boot the bare-metal system from the generated ISO. The ISO provides the temporary NixOS environment required for the installation.

3. Run NixOS Anywhere against the target machine and select the corresponding host configuration from the flake.

4. NixOS Anywhere uses the configuration provided by the flake together with Disko to partition the disks and install NixOS.

5. Required persistent files, including the node's SSH host keys, are deployed as part of the installation.

6. After the installation is complete, the machine boots into its actual NixOS configuration. The node joins or bootstraps the K3s cluster according to its host configuration.

### VirtualBox / Vagrant Deployment

The virtual-machine deployment follows a similar process, but uses a VirtualBox base image instead of an installation ISO:

1. Build the `vbox-vm` base image that is used by Vagrant to create the virtual machines.

2. Vagrant creates the cluster VMs in VirtualBox from the generated base box.

3. The newly created VMs boot into the base NixOS system.

4. Run NixOS Anywhere against each VM and select the corresponding VM host configuration (`n1-vm`, `n2-vm`, or `n3-vm`).

5. NixOS Anywhere uses Disko and the selected NixOS configuration to install the actual system.

6. Node-specific configuration and persistent files are deployed as part of the installation. (VMs are using the extra-files of the corresponding bare-metal host e.g. `n1-vm` uses `n1`)

7. The VM reboots into its final NixOS configuration and joins or bootstraps the K3s cluster according to its host configuration.

### Deployment Overview

Both deployment methods ultimately follow the same principle:

**Bare Metal**

1. Build NixOS ISO with `nix-generators`
2. Boot machine from ISO
3. Run NixOS Anywhere
4. Install the selected NixOS configuration
5. Boot the installed system
6. Run K3s

**VirtualBox / Vagrant**

1. Build VirtualBox base box
2. Create VMs with Vagrant
3. Boot the VMs
4. Run NixOS Anywhere
5. Install the selected NixOS configuration
6. Boot the installed system
7. Run K3s

The bootstrap environments (`iso` and `vbox-vm`) are only used to get the machines into a state where NixOS Anywhere can perform the actual installation. The final system is always defined by the corresponding NixOS configuration in `flake.nix`.



<!--
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
-->
