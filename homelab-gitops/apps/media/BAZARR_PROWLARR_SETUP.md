# New Applications Added - Bazarr & Prowlarr

## Overview

Two additional *arr applications have been added to your media deployment:

- **Bazarr** - Automatic subtitle management for TV shows and movies
- **Prowlarr** - Centralized indexer manager for all *arr applications

## Application Details

### Bazarr

**Purpose**: Manages subtitles for TV shows and movies  
**Image**: `ghcr.io/linuxserver/bazarr:latest`  
**Port**: 6767  
**Service Port**: 80 → 6767  
**Config Storage**: 5Gi on shared NFS `/srv/vault/config/bazarr`  
**Media Access**: `/tv`, `/movies` (read-only)

**Volume Mounts**:
- `/config` - Bazarr application configuration
- `/tv` - TV shows directory (for subtitle management)
- `/movies` - Movies directory (for subtitle management)

**Use Cases**:
- Automatically download and add subtitles to downloaded content
- Support for multiple languages
- Integration with subtitle providers (OpenSubtitles, etc.)
- Integrates with Sonarr and Radarr

### Prowlarr

**Purpose**: Centralized indexer management and API aggregation  
**Image**: `ghcr.io/linuxserver/prowlarr:latest`  
**Port**: 9696  
**Service Port**: 80 → 9696  
**Config Storage**: 5Gi on shared NFS `/srv/vault/config/prowlarr`  
**Media Access**: None (no media access required)

**Volume Mounts**:
- `/config` - Prowlarr application configuration

**Use Cases**:
- Centralized management of all indexers for Sonarr, Radarr, Lidarr
- Single API endpoint for all indexer requests
- Better indexer redundancy and load balancing
- Simplified maintenance of indexer configurations

## Configuration

### Environment Variables

**Bazarr ConfigMap**:
```yaml
PUID: "1000"
PGID: "1000"
TZ: "UTC"
BAZARR_PORT: "6767"
```

**Prowlarr ConfigMap**:
```yaml
PUID: "1000"
PGID: "1000"
TZ: "UTC"
PROWLARR_PORT: "9696"
```

### Storage

Both applications share the common NFS configuration:

- **NFS Server**: 10.11.11.46
- **Config Path**: `/srv/vault/config`
- **Bazarr Config**: `/srv/vault/config/bazarr` (5Gi)
- **Prowlarr Config**: `/srv/vault/config/prowlarr` (5Gi)

### Resources

Both applications configured with:
- **Requests**: 256Mi memory, 100m CPU
- **Limits**: 1Gi memory, 1000m CPU

## Files Created

### Base Configuration
- `base/bazarr-configmap.yaml`
- `base/bazarr-deployment.yaml`
- `base/bazarr-service.yaml`
- `base/prowlarr-configmap.yaml`
- `base/prowlarr-deployment.yaml`
- `base/prowlarr-service.yaml`

### Production Overlays
- `overlays/prod/bazarr-replicas.yaml`
- `overlays/prod/prowlarr-replicas.yaml`

### Updated Files
- `base/pvc.yaml` - Added bazarr-config and prowlarr-config PVCs
- `base/kustomization.yaml` - Added new resources
- `overlays/prod/kustomization.yaml` - Added new patches
- `README.md` - Updated application list

## Pre-Deployment Requirements

### Create NFS Directories

On your NFS server (10.11.11.46), ensure these directories exist:

```bash
mkdir -p /srv/vault/config/bazarr
mkdir -p /srv/vault/config/prowlarr
```

Or run the setup script which includes these directories:
```bash
bash setup-nfs-dirs.sh
```

### Update NFS Exports (if needed)

Ensure `/etc/exports` includes:
```
/srv/vault *(rw,sync,no_subtree_check,no_root_squash)
```

## Deployment

The new applications are included in the standard deployment:

```bash
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

Verify all applications are deployed:

```bash
kubectl get deployments -n media
# Should show: sonarr, radarr, lidarr, bazarr, prowlarr
```

## Accessing the Applications

### Port Forwarding

**Bazarr**:
```bash
kubectl port-forward -n media svc/bazarr 6767:80
# Access at http://localhost:6767
```

**Prowlarr**:
```bash
kubectl port-forward -n media svc/prowlarr 9696:80
# Access at http://localhost:9696
```

### Internal DNS

- Bazarr: `bazarr.media.svc.cluster.local`
- Prowlarr: `prowlarr.media.svc.cluster.local`

## Setup Instructions

### Bazarr Setup

1. Access Bazarr web interface
2. Configure subtitle providers (OpenSubtitles, etc.)
3. Enable integrations with Sonarr and Radarr
4. Set language preferences
5. Configure download directory paths

### Prowlarr Setup

1. Access Prowlarr web interface
2. Add your indexers (Usenet, Torrent, etc.)
3. Configure sync with:
   - Sonarr
   - Radarr
   - Lidarr
4. Test indexers
5. Monitor sync status

## Integration with Other Apps

### Bazarr Integration

**With Sonarr**:
- Configure Sonarr webhook in Bazarr
- Bazarr will automatically download subtitles for new TV episodes

**With Radarr**:
- Configure Radarr webhook in Bazarr
- Bazarr will automatically download subtitles for new movies

### Prowlarr Integration

**With Sonarr**:
1. In Sonarr Settings → Indexers → Add Prowlarr
2. Set API URL: `http://prowlarr.media.svc.cluster.local:80`
3. Set API Key (from Prowlarr)

**With Radarr**:
1. In Radarr Settings → Indexers → Add Prowlarr
2. Set API URL: `http://prowlarr.media.svc.cluster.local:80`
3. Set API Key (from Prowlarr)

**With Lidarr**:
1. In Lidarr Settings → Indexers → Add Prowlarr
2. Set API URL: `http://prowlarr.media.svc.cluster.local:80`
3. Set API Key (from Prowlarr)

## Troubleshooting

### Check Deployment Status

```bash
kubectl get deployments -n media
kubectl describe deployment bazarr -n media
kubectl describe deployment prowlarr -n media
```

### View Logs

```bash
kubectl logs -n media deployment/bazarr
kubectl logs -n media deployment/prowlarr
```

### Check Storage Mounts

```bash
# Bazarr
kubectl exec -it -n media deployment/bazarr -- df -h | grep /srv
kubectl exec -it -n media deployment/bazarr -- ls -la /config

# Prowlarr
kubectl exec -it -n media deployment/prowlarr -- df -h | grep /srv
kubectl exec -it -n media deployment/prowlarr -- ls -la /config
```

### Connection Issues

If other apps can't connect to Prowlarr or Bazarr:

```bash
# Test connectivity from other pods
kubectl exec -it -n media deployment/sonarr -- curl http://prowlarr:80
kubectl exec -it -n media deployment/sonarr -- curl http://bazarr:80
```

## Storage Information

### Total Config Storage Used

- Sonarr: 10Gi
- Radarr: 10Gi
- Lidarr: 10Gi
- Bazarr: 5Gi
- Prowlarr: 5Gi
- **Total**: 40Gi of 100Gi allocated

### Remaining Storage

- **Available**: 60Gi
- Can expand allocations if needed by modifying `pvc.yaml` (requires volume resize support)

## What's Next

1. Deploy with `kubectl apply -k homelab-gitops/apps/media/overlays/prod`
2. Access Bazarr and configure subtitle providers
3. Access Prowlarr and add your indexers
4. Configure integrations between apps
5. Test end-to-end workflows

## Reference Links

- **Bazarr Documentation**: https://www.bazarr.media/
- **Prowlarr Documentation**: https://wiki.servarr.com/prowlarr
- **LinuxServer Bazarr**: https://docs.linuxserver.io/images/docker-bazarr
- **LinuxServer Prowlarr**: https://docs.linuxserver.io/images/docker-prowlarr

## Additional Resources

- See `NFS_SETUP_GUIDE.md` for NFS configuration details
- See `PRE_DEPLOYMENT_CHECKLIST.md` for deployment verification
- See `ARCHITECTURE_DIAGRAMS.md` for storage architecture
