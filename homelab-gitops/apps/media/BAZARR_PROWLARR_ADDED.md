# ✅ Bazarr & Prowlarr - Added Successfully

## Summary

Two additional *arr applications have been successfully added to your media deployment:

### 🎬 **Bazarr** - Subtitle Management
- Automatic subtitle downloading for TV shows and movies
- Integrates with OpenSubtitles and other subtitle providers
- Works with Sonarr and Radarr webhooks
- Port: 6767
- Config Storage: 5Gi

### 🔍 **Prowlarr** - Indexer Management  
- Centralized indexer management for all *arr apps
- Single API endpoint for all indexers
- Manages Usenet and Torrent indexers
- Port: 9696
- Config Storage: 5Gi

---

## 📋 Files Created/Updated

### New Deployment Files (6)

**Bazarr**:
- ✅ `base/bazarr-configmap.yaml` - Environment configuration
- ✅ `base/bazarr-deployment.yaml` - Pod specification with volume mounts
- ✅ `base/bazarr-service.yaml` - ClusterIP service
- ✅ `overlays/prod/bazarr-replicas.yaml` - Production replica patch

**Prowlarr**:
- ✅ `base/prowlarr-configmap.yaml` - Environment configuration
- ✅ `base/prowlarr-deployment.yaml` - Pod specification with volume mounts
- ✅ `base/prowlarr-service.yaml` - ClusterIP service
- ✅ `overlays/prod/prowlarr-replicas.yaml` - Production replica patch

### Updated Files (4)

1. **`base/pvc.yaml`** ✅
   - Added `bazarr-config` PVC (5Gi)
   - Added `prowlarr-config` PVC (5Gi)
   - Both share the `media-config-nfs-pv` NFS volume

2. **`base/kustomization.yaml`** ✅
   - Added 6 new resources to the base configuration
   - Now includes all 18 resource files (3 per app × 5 apps + namespace + pvc)

3. **`overlays/prod/kustomization.yaml`** ✅
   - Added 2 new patch resources
   - Now patches 5 deployment replicas

4. **`README.md`** ✅
   - Updated application overview
   - Added Bazarr and Prowlarr to descriptions
   - Updated directory structure
   - Updated service ports list

### Documentation (1)

- ✅ `BAZARR_PROWLARR_SETUP.md` - Comprehensive setup and integration guide

---

## 📊 Updated Configuration

### Total Applications Now: 5

```
media/
├── Sonarr   (TV Shows)       - Port 8989
├── Radarr   (Movies)         - Port 7878
├── Lidarr   (Music)          - Port 8686
├── Bazarr   (Subtitles) ✨   - Port 6767
└── Prowlarr (Indexers) ✨    - Port 9696
```

### Storage Allocation

**Configuration Storage** (Total: 40Gi of 100Gi used):
```
sonarr-config     10Gi
radarr-config     10Gi
lidarr-config     10Gi
bazarr-config      5Gi ✨ NEW
prowlarr-config    5Gi ✨ NEW
──────────────────────
Total Used:       40Gi
Available:        60Gi
```

**Media Storage** (unchanged):
```
downloads          500Gi
movies            1000Gi
tv/music           500Gi
──────────────────────
Total:           2000Gi
```

---

## 🚀 Deployment

### All Apps Ready

Your deployment now includes:
- ✅ 5 Complete application stacks (configmap + deployment + service)
- ✅ Shared NFS configuration storage
- ✅ Shared NFS media storage
- ✅ Production overlay patches
- ✅ Full kustomization setup

### Deploy with Single Command

```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

### Verify Deployment

```bash
# Check all 5 deployments are running
kubectl get deployments -n media

# Should output:
# NAME       READY   UP-TO-DATE   AVAILABLE
# bazarr     1/1     1            1
# lidarr     1/1     1            1
# prowlarr   1/1     1            1
# radarr     1/1     1            1
# sonarr     1/1     1            1
```

---

## 📝 Pre-Deployment Checklist

Before deploying, ensure:

- [ ] NFS directories exist on 10.11.11.46:
  - `/srv/vault/config/sonarr`
  - `/srv/vault/config/radarr`
  - `/srv/vault/config/lidarr`
  - `/srv/vault/config/bazarr` ✨
  - `/srv/vault/config/prowlarr` ✨
  - `/srv/vault/downloads`
  - `/srv/vault/movies`
  - `/srv/vault/music`

- [ ] NFS exports configured: `/srv/vault *(rw,sync,...)`
- [ ] Cluster nodes can reach 10.11.11.46:2049
- [ ] Run: `kubectl apply -k homelab-gitops/apps/media/overlays/prod`

---

## 🔗 Integration Guide

### Bazarr Integration

**With Sonarr & Radarr**:
1. Access Bazarr web UI (port 6767)
2. Configure subtitle providers (OpenSubtitles, etc.)
3. Add Sonarr integration with webhook
4. Add Radarr integration with webhook
5. Set language preferences

**Webhook URLs**:
- Sonarr: `http://sonarr.media.svc.cluster.local/api/notification/bazarr`
- Radarr: `http://radarr.media.svc.cluster.local/api/notification/bazarr`

### Prowlarr Integration

**With All *arr Apps**:
1. Access Prowlarr web UI (port 9696)
2. Add your indexers (Usenet, Torrent, etc.)
3. Configure sync with Sonarr, Radarr, and Lidarr
4. Test each connection
5. Monitor sync status in Prowlarr

**API Configuration**:
- URL: `http://prowlarr.media.svc.cluster.local` (port 80)
- Get API Key from Prowlarr Settings

See `BAZARR_PROWLARR_SETUP.md` for detailed integration steps.

---

## 📚 Documentation

**Quick References**:
- **`BAZARR_PROWLARR_SETUP.md`** - Setup and integration guide ⭐
- **`README.md`** - Updated with new applications
- **`NFS_SETUP_GUIDE.md`** - NFS configuration
- **`PRE_DEPLOYMENT_CHECKLIST.md`** - Deployment verification

---

## 🎯 Next Steps

1. **Create NFS Directories** (if not already done):
   ```bash
   bash setup-nfs-dirs.sh
   ```

2. **Deploy to Kubernetes**:
   ```bash
   kubectl apply -k homelab-gitops/apps/media/overlays/prod
   ```

3. **Verify All Pods Running**:
   ```bash
   kubectl get pods -n media
   ```

4. **Access Web UIs**:
   ```bash
   # Bazarr
   kubectl port-forward -n media svc/bazarr 6767:80

   # Prowlarr
   kubectl port-forward -n media svc/prowlarr 9696:80
   ```

5. **Configure Applications** (see `BAZARR_PROWLARR_SETUP.md`):
   - Set up Bazarr subtitle providers
   - Add indexers to Prowlarr
   - Create integrations between apps

---

## 📋 File Structure Summary

```
homelab-gitops/apps/media/
├── base/
│   ├── namespace.yaml
│   ├── pvc.yaml ✅ UPDATED (added 2 PVCs)
│   ├── kustomization.yaml ✅ UPDATED (added 6 resources)
│   ├── sonarr-* (3 files)
│   ├── radarr-* (3 files)
│   ├── lidarr-* (3 files)
│   ├── bazarr-configmap.yaml ✨ NEW
│   ├── bazarr-deployment.yaml ✨ NEW
│   ├── bazarr-service.yaml ✨ NEW
│   ├── prowlarr-configmap.yaml ✨ NEW
│   ├── prowlarr-deployment.yaml ✨ NEW
│   └── prowlarr-service.yaml ✨ NEW
│
├── overlays/prod/
│   ├── kustomization.yaml ✅ UPDATED (added 2 patches)
│   ├── sonarr-replicas.yaml
│   ├── radarr-replicas.yaml
│   ├── lidarr-replicas.yaml
│   ├── bazarr-replicas.yaml ✨ NEW
│   └── prowlarr-replicas.yaml ✨ NEW
│
├── README.md ✅ UPDATED
├── BAZARR_PROWLARR_SETUP.md ✨ NEW
└── [other documentation files]
```

---

## ✨ What's New

### Added Applications:
- ✅ **Bazarr** - Subtitle management and download automation
- ✅ **Prowlarr** - Centralized indexer management

### New Features:
- ✅ Automatic subtitle downloading for TV/movies
- ✅ Single indexer management API for all *arr apps
- ✅ Indexer failover and redundancy
- ✅ Simplified indexer configuration across all apps

### Storage:
- ✅ 10Gi additional config storage (5Gi each app)
- ✅ Both integrate with existing NFS infrastructure
- ✅ Persist configuration across restarts

---

## 🔍 Quick Commands

```bash
# Deploy
kubectl apply -k homelab-gitops/apps/media/overlays/prod

# Check status
kubectl get all -n media

# Access Bazarr
kubectl port-forward -n media svc/bazarr 6767:80
# Then visit http://localhost:6767

# Access Prowlarr
kubectl port-forward -n media svc/prowlarr 9696:80
# Then visit http://localhost:9696

# View logs
kubectl logs -n media deployment/bazarr
kubectl logs -n media deployment/prowlarr

# Check storage mounts
kubectl exec -it -n media deployment/bazarr -- df -h | grep /srv
kubectl exec -it -n media deployment/prowlarr -- df -h | grep /srv
```

---

## 📞 Support

If you encounter issues:

1. Check `BAZARR_PROWLARR_SETUP.md` → Troubleshooting
2. View logs: `kubectl logs -n media deployment/<app>`
3. Check pod status: `kubectl describe pod -n media <pod-name>`
4. Verify NFS mounts: `kubectl exec -it -n media deployment/<app> -- df -h`

---

**Status**: ✅ All files created and updated  
**Ready to Deploy**: Yes  
**Applications**: 5 (Sonarr, Radarr, Lidarr, Bazarr, Prowlarr)  
**Total Config Storage**: 40Gi / 100Gi  
**Date**: March 2026
