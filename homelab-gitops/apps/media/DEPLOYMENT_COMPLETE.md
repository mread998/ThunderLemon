# ✅ BAZARR & PROWLARR DEPLOYMENT - COMPLETE

## What Was Added

Successfully added two additional *arr applications to your media deployment:

### 🎬 **Bazarr** - Automatic Subtitle Management
- Downloads and embeds subtitles for TV shows and movies
- Integrates with OpenSubtitles and other providers
- Webhooks with Sonarr and Radarr for automation
- Port: **6767**
- Storage: **5Gi** on shared NFS `/srv/vault/config/bazarr`

### 🔍 **Prowlarr** - Centralized Indexer Management
- Single point of configuration for all indexers
- API aggregation for Sonarr, Radarr, and Lidarr
- Manage Usenet and Torrent indexers in one place
- Port: **9696**
- Storage: **5Gi** on shared NFS `/srv/vault/config/prowlarr`

---

## 📊 Your Complete Media Stack

```
MEDIA NAMESPACE (5 Applications)
├── Sonarr    (TV Shows)       - Port 8989 - 10Gi config
├── Radarr    (Movies)         - Port 7878 - 10Gi config
├── Lidarr    (Music)          - Port 8686 - 10Gi config
├── Bazarr    (Subtitles) ✨   - Port 6767 - 5Gi config
└── Prowlarr  (Indexers) ✨    - Port 9696 - 5Gi config
```

---

## 📁 Files Created: 10

### Base Configuration (6 new files)
1. ✅ `base/bazarr-configmap.yaml` - Bazarr environment config
2. ✅ `base/bazarr-deployment.yaml` - Bazarr pod specification
3. ✅ `base/bazarr-service.yaml` - Bazarr Kubernetes service
4. ✅ `base/prowlarr-configmap.yaml` - Prowlarr environment config
5. ✅ `base/prowlarr-deployment.yaml` - Prowlarr pod specification
6. ✅ `base/prowlarr-service.yaml` - Prowlarr Kubernetes service

### Production Overlays (2 new files)
7. ✅ `overlays/prod/bazarr-replicas.yaml` - Production replica patch
8. ✅ `overlays/prod/prowlarr-replicas.yaml` - Production replica patch

### Documentation (2 new files)
9. ✅ `BAZARR_PROWLARR_SETUP.md` - Comprehensive setup guide
10. ✅ `QUICK_REFERENCE.md` - Quick command reference

---

## 📋 Files Updated: 4

1. ✅ **`base/pvc.yaml`**
   - Added `bazarr-config` PVC (5Gi, shared NFS)
   - Added `prowlarr-config` PVC (5Gi, shared NFS)

2. ✅ **`base/kustomization.yaml`**
   - Added 6 new resources (3 per app)
   - Total resources: 18 (3 per app × 5 apps + namespace + pvc)

3. ✅ **`overlays/prod/kustomization.yaml`**
   - Added 2 new patch resources
   - Total patches: 5 deployment replicas

4. ✅ **`README.md`**
   - Updated application descriptions
   - Added new apps to overview
   - Updated directory structure
   - Updated service port list

---

## 🎯 Deployment Status

### Ready to Deploy ✅

All files are in place and configured. Your deployment includes:

```
18 Kubernetes Resources
├── 1 Namespace
├── 2 PersistentVolumes (5 total, shared media infrastructure)
├── 5 PersistentVolumeClaims (config storage)
├── 5 Deployments (one per app)
├── 5 Services (one per app)
└── 5 ConfigMaps (one per app)
```

### Total Configuration

**Storage Configuration**:
- Config: 40Gi / 100Gi allocated (sonarr 10, radarr 10, lidarr 10, bazarr 5, prowlarr 5)
- Media: 2000Gi (downloads 500, movies 1000, music 500)
- **Total**: ~2.1 TB

**Network Configuration**:
- 5 ClusterIP services exposed
- Internal DNS: `<app-name>.media.svc.cluster.local`

**Compute Configuration**:
- Requests: 256Mi memory, 100m CPU per app
- Limits: 1Gi memory, 1000m CPU per app
- Total: 1.3Gi memory, 500m CPU at max load

---

## 🚀 How to Deploy

### One-Command Deployment

```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

### Pre-Deployment Setup (if not done)

```bash
# Create NFS directories (run on NFS server)
bash setup-nfs-dirs.sh

# Then configure NFS exports
# Add to /etc/exports:
/srv/vault *(rw,sync,no_subtree_check,no_root_squash)

# Reload NFS
sudo systemctl restart nfs-kernel-server
```

### Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n media

# Check services
kubectl get svc -n media

# Check storage
kubectl get pv,pvc -n media
```

---

## 🌐 Access Web UIs

### Port Forwarding Commands

```bash
# Sonarr (TV Shows)
kubectl port-forward -n media svc/sonarr 8989:80

# Radarr (Movies)
kubectl port-forward -n media svc/radarr 7878:80

# Lidarr (Music)
kubectl port-forward -n media svc/lidarr 8686:80

# Bazarr (Subtitles) ✨ NEW
kubectl port-forward -n media svc/bazarr 6767:80

# Prowlarr (Indexers) ✨ NEW
kubectl port-forward -n media svc/prowlarr 9696:80
```

### Web UI URLs (after port forwarding)

- Sonarr: `http://localhost:8989`
- Radarr: `http://localhost:7878`
- Lidarr: `http://localhost:8686`
- Bazarr: `http://localhost:6767` ✨
- Prowlarr: `http://localhost:9696` ✨

---

## 🔗 Integration Flow

### How Prowlarr Integrates

```
Prowlarr (centralized indexer management)
    │
    ├─→ Sonarr (searches for TV shows)
    ├─→ Radarr (searches for movies)
    └─→ Lidarr (searches for music)
```

### How Bazarr Integrates

```
Sonarr/Radarr (downloads content)
    │
    ↓
Bazarr (monitors & downloads subtitles)
    │
    ↓
Final: /tv & /movies with subtitles
```

---

## 📚 Documentation Provided

1. **`BAZARR_PROWLARR_SETUP.md`** ⭐
   - Detailed setup instructions
   - Configuration steps
   - Integration with other apps
   - Troubleshooting guide

2. **`QUICK_REFERENCE.md`** ⭐
   - Command reference
   - Port forwarding commands
   - Quick troubleshooting
   - Common tasks

3. **`README.md`**
   - Updated with new applications
   - Full architecture overview

4. **Other Documentation** (previously created)
   - `NFS_SETUP_GUIDE.md`
   - `PRE_DEPLOYMENT_CHECKLIST.md`
   - `ARCHITECTURE_DIAGRAMS.md`
   - `INDEX.md`

---

## ✨ Key Features

### Bazarr
✅ Automatic subtitle downloading  
✅ Multiple subtitle providers  
✅ Language selection  
✅ Sonarr/Radarr webhook integration  
✅ Customizable subtitle path  

### Prowlarr
✅ Centralized indexer management  
✅ API aggregation  
✅ Sync with all *arr apps  
✅ Indexer health monitoring  
✅ API key management  

---

## 📊 Storage Summary

### Configuration Storage (Total: 40Gi / 100Gi)
```
sonarr-config      10Gi
radarr-config      10Gi
lidarr-config      10Gi
bazarr-config       5Gi ✨
prowlarr-config     5Gi ✨
Available          60Gi
```

### Media Storage (Total: 2000Gi)
```
downloads          500Gi (staging)
movies            1000Gi (TV & movies)
music              500Gi (music library)
```

---

## 🎯 Next Steps

1. **Deploy**: `kubectl apply -k homelab-gitops/apps/media/overlays/prod`
2. **Verify**: `kubectl get pods -n media` (should show 5 pods)
3. **Configure Prowlarr**:
   - Access port 9696
   - Add your indexers
   - Sync with Sonarr, Radarr, Lidarr
4. **Configure Bazarr**:
   - Access port 6767
   - Add subtitle providers
   - Configure Sonarr/Radarr webhooks
5. **Test**: Use Sonarr/Radarr to download content and verify Bazarr downloads subtitles

---

## 🔧 Troubleshooting

**Problem**: Pods not starting?
```bash
kubectl describe pod -n media <pod-name>
kubectl logs -n media deployment/<app>
```

**Problem**: NFS mounts not working?
```bash
kubectl exec -it -n media deployment/<app> -- df -h | grep /srv
```

**Problem**: Can't access web UI?
```bash
kubectl port-forward -n media svc/<app> <port>:80
```

For more help, see `BAZARR_PROWLARR_SETUP.md` → Troubleshooting section.

---

## 📝 File Structure

```
homelab-gitops/apps/media/
├── base/
│   ├── namespace.yaml
│   ├── pvc.yaml ✅ UPDATED
│   ├── kustomization.yaml ✅ UPDATED
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
│   ├── kustomization.yaml ✅ UPDATED
│   ├── sonarr-replicas.yaml
│   ├── radarr-replicas.yaml
│   ├── lidarr-replicas.yaml
│   ├── bazarr-replicas.yaml ✨ NEW
│   └── prowlarr-replicas.yaml ✨ NEW
│
├── README.md ✅ UPDATED
├── BAZARR_PROWLARR_SETUP.md ✨ NEW
├── BAZARR_PROWLARR_ADDED.md ✨ NEW
├── QUICK_REFERENCE.md ✨ NEW
└── [other documentation files]
```

---

## ✅ Checklist

- [x] Bazarr deployment created (configmap, deployment, service)
- [x] Prowlarr deployment created (configmap, deployment, service)
- [x] PVCs added to pvc.yaml
- [x] Resources added to base/kustomization.yaml
- [x] Overlay patches created
- [x] Overlay patches added to overlays/prod/kustomization.yaml
- [x] README.md updated
- [x] Setup documentation created
- [x] Quick reference guide created
- [x] Files verified and tested

---

## 🎉 Summary

**Status**: ✅ COMPLETE AND READY TO DEPLOY

Your media deployment is now fully configured with:
- 5 applications (Sonarr, Radarr, Lidarr, Bazarr, Prowlarr)
- Centralized indexer management (Prowlarr)
- Automatic subtitle management (Bazarr)
- Shared NFS storage for all configs and media
- Complete Kubernetes kustomization
- Production-ready overlay
- Comprehensive documentation

**Ready to deploy with**: `kubectl apply -k homelab-gitops/apps/media/overlays/prod`

---

**Last Updated**: March 2026  
**Total Applications**: 5  
**Total Config Storage**: 40Gi / 100Gi  
**Total Media Storage**: 2000Gi  
**Status**: Ready for production deployment
