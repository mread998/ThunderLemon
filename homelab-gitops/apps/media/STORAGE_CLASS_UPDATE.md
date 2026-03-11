# Storage Class Update - Using nfs-rwx

## Good News! 🎉

Your cluster has the `nfs-rwx` storage class available, which simplifies the entire setup significantly!

### Previous Approach (Static PVs)
- Required creating static PersistentVolumes manually
- Needed label selectors to match PVs with PVCs
- More complex to manage and debug
- Required manual cleanup of unused PVs

### New Approach (Dynamic Provisioning) ✅
- Uses the `nfs-rwx` StorageClass for automatic provisioning
- Each PVC requests storage directly from the storage class
- The NFS CSI driver handles the NFS mount automatically
- Simpler, cleaner, more maintainable

## What Changed

### pvc.yaml Now Contains Only PersistentVolumeClaims

Instead of:
```yaml
# OLD: Static PV + PVC binding
PersistentVolume (media-config-nfs-pv)
  ↓ (manual label matching)
PersistentVolumeClaim (sonarr-config)
```

Now we have:
```yaml
# NEW: Dynamic provisioning via StorageClass
PersistentVolumeClaim (sonarr-config)
  ↓ (automatic via storageClassName: nfs-rwx)
StorageClass (nfs-rwx) → Creates PV automatically
```

## Updated PVC Structure

All 9 PVCs now use this simple pattern:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <app-name>-config    # or media-downloads, media-tv, etc.
  namespace: media
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-rwx   # This is the key!
  resources:
    requests:
      storage: <size>Gi
```

## Key Advantages

| Aspect | Static PVs | Dynamic (nfs-rwx) |
|--------|-----------|------------------|
| **Complexity** | High | Low |
| **PV Management** | Manual | Automatic |
| **Debugging** | Harder | Easier |
| **Scalability** | Limited | Better |
| **Recovery** | Manual cleanup needed | Automatic cleanup |

## NFS Server Integration

The `nfs-rwx` StorageClass is already configured on your cluster to connect to:
- **Server**: 10.11.11.46
- **Base Path**: Configured by the storage class
- **Volume Binding Mode**: Immediate (PVCs bind instantly)

## Deployment Instructions

### 1. Clean Up Old Resources (if you applied the old pvc.yaml)

```powershell
# Delete the namespace and all resources
kubectl delete namespace media

# Wait for it to clean up
Start-Sleep -Seconds 10
```

### 2. Verify nfs-rwx Storage Class

```powershell
# Check it exists and is configured correctly
kubectl get storageclass nfs-rwx -o yaml
```

### 3. Apply New Manifests

```powershell
# Apply from the base directory
kubectl apply -k homelab-gitops/apps/media/base/

# For production overlay:
kubectl apply -k homelab-gitops/apps/media/overlays/prod/
```

### 4. Verify PVCs Are Binding

```powershell
# Watch PVCs bind (should show Bound almost immediately)
kubectl get pvc -n media --watch

# Expected output:
# NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
# sonarr-config      Bound    pvc-12345678-1234-1234-1234-123456789012   10Gi       RWX            nfs-rwx
# radarr-config      Bound    pvc-abcdefgh-abcd-abcd-abcd-abcdefghijkl   10Gi       RWX            nfs-rwx
# lidarr-config      Bound    pvc-qwertyui-qwer-qwer-qwer-qwertyuiopqwe  10Gi       RWX            nfs-rwx
# bazarr-config      Bound    pvc-asdfghjk-asdf-asdf-asdf-asdfghjklzxcv  5Gi        RWX            nfs-rwx
# prowlarr-config    Bound    pvc-zxcvbnm0-zxcv-zxcv-zxcv-zxcvbnmqwerty  5Gi        RWX            nfs-rwx
# media-downloads    Bound    pvc-09876543-0987-0987-0987-098765432109   500Gi      RWX            nfs-rwx
# media-tv           Bound    pvc-jhgfdsa0-jhgf-jhgf-jhgf-jhgfdsapqwert  1000Gi     RWX            nfs-rwx
# media-movies       Bound    pvc-qazwsx12-qazw-qazw-qazw-qazwsx12edcrf  1000Gi     RWX            nfs-rwx
# media-music        Bound    pvc-edcrfvgt-edcr-edcr-edcr-edcrfvgtyhujk  500Gi      RWX            nfs-rwx
```

### 5. Verify Pods Are Running

```powershell
kubectl get pods -n media

# Expected: All 5 pods should be Running
```

### 6. Verify NFS Mounts

```powershell
# Check if apps can see NFS mounts
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv

# Should show NFS mount points are accessible
```

## Configuration Details

### Application Configuration Directories

Each app's config PVC will be mounted at `/config` in the container:
- **sonarr-config** → 10Gi shared NFS space for Sonarr config
- **radarr-config** → 10Gi shared NFS space for Radarr config
- **lidarr-config** → 10Gi shared NFS space for Lidarr config
- **bazarr-config** → 5Gi shared NFS space for Bazarr config
- **prowlarr-config** → 5Gi shared NFS space for Prowlarr config

### Media Storage Directories

Shared across all *arr applications:
- **media-downloads** → 500Gi for incomplete downloads
- **media-tv** → 1000Gi for TV shows
- **media-movies** → 1000Gi for movies
- **media-music** → 500Gi for music

## Troubleshooting

### PVCs Still Pending?

```powershell
# 1. Check the PVC details
kubectl describe pvc sonarr-config -n media

# 2. Check storage class configuration
kubectl get storageclass nfs-rwx -o yaml

# 3. Check PVC events
kubectl get events -n media --sort-by='.lastTimestamp'
```

### NFS Mount Not Working?

```powershell
# 1. Verify pod can reach NFS server
kubectl exec -it -n media deployment/sonarr -- ping 10.11.11.46

# 2. Check mounted volumes inside pod
kubectl exec -it -n media deployment/sonarr -- mount | grep nfs

# 3. Test NFS access from within pod
kubectl exec -it -n media deployment/sonarr -- ls -la /config
```

## Reverting (If Needed)

If you need to revert to static PVs (not recommended):

1. Delete the current namespace
2. Restore from the git history (or contact if you need the old pvc.yaml)
3. Re-apply with the old approach

But honestly, the dynamic provisioning approach is better!

## Summary

✅ **Much simpler** - No static PV management  
✅ **More reliable** - StorageClass handles provisioning  
✅ **Easier debugging** - Fewer moving parts  
✅ **Better scalability** - Add new apps easily  

Your cluster's `nfs-rwx` StorageClass is perfect for this setup. This is the recommended modern Kubernetes approach!
