# PVC Configuration - Complete Update Summary

## Overview

Your media *arr apps deployment has been completely restructured to use **pure NFS storage** from an external server (10.11.11.46) instead of mixing NFS with Longhorn.

## What Changed

### ✅ Files Updated

1. **`base/pvc.yaml`** - Complete restructure
   - Replaced single multi-path NFS volume with separate dedicated PVs
   - One PV per NFS path for better isolation and management
   - All PVCs bound to appropriate PVs by name

2. **`base/sonarr-deployment.yaml`** - Updated volume references
   - Removed subPath usage
   - Now references separate PVCs: `sonarr-config`, `media-tv`, `media-downloads`, `media-movies`
   - Direct mount paths: `/config`, `/tv`, `/downloads`, `/movies`

3. **`base/radarr-deployment.yaml`** - Updated volume references
   - Removed subPath usage
   - Now references separate PVCs: `radarr-config`, `media-movies`, `media-downloads`
   - Direct mount paths: `/config`, `/movies`, `/downloads`

4. **`base/lidarr-deployment.yaml`** - Updated volume references
   - Removed subPath usage
   - Now references separate PVCs: `lidarr-config`, `media-music`, `media-downloads`
   - Direct mount paths: `/config`, `/music`, `/downloads`

### ✅ New Documentation Files

1. **`NFS_SETUP_GUIDE.md`** - Complete NFS configuration guide
   - NFS server setup instructions
   - Directory structure requirements
   - Kubernetes verification steps
   - Troubleshooting guide

2. **`PVC_UPDATE_SUMMARY.md`** - Architecture overview
   - Changes made and why
   - New PV/PVC structure
   - Required pre-deployment setup
   - Next steps

3. **`PRE_DEPLOYMENT_CHECKLIST.md`** - Step-by-step verification
   - Pre-flight checks
   - Deployment steps with verification
   - Troubleshooting guide
   - Post-deployment tasks

4. **`setup-nfs-dirs.sh`** - Linux NFS directory setup script
   - Creates required directory structure
   - Sets permissions
   - Displays next steps

5. **`setup-nfs-dirs.ps1`** - Windows NFS directory setup script
   - For Windows Server with NFS role
   - Creates required directory structure
   - Sets NTFS permissions

## New Architecture

### Storage Layout

```
NFS Server: 10.11.11.46
└── /srv/vault/
    ├── config/
    │   ├── sonarr/      ← sonarr-config PVC (10Gi)
    │   ├── radarr/      ← radarr-config PVC (10Gi)
    │   └── lidarr/      ← lidarr-config PVC (10Gi)
    ├── downloads/       ← media-downloads PVC (500Gi)
    ├── movies/          ← media-tv & media-movies PVC (1000Gi)
    └── music/           ← media-music PVC (500Gi)
```

### PersistentVolumes (5 total)

| PV Name | NFS Path | Capacity | Used By |
|---------|----------|----------|---------|
| `media-config-nfs-pv` | `/srv/vault/config` | 100Gi | 3 config PVCs |
| `media-downloads-nfs-pv` | `/srv/vault/downloads` | 500Gi | `media-downloads` |
| `media-tv-nfs-pv` | `/srv/vault/movies` | 1000Gi | `media-tv` |
| `media-movies-nfs-pv` | `/srv/vault/movies` | 1000Gi | `media-movies` |
| `media-music-nfs-pv` | `/srv/vault/music` | 500Gi | `media-music` |

### PersistentVolumeClaims (8 total)

**Config PVCs (all bound to media-config-nfs-pv):**
- `sonarr-config` (10Gi)
- `radarr-config` (10Gi)
- `lidarr-config` (10Gi)

**Media PVCs (each has dedicated PV):**
- `media-downloads` (500Gi) → `/srv/vault/downloads`
- `media-tv` (1000Gi) → `/srv/vault/movies`
- `media-movies` (1000Gi) → `/srv/vault/movies`
- `media-music` (500Gi) → `/srv/vault/music`

### Pod Mounts

**Sonarr Pod**
- `/config` ← `sonarr-config` PVC ← `media-config-nfs-pv` ← `/srv/vault/config` (NFS)
- `/tv` ← `media-tv` PVC ← `media-tv-nfs-pv` ← `/srv/vault/movies` (NFS)
- `/downloads` ← `media-downloads` PVC ← `media-downloads-nfs-pv` ← `/srv/vault/downloads` (NFS)
- `/movies` ← `media-movies` PVC ← `media-movies-nfs-pv` ← `/srv/vault/movies` (NFS)

**Radarr Pod**
- `/config` ← `radarr-config` PVC ← `media-config-nfs-pv` ← `/srv/vault/config` (NFS)
- `/movies` ← `media-movies` PVC ← `media-movies-nfs-pv` ← `/srv/vault/movies` (NFS)
- `/downloads` ← `media-downloads` PVC ← `media-downloads-nfs-pv` ← `/srv/vault/downloads` (NFS)

**Lidarr Pod**
- `/config` ← `lidarr-config` PVC ← `media-config-nfs-pv` ← `/srv/vault/config` (NFS)
- `/music` ← `media-music` PVC ← `media-music-nfs-pv` ← `/srv/vault/music` (NFS)
- `/downloads` ← `media-downloads` PVC ← `media-downloads-nfs-pv` ← `/srv/vault/downloads` (NFS)

## Pre-Deployment Requirements

### 1. Create NFS Directories

You **must** create these directories on your NFS server (10.11.11.46) **before deploying**:

```bash
# Using provided setup script:
bash setup-nfs-dirs.sh

# Or manually:
mkdir -p /srv/vault/{config/{sonarr,radarr,lidarr},downloads,movies,music}
chmod -R 777 /srv/vault
chown -R nobody:nogroup /srv/vault
```

### 2. Configure NFS Server

**For Linux NFS servers:**

Add to `/etc/exports`:
```
/srv/vault *(rw,sync,no_subtree_check,no_root_squash)
```

Then reload:
```bash
sudo systemctl restart nfs-kernel-server
exportfs -v  # Verify
```

**For Windows NFS servers:**
- Use provided `setup-nfs-dirs.ps1` script
- Configure NFS Share Properties
- Ensure NFS Server role is running

### 3. Verify Cluster Connectivity

Test from a Kubernetes node:
```bash
showmount -e 10.11.11.46
sudo mount -t nfs 10.11.11.46:/srv/vault /mnt/test
ls /mnt/test
sudo umount /mnt/test
```

## Deployment

### Deploy to Kubernetes

```bash
# Validate first
kubectl apply -k homelab-gitops/apps/media/overlays/prod --dry-run=client

# Deploy
kubectl apply -k homelab-gitops/apps/media/overlays/prod

# Verify
kubectl get pv,pvc -n media
kubectl get deployments -n media
```

### Verify NFS Mounts

```bash
# Check Sonarr sees the mounts
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv/vault

# List config directory
kubectl exec -it -n media deployment/sonarr -- ls -la /config

# Check downloads
kubectl exec -it -n media deployment/sonarr -- ls -la /downloads
```

## Advantages of This Design

✅ **Pure NFS** - No Longhorn dependency for configs
✅ **Separation of Concerns** - Each path has its own PV
✅ **Easy Backups** - All data on single external NFS server
✅ **Cluster Independent** - Apps survive cluster recreation
✅ **Flexible** - Easy to add more *arr apps
✅ **Better Isolation** - Each app's config separate from others

## Key Differences from Original

| Aspect | Before | After |
|--------|--------|-------|
| Config Storage | Longhorn | NFS |
| Config PVCs | Separate Longhorn per app | Shared NFS with subpaths |
| Media PVCs | Single multi-path NFS PVC | Separate PVC per path |
| Mount Style | subPath: downloads | Direct mount to `/downloads` |
| NFS Paths | `/srv/vault2` (one path) | `/srv/vault/*` (multiple paths) |
| Total PVs | 2 (config + media) | 5 (one per path) |
| Total PVCs | 4 (3 Longhorn + 1 NFS) | 8 (all NFS) |

## Troubleshooting Quick Links

- **NFS not mounting**: See `NFS_SETUP_GUIDE.md` → Troubleshooting section
- **PVC stuck pending**: See `PRE_DEPLOYMENT_CHECKLIST.md` → Troubleshooting
- **Permission denied**: Check NFS directory ownership and Kubernetes PUID/PGID
- **Can't reach NFS server**: Verify network connectivity from cluster nodes

## Next Steps

1. ✅ **Read** `PRE_DEPLOYMENT_CHECKLIST.md` - Complete all pre-flight checks
2. ✅ **Create** NFS directories on 10.11.11.46 using provided scripts
3. ✅ **Configure** NFS server exports (`/etc/exports` or NFS Share Properties)
4. ✅ **Test** NFS connectivity from cluster nodes
5. ✅ **Deploy** using `kubectl apply -k homelab-gitops/apps/media/overlays/prod`
6. ✅ **Verify** with `kubectl get pv,pvc,pods -n media`
7. ✅ **Access** apps via port-forward and configure them

## Files Checklist

- [x] `base/pvc.yaml` - Updated with 5 PVs and 8 PVCs
- [x] `base/sonarr-deployment.yaml` - Updated volume mounts
- [x] `base/radarr-deployment.yaml` - Updated volume mounts
- [x] `base/lidarr-deployment.yaml` - Updated volume mounts
- [x] `NFS_SETUP_GUIDE.md` - Complete NFS guide
- [x] `PVC_UPDATE_SUMMARY.md` - Architecture overview
- [x] `PRE_DEPLOYMENT_CHECKLIST.md` - Verification checklist
- [x] `setup-nfs-dirs.sh` - Linux setup script
- [x] `setup-nfs-dirs.ps1` - Windows setup script

---

**Ready to deploy?** Start with `PRE_DEPLOYMENT_CHECKLIST.md`
