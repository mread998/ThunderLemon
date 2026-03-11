# Quick Start - Deploy Media Apps Now! 🚀

## TL;DR - Just Run This

### Windows (PowerShell)
```powershell
cd c:\Users\marcr\repo\ThunderLemon
powershell -ExecutionPolicy Bypass -File homelab-gitops/apps/media/deploy.ps1
```

### Linux/Mac (Bash)
```bash
cd ~/repo/ThunderLemon
bash homelab-gitops/apps/media/deploy.sh
```

The script will handle everything automatically! ✅

---

## If You Prefer Manual Steps

```powershell
# 1. Clean up old resources (if they exist)
kubectl delete namespace media --wait=true 2>$null

# 2. Wait for cleanup
Start-Sleep -Seconds 10

# 3. Deploy everything
kubectl apply -k homelab-gitops/apps/media/base/

# 4. Watch PVCs bind (Ctrl+C to stop)
kubectl get pvc -n media --watch

# 5. Once PVCs are Bound, check pods
kubectl get pods -n media

# 6. Wait for all pods to be Running
kubectl wait --for=condition=ready pod --all -n media --timeout=300s
```

---

## Verify Everything Works

```powershell
# All PVCs should be Bound
kubectl get pvc -n media

# All 5 pods should be Running
kubectl get pods -n media

# NFS mounts should be visible
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv
```

---

## Access the Applications

```powershell
# In separate terminal windows, forward each service:
kubectl port-forward -n media svc/sonarr 8989:80    # TV Management
kubectl port-forward -n media svc/radarr 7878:80    # Movie Management
kubectl port-forward -n media svc/lidarr 8686:80    # Music Management
kubectl port-forward -n media svc/bazarr 6767:80    # Subtitles
kubectl port-forward -n media svc/prowlarr 9696:80  # Indexers
```

Then open in browser:
- **Sonarr**: http://localhost:8989
- **Radarr**: http://localhost:7878
- **Lidarr**: http://localhost:8686
- **Bazarr**: http://localhost:6767
- **Prowlarr**: http://localhost:9696

---

## What Changed From Before

✅ **Removed**: 5 static PersistentVolume definitions  
✅ **Removed**: Complex label selectors and volume name bindings  
✅ **Changed**: `storageClassName: ""` → `storageClassName: nfs-rwx`  
✅ **Result**: Cleaner, simpler, more reliable!

---

## Storage Configuration

All 9 PVCs use the `nfs-rwx` StorageClass:

| PVC | Size | Purpose |
|-----|------|---------|
| sonarr-config | 10Gi | TV app config |
| radarr-config | 10Gi | Movie app config |
| lidarr-config | 10Gi | Music app config |
| bazarr-config | 5Gi | Subtitle app config |
| prowlarr-config | 5Gi | Indexer app config |
| media-downloads | 500Gi | Download staging |
| media-tv | 1000Gi | TV shows storage |
| media-movies | 1000Gi | Movies storage |
| media-music | 500Gi | Music storage |

---

## Troubleshooting

### PVCs not binding?
```powershell
kubectl describe pvc sonarr-config -n media
kubectl get events -n media --sort-by='.lastTimestamp'
```

### Pods not starting?
```powershell
kubectl logs -n media deployment/sonarr
kubectl describe pod <pod-name> -n media
```

### NFS not mounting?
```powershell
kubectl exec -it -n media deployment/sonarr -- mount | grep nfs
kubectl exec -it -n media deployment/sonarr -- ping 10.11.11.46
```

---

## Documentation

- 📘 **Detailed Explanation**: `STORAGE_CLASS_UPDATE.md`
- 📋 **Migration Summary**: `MIGRATION_COMPLETE.md`
- 📊 **Complete Overview**: `STORAGE_CLASS_SUMMARY.md`
- 📖 **Architecture**: `README.md`

---

## Files Changed

- ✅ `base/pvc.yaml` - Refactored for nfs-rwx (now ~130 lines, was ~250)
- ✅ `README.md` - Updated architecture documentation
- ✅ `deploy.sh` - New bash deployment script
- ✅ `deploy.ps1` - New PowerShell deployment script

---

**Status**: ✅ Ready to deploy!

Just run the deploy script and you're done! 🎉
