# PVC Configuration Update Summary

## Changes Made

The PersistentVolume and PersistentVolumeClaim configuration has been completely restructured to use **direct NFS mounts** for all storage (config and media), removing the dependency on Longhorn for configuration storage.

## New NFS Architecture

### PersistentVolumes Created

All PVs point to the external NFS server at `10.11.11.46`:

1. **media-config-nfs-pv** → `/srv/vault/config`
   - Capacity: 100Gi
   - Access Mode: ReadWriteMany
   - Used by: sonarr-config, radarr-config, lidarr-config PVCs

2. **media-downloads-nfs-pv** → `/srv/vault/downloads`
   - Capacity: 500Gi
   - Access Mode: ReadWriteMany
   - Used by: media-downloads PVC

3. **media-tv-nfs-pv** → `/srv/vault/movies`
   - Capacity: 1000Gi
   - Access Mode: ReadWriteMany
   - Used by: media-tv PVC

4. **media-movies-nfs-pv** → `/srv/vault/movies`
   - Capacity: 1000Gi
   - Access Mode: ReadWriteMany
   - Used by: media-movies PVC

5. **media-music-nfs-pv** → `/srv/vault/music`
   - Capacity: 500Gi
   - Access Mode: ReadWriteMany
   - Used by: media-music PVC

### PersistentVolumeClaims Created

**Configuration PVCs** (all bound to media-config-nfs-pv):
- `sonarr-config` - 10Gi
- `radarr-config` - 10Gi
- `lidarr-config` - 10Gi

**Media PVCs**:
- `media-downloads` - 500Gi (downloads staging)
- `media-tv` - 1000Gi (TV shows)
- `media-movies` - 1000Gi (Movies)
- `media-music` - 500Gi (Music library)

## Deployment Updates

All three deployments have been updated to use the new PVCs without subpaths:

### Sonarr
- Config → mounts `sonarr-config` at `/config`
- TV → mounts `media-tv` at `/tv`
- Downloads → mounts `media-downloads` at `/downloads`
- Movies → mounts `media-movies` at `/movies`

### Radarr
- Config → mounts `radarr-config` at `/config`
- Movies → mounts `media-movies` at `/movies`
- Downloads → mounts `media-downloads` at `/downloads`

### Lidarr
- Config → mounts `lidarr-config` at `/config`
- Music → mounts `media-music` at `/music`
- Downloads → mounts `media-downloads` at `/downloads`

## Required NFS Setup (Pre-Deployment)

**Create these directories on your NFS server before deploying:**

```bash
mkdir -p /srv/vault/{config/{sonarr,radarr,lidarr},downloads,movies,music}
```

### Directory Structure

```
/srv/vault/
├── config/
│   ├── sonarr/          → Sonarr app data
│   ├── radarr/          → Radarr app data
│   └── lidarr/          → Lidarr app data
├── downloads/           → Download staging directory
├── movies/              → TV shows and movies
└── music/               → Music library
```

## Advantages of This Configuration

✅ **External NFS Only** - No dependency on Longhorn for app configs
✅ **Easy Backup** - All data backed by external NFS server
✅ **Simple Mount Structure** - No subpaths, direct directory mapping
✅ **Cluster-Independent** - Apps can survive cluster recreation if NFS is preserved
✅ **Persistent Across Deploys** - Configuration persists independently of Kubernetes
✅ **Scalable** - Easy to add more *arr apps sharing the same NFS storage

## Networking Notes

Since this NFS server is external to Kubernetes:
- Ensure all Kubernetes **nodes** have network access to `10.11.11.46:2049` (NFS port)
- Firewall rules must permit NFS traffic (UDP 111, TCP 2049)
- NFS exports should be configured to allow access from your cluster nodes

## Next Steps

1. **Create NFS directories** (see above)
2. **Configure NFS server exports** (see NFS_SETUP_GUIDE.md for details)
3. **Deploy**: `kubectl apply -k homelab-gitops/apps/media/overlays/prod`
4. **Verify**: `kubectl get pv,pvc -n media`
5. **Test mounts**: `kubectl exec -it -n media deployment/sonarr -- df -h`

## Files Modified

- `pvc.yaml` - Complete restructure with separate PVs for each path
- `sonarr-deployment.yaml` - Updated volume mounts and references
- `radarr-deployment.yaml` - Updated volume mounts and references
- `lidarr-deployment.yaml` - Updated volume mounts and references

## New Documentation

- `NFS_SETUP_GUIDE.md` - Comprehensive NFS configuration guide
