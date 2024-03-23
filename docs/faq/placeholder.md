# FAQ

## General

### How do I force reconcile `flux` from main?

execute

```sh
flux reconcile source git home-ops-kubernetes
```

## Longhorn

### How do I restore volumes from Longhorn backups?

1. Scale any deployments or statefulsets connected to volume to 0
2. Delete the volume in Longhorn
3. In the "Backup" tab, find the PVC associated with the workload you want to restore
4. Select the checkbox for that PVC and hit the "Restore Latest Backup" button
5. Scale the deployments or statefulsets connected to volume back to previous count.

### How do I set up new disks in Longhorn?

!!! note
    You will need to set up the disk to automount on the host by adding an entry to /etc/fstab.
    For k3s, I've settled on a path convention of `/var/lib/longhorn-int-<ssd|nvme><number>/` where number is a count starting at 1.

1. Under the "Node" tab, find the kubernetes node associated with the disks you'd like to add.
2. Select it and click "Edit Node"
3. Click "Add Disk" and populate the following:
  1. Add a tag; either `ssd` or `nvme`
  2. Give the disk a name of the form `internal-<ssd|nvme>-<number>`
  3. Set the mount path of the disk from the prerequisite step.
  4. Set "Scheduling" to "Enable"
