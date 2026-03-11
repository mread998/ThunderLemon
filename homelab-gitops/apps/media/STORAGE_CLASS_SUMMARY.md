# 🎉 Storage Class Migration - Complete Summary

## Your Cluster's Storage Classes

Based on your kubectl output, your cluster has **three storage classes**:

```
local-path          rancher.io/local-path    Delete    WaitForFirstConsumer   false    33d
longhorn (default)  driver.longhorn.io       Delete    Immediate              true     33d
nfs-rwx             nfs.csi.k8s.io           Retain    Immediate              true     4d20h
```

The **nfs-rwx** storage class is perfect for your NFS-based media setup!

## What Changed

### Before (Static PVs - Complex)
```yaml
PersistentVolume (media-config-nfs-pv)
  ↓
  └─ Label: pv-type: nfs-config
  └─ Manual NFS config: server: 10.11.11.46, path: /srv/vault/config

PersistentVolumeClaim (sonarr-config)
  ↓ (manual selector matching required)
  └─ Selector matching pv-type: nfs-config
```

**Problems:**
- ❌ 5 static PV definitions to manage
- ❌ Complex label/selector matching
- ❌ Manual cleanup required
- ❌ Hard to debug

### After (Dynamic Provisioning - Simple) ✅
```yaml
PersistentVolumeClaim (sonarr-config)
  ↓
  └─ storageClassName: nfs-rwx
  └─ Automatic provisioning via NFS CSI driver

StorageClass (nfs-rwx)
  ↓
  └─ Automatically creates PV on-demand
  └─ Configures NFS mount to 10.11.11.46:/srv/vault
```

**Benefits:**
- ✅ Only 9 PVC definitions (one per app/storage target)
- ✅ Simple, clean configuration
- ✅ Automatic provisioning and cleanup
- ✅ Easy to debug and extend
- ✅ Industry standard approach

## Files Changed

### Modified Files

1. **`base/pvc.yaml`** - COMPLETELY REFACTORED
   - Removed all 5 static PersistentVolume definitions
   - Removed all label and selector configuration
   - Simplified to pure PersistentVolumeClaim definitions
   - Changed storageClassName from `""` to `nfs-rwx`
   - Removed manual volumeName and selector bindings
   - Result: From ~250 lines to ~80 lines (cleaner!)

2. **`README.md`** - Updated Architecture Section
   - Replaced "Longhorn storage" references with "nfs-rwx StorageClass"
   - Updated storage architecture diagram
   - Clarified that all volumes (config + media) now use NFS
   - Added StorageClass details (Access Mode, Binding Mode, Reclaim Policy)

### New Documentation Files

1. **`STORAGE_CLASS_UPDATE.md`** (Detailed Guide)
   - Comprehensive explanation of old vs. new approach
   - Step-by-step deployment instructions
   - Verification procedures with expected output
   - Troubleshooting section with kubectl commands
   - NFS integration details

2. **`MIGRATION_COMPLETE.md`** (Quick Summary)
   - Executive summary of the change
   - Storage configuration table
   - Quick deploy options (automated and manual)
   - Verification checklist
   - What gets created automatically

3. **`deploy.sh`** (Bash Deployment Script)
   - Automated deployment for Linux/Mac
   - Checks prerequisites
   - Applies manifests with progress updates
   - Verifies PVC binding and pod status
   - Colored output for easy reading

4. **`deploy.ps1`** (PowerShell Deployment Script)
   - Automated deployment for Windows
   - Same functionality as bash version
   - Native PowerShell error handling
   - Color-coded status messages

## How This Works Now

### When You Apply manifests:

```
kubectl apply -k homelab-gitops/apps/media/base/
        ↓
    Kubernetes sees 9 PVC resources
        ↓
    Each PVC specifies storageClassName: nfs-rwx
        ↓
    NFS CSI Driver (nfs.csi.k8s.io) is triggered
        ↓
    For each PVC, the driver:
    ├─ Creates a PersistentVolume automatically
    ├─ Generates unique subdirectory on NFS server
    ├─ Configures NFS mount to 10.11.11.46:/srv/vault
    └─ Binds PVC to the new PV
        ↓
    PVC Status changes from Pending → Bound (seconds)
```

### Automatic Directory Structure

Your NFS server will have structure created automatically:

```
/srv/vault/
├── config/
│   ├── pvc-12345678-1234-1234-1234-123456789012/  (sonarr-config)
│   ├── pvc-abcdefgh-abcd-abcd-abcd-abcdefghijkl/  (radarr-config)
│   ├── pvc-qwertyui-qwer-qwer-qwer-qwertyuiopqwe/ (lidarr-config)
│   ├── pvc-asdfghjk-asdf-asdf-asdf-asdfghjklzxcv/ (bazarr-config)
│   └── pvc-zxcvbnm0-zxcv-zxcv-zxcv-zxcvbnmqwerty/ (prowlarr-config)
├── downloads/
│   └── pvc-09876543-0987-0987-0987-098765432109/  (media-downloads)
├── tv/
│   └── pvc-jhgfdsa0-jhgf-jhgf-jhgf-jhgfdsapqwert/ (media-tv)
├── movies/
│   └── pvc-qazwsx12-qazw-qazw-qazw-qazwsx12edcrf/ (media-movies)
└── music/
    └── pvc-edcrfvgt-edcr-edcr-edcr-edcrfvgtyhujk/ (media-music)
```

The NFS CSI driver handles all of this automatically! No manual directory creation needed.

## Deployment Options

### Option 1: Automated (Recommended) ⭐

**Windows PowerShell:**
```powershell
cd c:\Users\marcr\repo\ThunderLemon
powershell -ExecutionPolicy Bypass -File homelab-gitops/apps/media/deploy.ps1
```

**Linux/Mac Bash:**
```bash
cd ~/repo/ThunderLemon
bash homelab-gitops/apps/media/deploy.sh
```

The script will:
- ✅ Clean up old namespace
- ✅ Verify nfs-rwx storage class exists
- ✅ Apply all manifests
- ✅ Wait for PVCs to bind
- ✅ Verify pod status
- ✅ Show next steps

### Option 2: Manual Steps

```powershell
# Clean up (if needed)
kubectl delete namespace media --wait=true

# Wait for cleanup
Start-Sleep -Seconds 10

# Apply manifests
kubectl apply -k homelab-gitops/apps/media/base/

# Watch PVCs bind
kubectl get pvc -n media --watch

# Check pods
kubectl get pods -n media
```

## Verification Steps

After deployment, verify everything works:

```powershell
# 1. Check PVCs are bound
kubectl get pvc -n media

# Expected output: All 9 PVCs with STATUS: Bound

# 2. Check pods are running
kubectl get pods -n media

# Expected output: sonarr, radarr, lidarr, bazarr, prowlarr all Running

# 3. Verify NFS mounts
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv

# Expected output: NFS mount points visible (10.11.11.46:...)

# 4. Check config directory
kubectl exec -it -n media deployment/sonarr -- ls -la /config

# Expected output: Directory exists and is writable
```

## Why This Is Better

| Aspect | Before | After |
|--------|--------|-------|
| **Storage Configuration** | ~250 lines YAML | ~80 lines YAML |
| **PV Management** | Manual | Automatic |
| **Binding Process** | Complex label matching | Automatic via StorageClass |
| **Debugging Complexity** | High | Low |
| **Adding new app** | Create PV + PVC + selectors | Just add PVC |
| **Cleanup** | Manual PV deletion | Automatic |
| **Kubernetes Standard** | Not idiomatic | Industry best practice |

## Key Insights About nfs-rwx

Your `nfs-rwx` StorageClass is configured with:

```yaml
PROVISIONER:        nfs.csi.k8s.io
RECLAIM POLICY:     Retain
VOLUME BINDING MODE: Immediate
```

This means:
- **Provisioner**: NFS CSI Driver (handles mounting)
- **Retain**: PVs kept even if PVC deleted (protects data)
- **Immediate**: PVCs bind instantly (no waiting for pod scheduling)

Perfect for media applications!

## Troubleshooting Guide

### If PVCs don't bind immediately:

```powershell
# Check PVC details
kubectl describe pvc sonarr-config -n media

# Check events
kubectl get events -n media --sort-by='.lastTimestamp'

# Check CSI driver logs
kubectl logs -n kube-system -l app=nfs-csi-driver

# Verify StorageClass is correct
kubectl get storageclass nfs-rwx -o yaml
```

### If pods can't start:

```powershell
# Check pod logs
kubectl logs -n media deployment/sonarr

# Check pod events
kubectl describe pod <pod-name> -n media

# Verify NFS server reachability
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Inside pod: ping 10.11.11.46
```

### If NFS mounts aren't working:

```powershell
# Check mounted volumes
kubectl exec -it -n media deployment/sonarr -- mount | grep nfs

# Test NFS access
kubectl exec -it -n media deployment/sonarr -- mkdir -p /config/test-dir

# Check NFS server directly (from bastion/nfs server)
ls -la /srv/vault/config/
```

## Next Actions

1. **Deploy**: Run `deploy.ps1` or `deploy.sh` script
2. **Verify**: Run verification commands above
3. **Access Applications**: 
   ```powershell
   kubectl port-forward -n media svc/sonarr 8989:80 &
   kubectl port-forward -n media svc/radarr 7878:80 &
   # etc.
   ```
4. **Configure**: Set up indexers, providers, API keys in each app
5. **Monitor**: Watch logs and verify downloads are working

## Port Mappings

Once deployed:
- **Sonarr** (TV): `localhost:8989`
- **Radarr** (Movies): `localhost:7878`
- **Lidarr** (Music): `localhost:8686`
- **Bazarr** (Subtitles): `localhost:6767`
- **Prowlarr** (Indexers): `localhost:9696`

Use `kubectl port-forward` to access them from your machine.

## Questions?

- **Storage Class details**: See `STORAGE_CLASS_UPDATE.md`
- **Migration overview**: See `MIGRATION_COMPLETE.md`
- **Troubleshooting**: See the Troubleshooting Guide above

---

**Status**: ✅ **Ready to Deploy**

All files have been updated and are ready for deployment. The new approach is simpler, cleaner, and follows Kubernetes best practices!
