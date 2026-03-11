# Media *arr Apps - Complete Documentation Index

Welcome! This directory contains a complete Kubernetes deployment for Sonarr, Radarr, and Lidarr (*arr applications) using external NFS storage.

## 🚀 Quick Start

**New to this deployment?** Start here in this order:

1. **[PRE_DEPLOYMENT_CHECKLIST.md](PRE_DEPLOYMENT_CHECKLIST.md)** ← START HERE
   - Complete pre-flight verification checklist
   - Network connectivity tests
   - NFS server configuration validation
   - Deployment commands
   - Post-deployment verification

2. **[COMPLETE_UPDATE_SUMMARY.md](COMPLETE_UPDATE_SUMMARY.md)**
   - Overview of changes made
   - Architecture summary
   - What's different from previous configuration

3. **[ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md)**
   - Visual diagrams of the storage layout
   - PV/PVC binding relationships
   - Pod to storage mapping
   - Network path visualization

## 📚 Documentation Files

### Overview & Setup
- **[README.md](README.md)** - General overview and feature list
- **[NFS_SETUP_GUIDE.md](NFS_SETUP_GUIDE.md)** - Detailed NFS server configuration
- **[PVC_UPDATE_SUMMARY.md](PVC_UPDATE_SUMMARY.md)** - What changed in PVC configuration

### Deployment Files
- **[base/](base/)** - Kubernetes manifests
  - `namespace.yaml` - Creates `media` namespace
  - `pvc.yaml` - 5 PersistentVolumes + 8 PersistentVolumeClaims
  - `sonarr-*` - Sonarr deployment, service, configmap
  - `radarr-*` - Radarr deployment, service, configmap
  - `lidarr-*` - Lidarr deployment, service, configmap
  - `kustomization.yaml` - Base kustomization

- **[overlays/prod/](overlays/prod/)** - Production overlay
  - `kustomization.yaml` - Production configuration
  - `*-replicas.yaml` - Production pod replicas

### Helper Scripts
- **[setup-nfs-dirs.sh](setup-nfs-dirs.sh)** - Create NFS directories on Linux
- **[setup-nfs-dirs.ps1](setup-nfs-dirs.ps1)** - Create NFS directories on Windows

### This File
- **[INDEX.md](INDEX.md)** - This file! Documentation index and quick reference

## 🏗️ Architecture Overview

```
External NFS Server (10.11.11.46:/srv/vault)
    ├── config/
    │   ├── sonarr/     ← Sonarr app configuration
    │   ├── radarr/     ← Radarr app configuration
    │   └── lidarr/     ← Lidarr app configuration
    ├── downloads/      ← Download staging
    ├── movies/         ← TV shows and movies
    └── music/          ← Music library
           ▲
           │ NFS mounts
           │
Kubernetes Cluster (media namespace)
    ├── Sonarr  Pod  (watches TV shows)
    ├── Radarr  Pod  (watches movies)
    └── Lidarr  Pod  (watches music)
```

**Storage Summary:**
- 5 PersistentVolumes (all pointing to external NFS server)
- 8 PersistentVolumeClaims (sonarr/radarr/lidarr configs + media directories)
- Total capacity: ~2.1 TB

## 📋 Pre-Deployment Checklist

Before deploying, ensure:

- [ ] NFS directories created on 10.11.11.46:/srv/vault
- [ ] NFS server exports configured
- [ ] Cluster nodes can reach NFS server (port 2049)
- [ ] Read `PRE_DEPLOYMENT_CHECKLIST.md`
- [ ] Run setup script: `bash setup-nfs-dirs.sh`

## 🎯 Common Tasks

### View What's Being Deployed
```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod --dry-run=client -o yaml
```

### Deploy
```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

### Verify Deployment
```bash
kubectl get pv,pvc,pods -n media
```

### Access Application Web UI
```bash
# Sonarr (8989)
kubectl port-forward -n media svc/sonarr 8989:80

# Radarr (7878)
kubectl port-forward -n media svc/radarr 7878:80

# Lidarr (8686)
kubectl port-forward -n media svc/lidarr 8686:80
```

### Check NFS Mounts in Pod
```bash
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv
```

### View Application Logs
```bash
kubectl logs -n media deployment/sonarr
kubectl logs -n media deployment/radarr
kubectl logs -n media deployment/lidarr
```

### Verify Permissions
```bash
kubectl exec -it -n media deployment/sonarr -- ls -la /config
kubectl exec -it -n media deployment/sonarr -- id
```

## 🔍 Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| PVCs stuck "Pending" | See [PRE_DEPLOYMENT_CHECKLIST.md](PRE_DEPLOYMENT_CHECKLIST.md) → Troubleshooting |
| Can't mount NFS | Check [NFS_SETUP_GUIDE.md](NFS_SETUP_GUIDE.md) → Troubleshooting |
| Permission denied | Verify ownership: `ls -la /srv/vault` on NFS server |
| Connection refused | Test: `showmount -e 10.11.11.46` from cluster node |
| No PVC bound to PV | Check PV/PVC names match in [base/pvc.yaml](base/pvc.yaml) |

## 🔒 Storage Details

### Persistent Volumes

| Name | Capacity | NFS Path | Apps |
|------|----------|----------|------|
| media-config-nfs-pv | 100Gi | `/srv/vault/config` | All 3 apps |
| media-downloads-nfs-pv | 500Gi | `/srv/vault/downloads` | All 3 apps |
| media-tv-nfs-pv | 1000Gi | `/srv/vault/movies` | Sonarr |
| media-movies-nfs-pv | 1000Gi | `/srv/vault/movies` | Radarr |
| media-music-nfs-pv | 500Gi | `/srv/vault/music` | Lidarr |

### Persistent Volume Claims

**Config PVCs** (10Gi each, bound to media-config-nfs-pv):
- `sonarr-config`
- `radarr-config`
- `lidarr-config`

**Media PVCs** (each has dedicated PV):
- `media-downloads` (500Gi)
- `media-tv` (1000Gi)
- `media-movies` (1000Gi)
- `media-music` (500Gi)

## 📊 Storage Allocation

```
Configuration Storage (shared):
  sonarr  10Gi
  radarr  10Gi
  lidarr  10Gi
  ──────────────
  Total:  30Gi used of 100Gi available

Media Storage:
  downloads  500Gi
  movies     1000Gi (shared: sonarr TV + radarr movies)
  music      500Gi
  ──────────────
  Total:     2000Gi
```

## 🛠️ Customization

### Change NFS Server IP
Edit `base/pvc.yaml` - Replace all `10.11.11.46` instances

### Change Storage Capacity
Edit `base/pvc.yaml` - Modify `capacity.storage` and `resources.requests.storage`

### Change NFS Paths
Edit `base/pvc.yaml` - Modify `nfs.path` for each PV

### Add New *arr Application
1. Create `base/<app>-configmap.yaml`
2. Create `base/<app>-deployment.yaml`
3. Create `base/<app>-service.yaml`
4. Add resources to `base/kustomization.yaml`
5. Add overlay patch to `overlays/prod/<app>-replicas.yaml`
6. Update `overlays/prod/kustomization.yaml`

## 📖 Full Documentation Structure

```
media/
├── INDEX.md (this file)
├── README.md (overview)
├── COMPLETE_UPDATE_SUMMARY.md (what changed)
├── PVC_UPDATE_SUMMARY.md (PVC details)
├── NFS_SETUP_GUIDE.md (NFS configuration)
├── PRE_DEPLOYMENT_CHECKLIST.md (pre-flight checks) ⭐ START HERE
├── ARCHITECTURE_DIAGRAMS.md (visual diagrams)
├── setup-nfs-dirs.sh (Linux setup script)
├── setup-nfs-dirs.ps1 (Windows setup script)
├── base/
│   ├── namespace.yaml
│   ├── pvc.yaml
│   ├── kustomization.yaml
│   ├── sonarr-configmap.yaml
│   ├── sonarr-deployment.yaml
│   ├── sonarr-service.yaml
│   ├── radarr-configmap.yaml
│   ├── radarr-deployment.yaml
│   ├── radarr-service.yaml
│   ├── lidarr-configmap.yaml
│   ├── lidarr-deployment.yaml
│   └── lidarr-service.yaml
└── overlays/prod/
    ├── kustomization.yaml
    ├── sonarr-replicas.yaml
    ├── radarr-replicas.yaml
    └── lidarr-replicas.yaml
```

## 🔗 Related Files

- **ArgoCD Application**: `../../argocd/apps/media-app.yaml`

## 📞 Support Resources

- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Kustomize Documentation**: https://kustomize.io/
- **LinuxServer.io Images**: https://linuxserver.io/
- **Sonarr**: https://sonarr.tv/
- **Radarr**: https://radarr.video/
- **Lidarr**: https://lidarr.audio/

## ✅ Deployment Status

- [x] Kubernetes manifests created
- [x] NFS configuration documented
- [x] Setup scripts provided
- [x] Pre-deployment checklist created
- [x] Architecture diagrams included
- [x] Full documentation written
- [ ] **Ready for deployment!** (pending your NFS setup)

---

## 🚀 Getting Started

### Step 1: Read the Guide
```bash
cat PRE_DEPLOYMENT_CHECKLIST.md
```

### Step 2: Set Up NFS
```bash
# Linux
bash setup-nfs-dirs.sh

# Windows
powershell -ExecutionPolicy Bypass -File setup-nfs-dirs.ps1
```

### Step 3: Deploy
```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

### Step 4: Verify
```bash
kubectl get pv,pvc,pods -n media
```

---

**Last Updated**: March 2026
**Status**: Ready for deployment
**NFS Server**: 10.11.11.46:/srv/vault
**Kubernetes Namespace**: media
**Apps**: Sonarr, Radarr, Lidarr
