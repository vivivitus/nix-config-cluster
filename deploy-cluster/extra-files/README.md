# Host key provisioning

This directory is intended to contain SSH host keys required for deploying the cluster nodes. The SSH host keys are stored per host and deployed to the corresponding target machine during the rollout with nixos-anywhere.

Each node is assigned a key that is used for **SSH authentication** and for **decrypting SOPS secrets** (by converting it into an age key within the system).

## Directory Structure

The directory structure matches the one found on the deployed hosts. Instead of /etc/, /persist/etc/ is used here because the configuration uses [impermanence](https://github.com/nix-community/impermanence).

```text
deploy-cluster/extra-files/
├── n1
│   └── persist
│       └── etc
│           └── ssh
│               ├── ssh_host_ed25519_key
│               └── ssh_host_ed25519_key.pub
├── n2
│   └── persist
│       └── etc
│           └── ssh
│               ├── ssh_host_ed25519_key
│               └── ssh_host_ed25519_key.pub
├── n3
│   └── persist
│       └── etc
│           └── ssh
│               ├── ssh_host_ed25519_key
│               └── ssh_host_ed25519_key.pub
└── README.md
```
