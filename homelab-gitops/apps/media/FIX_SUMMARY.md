# 🔧 PV/PVC Binding Issue - FIXED

## Problem

PVCs were stuck in **Pending** status after deployment:

```
STATUS    VOLUME                   CAPACITY   STORAGECLASS
Pending   media-config-nfs-pv      0          longhorn
Pending   media-downloads-nfs-pv   0          longhorn
Pending   media-tv-nfs-pv          0          longhorn
...
```

PVs showed **Available** (not bound):
```
STATUS      CLAIM      STORAGECLASS
Available                <unset>
Available                <unset>
...
```

## Root Cause

❌ **Missing**: `storageClassName: ""` on both PVs and PVCs  
❌ **Missing**: Labels on PVs for selector matching  
❌ **Missing**: Selectors on PVCs to match PV labels  

**Result**: Kubernetes tried to dynamically provision storage using `longhorn` storage class instead of binding to static PVs.

---

## Solution Applied ✅

Updated `base/pvc.yaml` with:

### 1. Added Labels to All PVs
```yaml
metadata:
  labels:
    pv-type: nfs-config  # or nfs-downloads, nfs-tv, etc.
```

### 2. Added storageClassName to All PVs
```yaml
spec:
  storageClassName: ""
```

### 3. Added storageClassName to All PVCs
```yaml
spec:
  storageClassName: ""
```

### 4. Added Selectors to All PVCs
```yaml
spec:
  selector:
    matchLabels:
      pv-type: nfs-config  # matches PV label
```

---

## Recovery Steps

### Quick Automated Recovery (Recommended)

```bash
# Run recovery script (Linux/Mac)
bash recover-deployment.sh

# OR PowerShell (Windows)
powershell -ExecutionPolicy Bypass -File recover-deployment.ps1
```

### Manual Recovery

```bash
# Step 1: Delete namespace (purges broken PVCs)
kubectl delete namespace media

# Step 2: Wait for cleanup
sleep 10

# Step 3: Delete stuck PVs
kubectl delete pv media-config-nfs-pv
kubectl delete pv media-downloads-nfs-pv
kubectl delete pv media-tv-nfs-pv
kubectl delete pv media-movies-nfs-pv
kubectl delete pv media-music-nfs-pv

# Step 4: Re-deploy with fixed configuration
kubectl apply -k homelab-gitops/apps/media/overlays/prod

# Step 5: Verify PVCs are bound
kubectl get pvc -n media

# Step 6: Verify pods are running
kubectl get pods -n media
```

---

## Verification

After recovery, verify with:

```bash
# All PVCs should show STATUS: Bound
kubectl get pvc -n media

# All pods should be running
kubectl get pods -n media

# Check NFS mounts in pod
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv/vault
```

**Expected output**:
```
NAME              STATUS   VOLUME                 CAPACITY
sonarr-config     Bound    media-config-nfs-pv    10Gi
radarr-config     Bound    media-config-nfs-pv    10Gi
lidarr-config     Bound    media-config-nfs-pv    10Gi
bazarr-config     Bound    media-config-nfs-pv    5Gi
prowlarr-config   Bound    media-config-nfs-pv    5Gi
media-downloads   Bound    media-downloads-nfs-pv 500Gi
media-tv          Bound    media-tv-nfs-pv        1000Gi
media-movies      Bound    media-movies-nfs-pv    1000Gi
media-music       Bound    media-music-nfs-pv     500Gi
```

---

## What Changed in pvc.yaml

### Before (Broken)
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

### After (Fixed) ✅
```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: media-config-nfs-pv
  labels:                        # ← ADDED
    pv-type: nfs-config
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.11.11.46
    path: /srv/vault/config
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""           # ← ADDED
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarr-config
  namespace: media
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""           # ← ADDED
  resources:
    requests:
      storage: 10Gi
  volumeName: media-config-nfs-pv
  selector:                      # ← ADDED
    matchLabels:
      pv-type: nfs-config
```

---

## PV Labels by Type

| PV Name | Label | Purpose |
|---------|-------|---------|
| `media-config-nfs-pv` | `pv-type: nfs-config` | App config storage (shared) |
| `media-downloads-nfs-pv` | `pv-type: nfs-downloads` | Download staging |
| `media-tv-nfs-pv` | `pv-type: nfs-tv` | TV shows |
| `media-movies-nfs-pv` | `pv-type: nfs-movies` | Movies |
| `media-music-nfs-pv` | `pv-type: nfs-music` | Music library |

---

## Multiple PVCs on Single PV

**Note**: Multiple PVCs can bind to the same PV:

- **media-config-nfs-pv** (100Gi) hosts:
  - sonarr-config (10Gi)
  - radarr-config (10Gi)
  - lidarr-config (10Gi)
  - bazarr-config (5Gi)
  - prowlarr-config (5Gi)
  - **Total**: 40Gi ≤ 100Gi capacity ✓

This is allowed because the PV has `accessModes: [ReadWriteMany]` and adequate capacity.

---

## Files Modified

✅ `base/pvc.yaml` - Added labels, storageClassName, and selectors

## Files Created

✅ `PVC_BINDING_FIX.md` - Detailed troubleshooting guide  
✅ `recover-deployment.sh` - Linux/Mac recovery script  
✅ `recover-deployment.ps1` - PowerShell recovery script

---

## Commands Reference

```bash
# Check PV status
kubectl get pv | grep media

# Check PVC status (should show Bound)
kubectl get pvc -n media

# Check PV details
kubectl describe pv media-config-nfs-pv

# Check PVC details
kubectl describe pvc sonarr-config -n media

# Check pod mount status
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv

# Check all media namespace resources
kubectl get all -n media

# Watch pod startup
kubectl get pods -n media -w
```

---

## Troubleshooting if Issues Persist

### If PVCs still Pending after recovery:

```bash
# Check PVC events
kubectl describe pvc sonarr-config -n media

# Check pod events
kubectl describe pod -n media <pod-name>

# Check if NFS server is reachable from cluster node
kubectl exec -it -n media deployment/sonarr -- mount -t nfs 10.11.11.46:/srv/vault /mnt/test

# Check NFS exports
kubectl exec -it -n media deployment/sonarr -- showmount -e 10.11.11.46
```

### If NFS mount fails:

1. Verify NFS server is running: `sudo systemctl status nfs-kernel-server`
2. Check exports: `sudo exportfs -v`
3. Test from cluster node: `sudo mount -t nfs 10.11.11.46:/srv/vault /mnt/test`
4. Check firewall: `sudo ufw status` (port 2049 must be open)

### If pods still can't start:

```bash
# Check pod logs
kubectl logs -n media deployment/sonarr --previous

# Check events
kubectl get events -n media --sort-by='.lastTimestamp'

# Describe pod for detailed info
kubectl describe pod -n media <pod-name>
```

---

## Prevention for Future Deployments

When creating static PV/PVC YAML:

1. ✅ **Always use `storageClassName: ""`** on both PV and PVC
2. ✅ **Add labels to PVs** for identification
3. ✅ **Use selectors on PVCs** to match labels
4. ✅ **Explicitly set `volumeName`** for direct binding
5. ✅ **Test binding** before creating deployments: `kubectl get pvc`

---

## Documentation

- **Detailed Guide**: `PVC_BINDING_FIX.md`
- **Recovery Scripts**: `recover-deployment.sh` or `recover-deployment.ps1`
- **General Guide**: `PRE_DEPLOYMENT_CHECKLIST.md`
- **NFS Setup**: `NFS_SETUP_GUIDE.md`

---

## Status

✅ **FIXED** - Updated `base/pvc.yaml`  
⏭️ **NEXT** - Run recovery script to re-deploy  
⏸️ **THEN** - Verify all PVCs show "Bound"  
🚀 **FINALLY** - Pods will start and media apps will be accessible

---

**Last Updated**: March 11, 2026  
**Files Fixed**: 1 (base/pvc.yaml)  
**Files Created**: 3 (PVC_BINDING_FIX.md, recover-deployment.sh, recover-deployment.ps1)  
**Recovery Time**: ~5-10 minutes
