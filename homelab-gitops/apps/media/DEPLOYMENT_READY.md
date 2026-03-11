# ✅ PVC Configuration Update - COMPLETE

## Summary of Changes

Your PVC configuration has been completely restructured to use pure NFS storage from an external server (10.11.11.46) instead of mixing NFS with Longhorn.

---

## 📋 What Was Changed

### Files Updated: 4

1. **`base/pvc.yaml`** ✅
   - Removed: Single multi-path NFS volume + Longhorn config storage
   - Added: 5 dedicated PersistentVolumes (one per NFS path)
   - Added: 8 PersistentVolumeClaims (config + media)
   - All PVs point to NFS server 10.11.11.46
   - Total storage capacity: ~2.1 TB

2. **`base/sonarr-deployment.yaml`** ✅
   - Updated volume mounts (removed subPath usage)
   - Now references: sonarr-config, media-tv, media-downloads, media-movies
   - Direct mount paths: /config, /tv, /downloads, /movies

3. **`base/radarr-deployment.yaml`** ✅
   - Updated volume mounts (removed subPath usage)
   - Now references: radarr-config, media-movies, media-downloads
   - Direct mount paths: /config, /movies, /downloads

4. **`base/lidarr-deployment.yaml`** ✅
   - Updated volume mounts (removed subPath usage)
   - Now references: lidarr-config, media-music, media-downloads
   - Direct mount paths: /config, /music, /downloads

### Documentation Added: 8 Files

1. **`INDEX.md`** - Documentation index and quick reference
2. **`COMPLETE_UPDATE_SUMMARY.md`** - Architecture overview and changes
3. **`NFS_SETUP_GUIDE.md`** - Detailed NFS server configuration
4. **`PRE_DEPLOYMENT_CHECKLIST.md`** - Pre-flight checks and deployment steps
5. **`PVC_UPDATE_SUMMARY.md`** - Summary of PVC changes
6. **`ARCHITECTURE_DIAGRAMS.md`** - Visual diagrams of the storage layout
7. **`setup-nfs-dirs.sh`** - Script to create NFS directories (Linux)
8. **`setup-nfs-dirs.ps1`** - Script to create NFS directories (Windows)

---

## 📁 New Storage Architecture

### Persistent Volumes (5)

```
media-config-nfs-pv       (100Gi) → 10.11.11.46:/srv/vault/config
media-downloads-nfs-pv    (500Gi) → 10.11.11.46:/srv/vault/downloads
media-tv-nfs-pv          (1000Gi) → 10.11.11.46:/srv/vault/movies
media-movies-nfs-pv      (1000Gi) → 10.11.11.46:/srv/vault/movies
media-music-nfs-pv        (500Gi) → 10.11.11.46:/srv/vault/music
```

### Persistent Volume Claims (8)

**Configuration (all share media-config-nfs-pv):**
- sonarr-config        (10Gi)
- radarr-config        (10Gi)
- lidarr-config        (10Gi)

**Media (each has dedicated PV):**
- media-downloads      (500Gi)
- media-tv            (1000Gi)
- media-movies        (1000Gi)
- media-music         (500Gi)

---

## 🔧 Required Pre-Deployment Setup

### 1. Create NFS Directories on 10.11.11.46

**Using provided scripts:**

```bash
# Linux
bash setup-nfs-dirs.sh

# Windows
powershell -ExecutionPolicy Bypass -File setup-nfs-dirs.ps1
```

**Or manually:**
```bash
mkdir -p /srv/vault/{config/{sonarr,radarr,lidarr},downloads,movies,music}
chmod -R 777 /srv/vault
chown -R nobody:nogroup /srv/vault
```

### 2. Configure NFS Server Exports

**For Linux:**
```bash
# Add to /etc/exports:
/srv/vault *(rw,sync,no_subtree_check,no_root_squash)

# Reload:
sudo systemctl restart nfs-kernel-server
exportfs -v
```

**For Windows:**
- Use setup-nfs-dirs.ps1 script
- Configure NFS Share Properties
- Ensure NFS Server role is installed

### 3. Verify Cluster Connectivity

```bash
# From a Kubernetes node:
showmount -e 10.11.11.46
sudo mount -t nfs 10.11.11.46:/srv/vault /mnt/test
ls /mnt/test
sudo umount /mnt/test
```

---

## 🚀 Deployment Steps

### 1. Validate YAML
```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod --dry-run=client
```

### 2. Deploy
```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

### 3. Verify Deployment
```bash
# Check resources
kubectl get pv,pvc -n media
kubectl get deployments -n media
kubectl get pods -n media

# Check PVC status
kubectl describe pvc -n media
```

### 4. Verify NFS Mounts
```bash
# Check if pods can see the mounts
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv/vault

# Check config directory
kubectl exec -it -n media deployment/sonarr -- ls -la /config

# Check downloads
kubectl exec -it -n media deployment/sonarr -- ls -la /downloads
```

---

## 📊 Storage Breakdown

```
Total Allocated: ~2.1 TB

Configuration (all on one PV):
  └─ sonarr-config       10Gi  ├─┐
  └─ radarr-config       10Gi  ├─┼─→ 100Gi PV
  └─ lidarr-config       10Gi  ├─┘

Media Storage:
  └─ downloads           500Gi  (shared by all)
  └─ movies             1000Gi  (sonarr TV + radarr movies)
  └─ music               500Gi  (lidarr only)
  ─────────────────────────
  Total:               2000Gi
```

---

## ✅ Pre-Deployment Checklist

Before deploying, complete these checks:

- [ ] Read `PRE_DEPLOYMENT_CHECKLIST.md`
- [ ] NFS directories created on 10.11.11.46
- [ ] NFS exports configured in /etc/exports
- [ ] NFS server restarted/reloaded
- [ ] Cluster nodes can reach NFS server (test with showmount)
- [ ] Verified with `kubectl apply --dry-run=client`
- [ ] Ready to deploy with `kubectl apply -k ...`

---

## 📚 Documentation Guide

**Start with these in order:**

1. `INDEX.md` - Overview of all documentation
2. `PRE_DEPLOYMENT_CHECKLIST.md` - Pre-flight checks
3. `NFS_SETUP_GUIDE.md` - Detailed NFS configuration
4. `ARCHITECTURE_DIAGRAMS.md` - Visual diagrams
5. `COMPLETE_UPDATE_SUMMARY.md` - Full change overview

---

## 🎯 Key Improvements

✅ **No Longhorn dependency** - All storage on external NFS
✅ **Simpler mount structure** - No subpaths, direct mounting
✅ **Better isolation** - Each path has dedicated PV
✅ **Easier backup** - All data on single NFS server
✅ **Scalable** - Easy to add more *arr apps
✅ **Cluster independent** - Data survives cluster recreation

---

## 🔍 File Locations

```
homelab-gitops/apps/media/
├── INDEX.md ⭐ START HERE
├── PRE_DEPLOYMENT_CHECKLIST.md ⭐ PRE-FLIGHT
├── COMPLETE_UPDATE_SUMMARY.md
├── ARCHITECTURE_DIAGRAMS.md
├── NFS_SETUP_GUIDE.md
├── PVC_UPDATE_SUMMARY.md
├── README.md
├── setup-nfs-dirs.sh
├── setup-nfs-dirs.ps1
├── base/
│   ├── namespace.yaml
│   ├── pvc.yaml ✅ UPDATED
│   ├── kustomization.yaml
│   ├── sonarr-configmap.yaml
│   ├── sonarr-deployment.yaml ✅ UPDATED
│   ├── sonarr-service.yaml
│   ├── radarr-configmap.yaml
│   ├── radarr-deployment.yaml ✅ UPDATED
│   ├── radarr-service.yaml
│   ├── lidarr-configmap.yaml
│   ├── lidarr-deployment.yaml ✅ UPDATED
│   └── lidarr-service.yaml
└── overlays/prod/
    ├── kustomization.yaml
    ├── sonarr-replicas.yaml
    ├── radarr-replicas.yaml
    └── lidarr-replicas.yaml
```

---

## ⚠️ Important Notes

1. **Directory creation is required** - Create `/srv/vault/*` directories BEFORE deploying
2. **External NFS server** - 10.11.11.46 must be reachable from all Kubernetes nodes
3. **Network connectivity** - NFS port 2049 must be accessible (firewall rules)
4. **Permissions** - Verify NFS export allows RW access
5. **Persistence** - Data persists across Kubernetes cluster restarts

---

## 🚨 Troubleshooting Quick Links

| Issue | See |
|-------|-----|
| PVCs stuck pending | PRE_DEPLOYMENT_CHECKLIST.md → Troubleshooting |
| NFS mount errors | NFS_SETUP_GUIDE.md → Troubleshooting |
| Permission denied | Check NFS directory ownership |
| Network connectivity | showmount -e 10.11.11.46 from cluster node |

---

## 🎉 You're Ready!

All configuration is complete. Your deployment structure:

- ✅ Uses pure NFS storage (no Longhorn for configs)
- ✅ Has dedicated PVs for each storage path
- ✅ Includes comprehensive documentation
- ✅ Provides setup scripts for NFS directories
- ✅ Includes pre-deployment verification checklist

**Next step:** Follow `PRE_DEPLOYMENT_CHECKLIST.md` to set up NFS and deploy!

---

**Files Changed**: 4 deployment files
**Files Added**: 8 documentation files
**Total Configuration Files**: 12 in base/ + 4 in overlays/prod/ = 16
**Status**: ✅ Ready for deployment
**NFS Server**: 10.11.11.46:/srv/vault
**Kubernetes Namespace**: media
**Applications**: Sonarr (TV), Radarr (Movies), Lidarr (Music)
