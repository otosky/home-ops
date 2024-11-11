# Bootstrap

## Talos

### Generate Config && apply

### Bootstrap etcd

todo: add talosctl command for bootstrapping single control-plane node

### Add Core Integrations

todo: add helmfile command



## Flux

### Install Flux

```sh
kubectl apply --server-side --kustomize ./kubernetes/bootstrap/flux
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to being encrypted with sops_

```sh
sops --decrypt kubernetes/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/github-deploy-key.sops.yaml | kubectl apply -f -
```

### Kick off Flux applying this repository

```sh
kubectl apply --server-side --kustomize ./kubernetes/flux/config
```
