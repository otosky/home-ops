<div align="center">

### Home Operations :sailboat:

_Managed with Flux, Renovate, and GitHub Actions_ :robot:

</div>

---

## 📖 Overview

This is a mono repository for my home infrastructure and Kubernetes cluster implementing Infrastructure as Code (IaC) and GitOps practices using tools like [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

---

## ⛵ Kubernetes

My Kubernetes cluster is built upon bare-metal nodes running Talos, with Longhorn providing hyper-converged block storage.
A separate TrueNAS system also exists externally for NFS storage - mostly for media and backups.

### Core Components

- **[flux](https://github.com/fluxcd/flux2)**: Manages the cluster state using GitOps
- **[longhorn](https://longhorn.io/)**: Provides distributed block storage for stateful applications
- **[renovate](https://github.com/renovatebot/renovate)**: Keeps application dependencies up-to-date

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches this Git repository and makes the appropriate changes to the cluster based on the YAML manifests in the [kubernetes](./kubernetes/) directory. 

[Renovate](https://github.com/renovatebot/renovate) also watches this Git repository and creates pull requests when it finds updates to Docker images, Helm charts, and other dependencies.

### Directories

This Git repository contains the following directories under [kubernetes](./kubernetes/).

```sh
📁 bootstrap       # Initial installation components
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 apps          # Apps deployed into cluster grouped by namespace
└─📁 flux          # Main Flux configuration of repository
```

---

## 🔧 Hardware

All hardware was cobbled together second-hand from Craigslist or eBay.

| Device                                    | Count | CPU      | RAM       | OS Disk Size            | Data Disk Size                                | NIC                     | Operating System | Purpose                  |   |   |
|-------------------------------------------|-------|----------|-----------|-------------------------|-----------------------------------------------|-------------------------|------------------|--------------------------|---|---|
| Lenovo ThinkCentre M720q                  | 2     | i3-8100T | 32GB      | 500GB NVMe              | -                                             | -                       | Talos            | Kubernetes Control Plane |   |   |
| Lenovo ThinkCentre M920q                  | 1     | i5-8500T | 32GB      | 500GB NVMe              | -                                             | -                       | Talos            | Kubernetes Control Plane |   |   |
| Dell OptiPlex 3070 SFF (9th-gen Intel i5) | 3     | i5 9500  | 64GB      | 250GB SSD               | 1x 1TB SSD; 1x 1TB NVMe                       | Mellanox ConnectX-3 10G | Talos            | Kubernetes Agent         |   |   |
| Custom NAS (i3-8100; 128GB ECC RAM)       | 1     | i3-8100  | 128GB ECC | Mellanox ConnectX-3 10G | TrueNAS                                       | NAS                     |                  |                          |   |   |
| Lenovo ThinkCentre M720q                  | 1     | -        | -         | -                       | [VyOS](https://github.com/otosky/vyos-config) | Router                  |                  |                          |   |   |
| Brocade ICX6450                           | 1     | -        | -         | -                       | -                                             | Switch                  |                  |                          |   |   |
| TP-Link EAP650                            | 1     | -        | -         | -                       | -                                             | WiFi AP                 |                  |                          |   |   |
| Unifi Flex-Mini                           | 2     | -        | -         | -                       | -                                             | Switch (per room)       |                  |                          |   |   |
| Raspberry Pi 4B w/ HiFiBerry DAC2 Pro     | 1     | -        | -         | -                       | -                                             | Volumio                 |                  |                          |   |   |

---

## 🤝 Gratitude and Thanks

Standing on the shoulders of giants, this cluster configuration is heavily inspired by the excellent work of the [k8s-at-home](https://k8s-at-home.com/) community and more specifically:

- [onedr0p/home-ops](https://github.com/onedr0p/home-ops)
- [bjw-s/home-ops](https://github.com/bjw-s/home-ops)
- [flux-cluster-template](https://github.com/onedr0p/flux-cluster-template)

Be sure to check out the [k8s-at-home Discord](https://discord.gg/k8s-at-home)!


