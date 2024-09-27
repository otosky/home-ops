apiVersion: v1
clusters:
- cluster:
    server: https://10.67.0.4:6443
    certificate-authority-data: "op://Homelab/kubeconfig/certificate-authority-data"
  name: homelab
contexts:
- context:
    cluster: homelab
    namespace: media
    user: admin
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: admin
  user:
    client-certificate-data: "op://Homelab/kubeconfig/client-certificate-data"
    client-key-data: "op://Homelab/kubeconfig/client-key-data"
