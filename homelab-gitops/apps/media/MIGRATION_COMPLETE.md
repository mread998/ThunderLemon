# Storage Class Migration Complete ✅

## What Changed

Your cluster has the `nfs-rwx` storage class, which is **perfect** for NFS storage. We've migrated from static PersistentVolumes to dynamic provisioning using this storage class.

### Old Approach ❌
- 5 static PersistentVolumes (media-config-nfs-pv, media-downloads-nfs-pv, etc.)
- Manual label selectors
- Complex binding logic
- Harder to debug and maintain

### New Approach ✅
- Only 9 PersistentVolumeClaims (one per app/storage target)
- Automatic provisioning via `nfs-rwx` StorageClass
- Simple, clean configuration
- Easier to debug and scale

## Storage Configuration Summary

| Component | Size | Storage Class | Mount Point |
|-----------|------|---------------|-------------|
| **Config Storage** | - | nfs-rwx | /config |
| sonarr-config | 10Gi | nfs-rwx | /config |
| radarr-config | 10Gi | nfs-rwx | /config |
| lidarr-config | 10Gi | nfs-rwx | /config |
| bazarr-config | 5Gi | nfs-rwx | /config |
| prowlarr-config | 5Gi | nfs-rwx | /config |
| **Media Storage** | - | nfs-rwx | /media |
| media-downloads | 500Gi | nfs-rwx | /downloads |
| media-tv | 1000Gi | nfs-rwx | /tv |
| media-movies | 1000Gi | nfs-rwx | /movies |
| media-music | 500Gi | nfs-rwx | /music |

## Quick Deploy

### Option 1: Automated (Recommended)

**Windows (PowerShell):**
```powershell
cd c:\Users\marcr\repo\ThunderLemon
powershell -ExecutionPolicy Bypass -File homelab-gitops/apps/media/deploy.ps1
```

**Linux/Mac:**
```bash
cd ~/repo/ThunderLemon
bash homelab-gitops/apps/media/deploy.sh
```

### Option 2: Manual Steps

```powershell
# 1. Delete old namespace if it exists
kubectl delete namespace media --wait=true 2>$null

# 2. Wait for cleanup
Start-Sleep -Seconds 10

# 3. Apply manifests
kubectl apply -k homelab-gitops/apps/media/base/

# 4. Watch PVCs bind
kubectl get pvc -n media --watch

# 5. Check pods
kubectl get pods -n media
```

## Verification

After deployment, verify everything is working:

```powershell
# Check PVCs are bound
kubectl get pvc -n media
# Should show all PVCs with STATUS: Bound

# Check pods are running
kubectl get pods -n media
# Should show 5 pods in Running state

# Verify NFS mounts
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv
# Should show NFS mount points
```

## Files Modified

- ✅ **base/pvc.yaml** - Completely refactored to use nfs-rwx StorageClass
- ✅ **New:** STORAGE_CLASS_UPDATE.md - Detailed explanation of the change
- ✅ **New:** deploy.sh - Bash deployment script
- ✅ **New:** deploy.ps1 - PowerShell deployment script

## Key Points

✅ **No more static PV management** - StorageClass handles it  
✅ **Automatic PVC binding** - Should complete in seconds  
✅ **Cleaner configuration** - Easier to understand and maintain  
✅ **Better scalability** - Add new apps with minimal changes  
✅ **Industry standard** - This is the recommended Kubernetes approach  

## NFS Server Details

The `nfs-rwx` StorageClass connects to your NFS server:
- **Server IP:** 10.11.11.46
- **Base Path:** Configured in storage class settings
- **Access Mode:** ReadWriteMany (multiple pods can write simultaneously)
- **Reclaim Policy:** Retain (PVs kept when PVCs deleted)

## What Gets Created

### PersistentVolumes
When you create PVCs with `storageClassName: nfs-rwx`, the NFS CSI driver automatically creates PVs with names like:
- `pvc-12345678-1234-1234-1234-123456789012`
- `pvc-abcdefgh-abcd-abcd-abcd-abcdefghijkl`
- etc.

These are managed by Kubernetes automatically.

### Subdirectory Structure on NFS
Based on your NFS server configuration (10.11.11.46:/srv/vault), the CSI driver will create subdirectories for each PVC:
- `/srv/vault/config/pvc-*/` - Config directories
- `/srv/vault/downloads/pvc-*/` - Download directories  
- `/srv/vault/tv/pvc-*/` - TV directories
- `/srv/vault/movies/pvc-*/` - Movie directories
- `/srv/vault/music/pvc-*/` - Music directories

Each PVC gets its own subdirectory automatically.

## Troubleshooting

### PVCs Not Binding?

```powershell
# Check PVC details
kubectl describe pvc sonarr-config -n media

# Check storage class
kubectl get storageclass nfs-rwx -o yaml

# Check events
kubectl get events -n media --sort-by='.lastTimestamp'
```

### Pods Failing to Start?

```powershell
# Check pod logs
kubectl logs -n media deployment/sonarr

# Check pod events
kubectl describe pod <pod-name> -n media

# Check NFS server accessibility
kubectl exec -it -n media deployment/sonarr -- ping 10.11.11.46
```

### NFS Mount Issues?

```powershell
# Check if NFS is mounted in pod
kubectl exec -it -n media deployment/sonarr -- mount | grep nfs

# List contents of config directory
kubectl exec -it -n media deployment/sonarr -- ls -la /config
```

## Next Steps

1. **Deploy:** Run the deploy script or manual kubectl commands above
2. **Verify:** Check PVC binding and pod status
3. **Access:** Port-forward to services and verify web UIs are working
4. **Configure:** Set up Prowlarr indexers, Bazarr providers, etc.
5. **Monitor:** Watch logs and ensure apps are functioning correctly

---

**Questions?** Refer to STORAGE_CLASS_UPDATE.md for detailed information.
