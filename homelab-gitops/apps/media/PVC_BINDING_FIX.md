# PV/PVC Binding Fix - Troubleshooting

## Problem Identified

**Issue**: PVCs were stuck in "Pending" status with no volumes assigned, showing `longhorn` as storageClass instead of being unset.

**Root Cause**: 
- PVCs didn't specify `storageClassName: ""`
- PVs lacked labels for selector matching
- Kubernetes was trying to dynamically provision storage using the `longhorn` storage class instead of binding to static PVs

## Solution Applied

Updated `pvc.yaml` with the following changes:

### 1. Added Labels to PersistentVolumes

```yaml
metadata:
  name: media-config-nfs-pv
  labels:
    pv-type: nfs-config  # ← Added label
```

Each PV now has a unique label:
- `pv-type: nfs-config` - Configuration storage
- `pv-type: nfs-downloads` - Downloads storage
- `pv-type: nfs-tv` - TV shows storage
- `pv-type: nfs-movies` - Movies storage
- `pv-type: nfs-music` - Music storage

### 2. Added storageClassName to PersistentVolumes

```yaml
spec:
  # ... other spec fields ...
  storageClassName: ""  # ← Added this line
```

Empty string `""` indicates this is a static PV without a dynamic storage class.

### 3. Added storageClassName to PersistentVolumeClaims

```yaml
spec:
  storageClassName: ""  # ← Added this line
  # ... other spec fields ...
```

This tells the PVC to NOT try to dynamically provision storage.

### 4. Added Selectors to PersistentVolumeClaims

```yaml
spec:
  # ... other spec fields ...
  selector:
    matchLabels:
      pv-type: nfs-config  # ← Added this section
```

This ensures each PVC binds to the correct labeled PV.

## How This Fixes the Issue

### Before (Broken)
```
PVC requests storage from longhorn StorageClass
  ↓
No longhorn provisioner to fulfill request
  ↓
PVC stuck in Pending
```

### After (Fixed)
```
PVC searches for static PV with matching label and capacity
  ↓
Finds labeled PV (media-config-nfs-pv with label pv-type: nfs-config)
  ↓
PVC binds to PV
  ↓
PVC becomes Bound
```

## Recovery Steps

### 1. Delete Existing Broken PVCs

```bash
# Delete the namespace and all resources (this will also delete PVCs)
kubectl delete namespace media

# Wait a moment for cleanup
sleep 10
```

**Note**: This will NOT delete the PVs (they have `Retain` reclaim policy), so your data is safe.

### 2. Delete Stuck PVs (Important!)

If you see "Released" status PVs, delete them:

```bash
# Check for any released PVs
kubectl get pv | grep Released

# Delete any released PVs from media
kubectl delete pv media-config-nfs-pv
kubectl delete pv media-downloads-nfs-pv
kubectl delete pv media-tv-nfs-pv
kubectl delete pv media-movies-nfs-pv
kubectl delete pv media-music-nfs-pv
```

### 3. Re-deploy with Fixed Configuration

```bash
# Apply the updated configuration
kubectl apply -k homelab-gitops/apps/media/overlays/prod

# Verify PVs are created
kubectl get pv | grep media

# Verify PVCs are bound
kubectl get pvc -n media

# Check status should show "Bound"
```

### 4. Verify All PVCs are Bound

```bash
kubectl get pvc -n media
```

**Expected output**:
```
NAME              STATUS   VOLUME                 CAPACITY   ACCESS MODES
sonarr-config     Bound    media-config-nfs-pv    10Gi       RWX
radarr-config     Bound    media-config-nfs-pv    10Gi       RWX
lidarr-config     Bound    media-config-nfs-pv    10Gi       RWX
bazarr-config     Bound    media-config-nfs-pv    5Gi        RWX
prowlarr-config   Bound    media-config-nfs-pv    5Gi        RWX
media-downloads   Bound    media-downloads-nfs-pv 500Gi      RWX
media-tv          Bound    media-tv-nfs-pv        1000Gi     RWX
media-movies      Bound    media-movies-nfs-pv    1000Gi     RWX
media-music       Bound    media-music-nfs-pv     500Gi      RWX
```

### 5. Verify Pods Start

```bash
kubectl get pods -n media

# Should show all 5 pods running
# sonarr, radarr, lidarr, bazarr, prowlarr
```

## Key Differences in Fixed pvc.yaml

### Configuration Storage (Example)

**Before**:
```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: media-config-nfs-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.11.11.46
    path: /srv/vault/config
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarr-config
  namespace: media
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  volumeName: media-config-nfs-pv
```

**After**:
```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: media-config-nfs-pv
  labels:
    pv-type: nfs-config              # ← Added
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.11.11.46
    path: /srv/vault/config
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""                # ← Added
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarr-config
  namespace: media
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""                # ← Added
  resources:
    requests:
      storage: 10Gi
  volumeName: media-config-nfs-pv
  selector:                            # ← Added
    matchLabels:
      pv-type: nfs-config
```

## Multiple PVCs Binding to Single PV

**Important**: Multiple PVCs CAN bind to the same PV as long as:
1. The PV has `accessModes: [ReadWriteMany]` ✓
2. The total requested storage ≤ PV capacity
3. Each PVC requests less than or equal to PV capacity

In your case:
- `media-config-nfs-pv` (100Gi capacity) is shared by:
  - sonarr-config (10Gi)
  - radarr-config (10Gi)
  - lidarr-config (10Gi)
  - bazarr-config (5Gi)
  - prowlarr-config (5Gi)
  - Total: 40Gi ≤ 100Gi ✓

## Verification Commands

```bash
# Check PV details
kubectl describe pv media-config-nfs-pv

# Check PVC details
kubectl describe pvc sonarr-config -n media

# Check if pod can mount
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv/vault

# Check pod events
kubectl describe pod -n media <pod-name>
```

## Prevention for Future Deployments

When creating static PV/PVC configurations:

1. **Always specify storageClassName: ""** on both PV and PVC
2. **Label all PVs** with identifying metadata
3. **Use selectors on PVCs** to match PV labels
4. **Explicitly set volumeName** on PVC for direct binding
5. **Test PVC binding** before creating pods

## Reference

- Kubernetes PV/PVC Binding: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#binding
- Static Provisioning: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static
- Storage Classes: https://kubernetes.io/docs/concepts/storage/storage-classes/

---

**Status**: ✅ Fixed  
**Date**: March 2026  
**Next Step**: Re-deploy with `kubectl apply -k homelab-gitops/apps/media/overlays/prod`
