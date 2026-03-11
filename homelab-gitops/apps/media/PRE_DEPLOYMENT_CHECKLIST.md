# Pre-Deployment Checklist

Use this checklist before deploying the media *arr apps to Kubernetes.

## NFS Server Configuration

### 1. Directory Creation
- [ ] Created `/srv/vault/config/sonarr/` on NFS server (10.11.11.46)
- [ ] Created `/srv/vault/config/radarr/` on NFS server
- [ ] Created `/srv/vault/config/lidarr/` on NFS server
- [ ] Created `/srv/vault/downloads/` on NFS server
- [ ] Created `/srv/vault/movies/` on NFS server
- [ ] Created `/srv/vault/music/` on NFS server

**Helper Scripts:**
- Linux: `setup-nfs-dirs.sh`
- Windows: `setup-nfs-dirs.ps1`

### 2. NFS Server Configuration

#### For Linux NFS:
- [ ] Updated `/etc/exports` with: `/srv/vault *(rw,sync,no_subtree_check,no_root_squash)`
- [ ] Reloaded NFS daemon: `sudo systemctl restart nfs-kernel-server`
- [ ] Verified exports: `exportfs -v` (shows `/srv/vault` exported)

#### For Windows NFS:
- [ ] Installed NFS Server role on Windows
- [ ] Configured NFS share properties for `/srv/vault`
- [ ] Enabled NFS sharing with appropriate permissions
- [ ] Started NFS service

### 3. Permissions
- [ ] Verified directory permissions allow read/write access
- [ ] If using specific UID/GID (1000:1000), verified ownership is set correctly
- [ ] Tested write access: `touch /srv/vault/test.txt` then `rm /srv/vault/test.txt`

## Kubernetes Cluster Preparation

### 1. Network Connectivity
- [ ] NFS server (10.11.11.46) is reachable from all Kubernetes nodes
- [ ] Tested from a cluster node: `showmount -e 10.11.11.46`
- [ ] Firewall rules allow NFS traffic (UDP 111, TCP 2049) from cluster nodes to NFS server
- [ ] DNS/hostname resolution works (if using hostname instead of IP)

### 2. NFS Client Tools
- [ ] All Kubernetes nodes have `nfs-utils` (Linux) or NFS client installed
- [ ] Verified with: `showmount --version` or similar on cluster nodes

### 3. Kubernetes Namespace
- [ ] Verified `media` namespace will be created by Kustomize deployment
- [ ] Or pre-created: `kubectl create namespace media`

## Configuration Review

### 1. PVC Configuration
- [ ] Reviewed `pvc.yaml` - all PVs point to correct NFS paths
- [ ] Verified all NFS server IPs are `10.11.11.46`
- [ ] Confirmed storage capacities match your environment:
  - [ ] Config PVs: 100Gi total (three 10Gi PVCs)
  - [ ] Downloads PV: 500Gi
  - [ ] TV PV: 1000Gi
  - [ ] Movies PV: 1000Gi
  - [ ] Music PV: 500Gi

### 2. Deployment Configuration
- [ ] Reviewed `sonarr-deployment.yaml` - volume mounts look correct
- [ ] Reviewed `radarr-deployment.yaml` - volume mounts look correct
- [ ] Reviewed `lidarr-deployment.yaml` - volume mounts look correct
- [ ] Verified all three use `accessModes: ReadWriteMany`
- [ ] Confirmed PUID/PGID in ConfigMaps match your environment (currently 1000:1000)

### 3. Kustomization
- [ ] Verified `base/kustomization.yaml` includes all resources
- [ ] Verified `overlays/prod/kustomization.yaml` patches are correct

## Deployment Steps

### Pre-Flight Checks
```bash
# Validate YAML syntax
kubectl apply -k homelab-gitops/apps/media/overlays/prod --dry-run=client

# Check resource definitions
kubectl apply -k homelab-gitops/apps/media/overlays/prod --dry-run=client -o json | jq '.items | length'
```

### Deploy
```bash
# Deploy to cluster
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

### Post-Deployment Verification

```bash
# Check namespace creation
kubectl get namespace media

# Check all resources created
kubectl get all -n media

# Check PersistentVolumes
kubectl get pv | grep media

# Check PersistentVolumeClaims
kubectl get pvc -n media

# Check deployment status
kubectl get deployments -n media
kubectl get pods -n media

# Check if PVCs are bound
kubectl describe pvc -n media
```

### Verify NFS Mounts

```bash
# Check Sonarr pod can see mounts
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv

# Check Sonarr config directory
kubectl exec -it -n media deployment/sonarr -- ls -la /config

# Check downloads directory
kubectl exec -it -n media deployment/sonarr -- ls -la /downloads

# Check TV directory
kubectl exec -it -n media deployment/sonarr -- ls -la /tv
```

## Troubleshooting

### If PVCs stay "Pending"
```bash
# Check PV/PVC binding
kubectl get pv,pvc -n media -o wide

# Check events for errors
kubectl describe pvc sonarr-config -n media

# Verify NFS server is accessible
kubectl debug node/<node-name> -it --image=ubuntu
# Then from the debug pod:
showmount -e 10.11.11.46
mount -t nfs 10.11.11.46:/srv/vault /mnt/test
```

### If pods can't mount NFS
```bash
# Check pod events
kubectl describe pod -n media <pod-name>

# Check kubelet logs on node
kubectl logs -n kube-system -l component=kubelet

# Manually test from node:
sudo mount -t nfs 10.11.11.46:/srv/vault /mnt/test
```

### If permissions denied
```bash
# Check directory permissions on NFS server
ls -la /srv/vault/

# Check PUID/PGID in pod
kubectl exec -it -n media deployment/sonarr -- id

# Verify ownership matches
# On NFS server: chown 1000:1000 /srv/vault -R
```

## Post-Deployment Tasks

- [ ] Access Sonarr web UI and complete initial setup
- [ ] Access Radarr web UI and complete initial setup
- [ ] Access Lidarr web UI and complete initial setup
- [ ] Configure indexers/download clients in each app
- [ ] Test download workflow end-to-end
- [ ] Verify files are being written to NFS correctly
- [ ] Set up backups for configuration directories
- [ ] Configure ArgoCD auto-sync if using GitOps

## Documentation

- [ ] Read `NFS_SETUP_GUIDE.md` for detailed NFS information
- [ ] Read `PVC_UPDATE_SUMMARY.md` for architecture overview
- [ ] Read `README.md` for general deployment information

---

**Estimated time to complete:** 30-60 minutes (depending on NFS server setup)

**Common issues:** NFS connectivity, permissions, firewall rules

**Support:** Check logs with `kubectl logs -n media deployment/<app-name>`
