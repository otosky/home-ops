# FluxCD Repo 4 The Homelab

Inspired by [flux-cluster-template](https://github.com/onedr0p/flux-cluster-template)

## Services

- [Home-Assistant](http://home-assistant.home.arpa)
- SMB share for music that is mounted to [Volumio](http://volumio.home.arpa)
- [Rancher](https://rancher.home.arpa)
- [Longhorn](http://longhorn.home.arpa)

## Dev Setup

### Install:

kubectl:
```bash
asdf plugin add kubectl
asdf plugin install kubectl 1.23.5

# Install `krew` https://krew.sigs.k8s.io/docs/user-guide/setup/install/

# Useful add-ons
kubectl krew install ctx
kubectl krew install ns
```

Helm - you won't really even need this, but the CLI is useful for searching chart repos:
```sh
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

Flux CLI:
```sh
curl -s https://fluxcd.io/install.sh | sudo bash
```

## Cluster Setup 

Node initilization is now handled by using this [Ansible Repo](https://github.com/otosky/ansible-home).

## Init Cluster with Flux
```bash
# export GITHUB_TOKEN=<access_token_with_repo_scope>

flux bootstrap github \                                                                                              ─╯
  --owner=otosky \
  --repository=kubernetes \
  --path=clusters/homelab \
  --personal
```

I'm not entirely sure how to recreate the cluster from this repo if I want to tear it down
and start fresh...

