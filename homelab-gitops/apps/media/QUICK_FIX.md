# 🚀 QUICK ACTION - Deploy Fix Now

## The Fix in 30 Seconds

Your PVCs were trying to use the `longhorn` storage class instead of binding to static NFS PVs.

**Fixed by adding:**
- ✅ `storageClassName: ""` to PVs and PVCs
- ✅ Labels to PVs 
- ✅ Selectors to PVCs

---

## Step 1: Clean Up (Choose ONE)

### Automated (Recommended)
```bash
bash recover-deployment.sh
```

### Manual
```bash
kubectl delete namespace media
sleep 5
kubectl delete pv media-config-nfs-pv media-downloads-nfs-pv media-tv-nfs-pv media-movies-nfs-pv media-music-nfs-pv 2>/dev/null
```

---

## Step 2: Re-Deploy

```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

---

## Step 3: Verify

```bash
# Check PVCs (should all show "Bound")
kubectl get pvc -n media

# Check pods (should show "Running")
kubectl get pods -n media
```

---

## Expected Results

```
NAME              STATUS   VOLUME
sonarr-config     Bound    media-config-nfs-pv
radarr-config     Bound    media-config-nfs-pv
lidarr-config     Bound    media-config-nfs-pv
bazarr-config     Bound    media-config-nfs-pv
prowlarr-config   Bound    media-config-nfs-pv
media-downloads   Bound    media-downloads-nfs-pv
media-tv          Bound    media-tv-nfs-pv
media-movies      Bound    media-movies-nfs-pv
media-music       Bound    media-music-nfs-pv
```

---

## That's It! ✅

Your media apps should now deploy successfully.

**For detailed information**: See `FIX_SUMMARY.md` or `PVC_BINDING_FIX.md`
