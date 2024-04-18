scale-nfs-related COUNT:
  #!/bin/bash
  kubectl get deploy,statefulset --all-namespaces -o json |
  jq -r '[.items[] | select(.spec.template.spec.volumes[]?.persistentVolumeClaim.claimName == "media") | "\(.kind) \(.metadata.name) \(.metadata.namespace)"] | .[]' |
  xargs -n 3 |
  parallel -j 1 --verbose --colsep ' ' 'kubectl scale {1}/{2} -n {3} --replicas={{COUNT}}'

scale-nfs-down: (scale-nfs-related "0")
scale-nfs-up: (scale-nfs-related "1")

mkdocs:
  poetry run mkdocs serve
