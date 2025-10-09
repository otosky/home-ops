# Home Operations

A fluxCD deployment repo for services I run in my homelab.

### Inspiration
This is heavily inspired by the wonderful work done by the [k8s-at-home](https://k8s-at-home.com/) community.
Peep their [discord](https://discord.gg/k8s-at-home)!

Standing on the shoulder of giants:
  - [onedr0p/home-ops](https://github.com/onedr0p/home-ops)
  - [bjw-s/home-ops](https://github.com/bjw-s/home-ops)
  - [flux-cluster-template](https://github.com/onedr0p/flux-cluster-template)

## Overview

### :computer: Hardware

If I didn't get it on Craigslist, it came from eBay.

|                  Device                   | Count | OS Disk Size |     Data Disk Size      |           NIC           |               Operating System                |         Purpose          |
|:-----------------------------------------:|:-----:|:------------:|:-----------------------:|:-----------------------:|:---------------------------------------------:|:------------------------:|
|         Lenovo Thinkcentre m720q          |   2   |  500GB NVME  |                         |                         |                    Fedora                     | Kubernetes Control Plane |
|         Lenovo Thinkcentre m920q          |   1   |  500GB NVME  |                         |                         |                    Fedora                     | Kubernetes Control Plane |
| Dell Optiplex 3070 SFF (9th-gen Intel i5) |   3   |  250GB SSD   | 1x 1TB SSD; 1x 1TB NVME | Mellanox ConnectX-3 10G |                    Fedora                     |     Kubernetes Agent     |
|         Custom NAS (Fractal 304)          |   1   |              |                         | Mellanox ConnectX-3 10G |                    Unraid                     |           NAS            |
|         Lenovo Thinkcentre m720q          |   1   |              |                         |                         | [VyOS](https://github.com/otosky/vyos-config) |          Router          |
|              Brocade ICX6450              |   1   |              |                         |                         |                                               |          Switch          |
|              TP-Link EAP650               |   1   |              |                         |                         |                                               |         Wifi AP          |
|              Unifi Flex-Mini              |   2   |              |                         |                         |                                               |    Switch (per room)     |
|       RPI 4B w/ Hifiberry DAC2 Pro        |   1   |              |                         |                         |                                               |         Volumio          |

### :anchor: Kubernetes 

#### Installation
A private repo with my ansible playbooks provision [k3s](https://k3s.io/) atop baremetal Fedora 37-Server installs. 

Someday I'll switch over to the [flux-cluster-template](https://github.com/onedr0p/flux-cluster-template) - 
right now what I use is something of a messy bastardization of the [techno-tim/k3s-ansible](https://github.com/techno-tim/k3s-ansible)
playbooks.

#### Storage

The cluster is mostly hyper-converged; block-storage is provisioned through [Longhorn](https://longhorn.io/)
on dedicated SSD and NVME drives per worker node. A separate NAS runs [Unraid](https://unraid.net/) for NFS,
but that is solely for media storage.

#### Layout
This Git repository contains the following directories under [kubernetes](./kubernetes/).

```sh
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 bootstrap     # Flux installation
├─📁 flux          # Main Flux configuration of repository
└─📁 apps          # Apps deployed into my cluster grouped by namespace
```

[Flux](https://github.com/fluxcd/flux2) is continually syncing the state of this repository to the cluster 
and applying any changes found in the [kustomizations](https://fluxcd.io/flux/components/kustomize/kustomization/) 
within.

No `kubectl apply` or `helm install|upgrade` for me. The flux controllers on the cluster
do all the work. :muscle:

