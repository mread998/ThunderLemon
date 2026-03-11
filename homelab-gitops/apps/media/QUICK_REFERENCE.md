# Quick Reference - All Media Apps

## Application Overview

| App | Purpose | Port | Config Size | Media Access |
|-----|---------|------|-------------|--------------|
| **Sonarr** | TV Shows | 8989 | 10Gi | /tv, /downloads |
| **Radarr** | Movies | 7878 | 10Gi | /movies, /downloads |
| **Lidarr** | Music | 8686 | 10Gi | /music, /downloads |
| **Bazarr** | Subtitles | 6767 | 5Gi | /tv, /movies |
| **Prowlarr** | Indexers | 9696 | 5Gi | None |

## Service Names (Internal DNS)

```
sonarr.media.svc.cluster.local    (port 80)
radarr.media.svc.cluster.local    (port 80)
lidarr.media.svc.cluster.local    (port 80)
bazarr.media.svc.cluster.local    (port 80)
prowlarr.media.svc.cluster.local  (port 80)
```

## Port Forwarding Commands

```bash
# Sonarr (TV Shows)
kubectl port-forward -n media svc/sonarr 8989:80

# Radarr (Movies)
kubectl port-forward -n media svc/radarr 7878:80

# Lidarr (Music)
kubectl port-forward -n media svc/lidarr 8686:80

# Bazarr (Subtitles)
kubectl port-forward -n media svc/bazarr 6767:80

# Prowlarr (Indexers)
kubectl port-forward -n media svc/prowlarr 9696:80
```

## Web UI Access URLs

After port forwarding:
- Sonarr: `http://localhost:8989`
- Radarr: `http://localhost:7878`
- Lidarr: `http://localhost:8686`
- Bazarr: `http://localhost:6767`
- Prowlarr: `http://localhost:9696`

## Kubernetes Commands

```bash
# Deploy
kubectl apply -k homelab-gitops/apps/media/overlays/prod

# Check status
kubectl get pods -n media
kubectl get svc -n media
kubectl get pv,pvc -n media

# View logs
kubectl logs -n media deployment/sonarr
kubectl logs -n media deployment/radarr
kubectl logs -n media deployment/lidarr
kubectl logs -n media deployment/bazarr
kubectl logs -n media deployment/prowlarr

# Describe pod
kubectl describe pod -n media <pod-name>

# Execute command in pod
kubectl exec -it -n media deployment/<app> -- <command>

# Delete deployment
kubectl delete -k homelab-gitops/apps/media/overlays/prod
```

## NFS Storage Paths

```
10.11.11.46:/srv/vault/
├── config/
│   ├── sonarr/      (10Gi)
│   ├── radarr/      (10Gi)
│   ├── lidarr/      (10Gi)
│   ├── bazarr/      (5Gi)
│   └── prowlarr/    (5Gi)
├── downloads/       (500Gi)
├── movies/          (1000Gi)
└── music/           (500Gi)
```

## Create NFS Directories

```bash
# Quick setup
bash setup-nfs-dirs.sh

# Or manually
mkdir -p /srv/vault/{config/{sonarr,radarr,lidarr,bazarr,prowlarr},downloads,movies,music}
chmod -R 777 /srv/vault
chown -R nobody:nogroup /srv/vault
```

## Test NFS Connectivity

```bash
# From cluster node
showmount -e 10.11.11.46

# Manual mount test
sudo mount -t nfs 10.11.11.46:/srv/vault /mnt/test
ls /mnt/test
sudo umount /mnt/test
```

## Configuration Files

### Base Configuration (always used)
```
base/
├── namespace.yaml              # Creates 'media' namespace
├── pvc.yaml                    # Storage configuration
├── sonarr-{configmap,deployment,service}.yaml
├── radarr-{configmap,deployment,service}.yaml
├── lidarr-{configmap,deployment,service}.yaml
├── bazarr-{configmap,deployment,service}.yaml
├── prowlarr-{configmap,deployment,service}.yaml
└── kustomization.yaml          # Combines all base resources
```

### Production Overlay (recommended)
```
overlays/prod/
├── kustomization.yaml          # Applies production patches
├── sonarr-replicas.yaml
├── radarr-replicas.yaml
├── lidarr-replicas.yaml
├── bazarr-replicas.yaml
└── prowlarr-replicas.yaml
```

## Integration Flows

### Prowlarr → All *arr Apps
```
Prowlarr (manages indexers)
    ↓
Indexers shared with:
    ├─→ Sonarr (searches for TV)
    ├─→ Radarr (searches for movies)
    └─→ Lidarr (searches for music)
```

### Download & Subtitle Flow
```
Sonarr/Radarr (finds content)
    ↓
SABnzbd (downloads)
    ↓
Bazarr (downloads subtitles)
    ↓
Final: /tv, /movies with subtitles
```

## Common Tasks

### Check if PVC is bound to PV
```bash
kubectl get pvc -n media -o wide
# Should show STATUS: Bound
```

### Check storage usage
```bash
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv
```

### List config files
```bash
kubectl exec -it -n media deployment/sonarr -- ls -la /config
```

### Test inter-pod connectivity
```bash
kubectl exec -it -n media deployment/sonarr -- curl http://prowlarr:80
kubectl exec -it -n media deployment/sonarr -- curl http://bazarr:80
```

### Restart an app
```bash
kubectl rollout restart deployment/sonarr -n media
kubectl rollout restart deployment/radarr -n media
kubectl rollout restart deployment/lidarr -n media
kubectl rollout restart deployment/bazarr -n media
kubectl rollout restart deployment/prowlarr -n media
```

### Scale replicas (advanced)
```bash
kubectl scale deployment sonarr -n media --replicas=2
```

## Resource Limits

Each app is configured with:
- **Memory Request**: 256Mi (minimum guaranteed)
- **Memory Limit**: 1Gi (maximum allowed)
- **CPU Request**: 100m (minimum guaranteed)
- **CPU Limit**: 1000m (maximum allowed)

Adjust in deployment files if needed.

## Environment Variables

All apps use standard LinuxServer.io environment variables:

```yaml
PUID: "1000"        # User ID (matching NFS)
PGID: "1000"        # Group ID (matching NFS)
TZ: "UTC"           # Timezone
```

Plus app-specific:
```yaml
SONARR_PORT: "8989"
RADARR_PORT: "7878"
LIDARR_PORT: "8686"
BAZARR_PORT: "6767"
PROWLARR_PORT: "9696"
```

## Troubleshooting Quick Links

| Issue | Command |
|-------|---------|
| Pod not starting | `kubectl describe pod -n media <pod-name>` |
| PVC stuck pending | `kubectl describe pvc -n media <pvc-name>` |
| No NFS access | `showmount -e 10.11.11.46` from cluster node |
| Can't access web UI | `kubectl port-forward -n media svc/<app> ...` |
| Permission denied | Check NFS directory ownership: `ls -la /srv/vault` |
| High memory usage | Check limits: `kubectl top pods -n media` |

## Documentation Files

- `README.md` - Main overview
- `BAZARR_PROWLARR_SETUP.md` - Setup guide for Bazarr & Prowlarr
- `NFS_SETUP_GUIDE.md` - NFS server configuration
- `PRE_DEPLOYMENT_CHECKLIST.md` - Pre-deployment verification
- `ARCHITECTURE_DIAGRAMS.md` - Visual diagrams
- `INDEX.md` - Documentation index
- `COMPLETE_UPDATE_SUMMARY.md` - Full change summary

## Quick Deploy

```bash
# Full deployment in 3 commands:
bash setup-nfs-dirs.sh
# (Configure NFS exports on server)
kubectl apply -k homelab-gitops/apps/media/overlays/prod

# Verify:
kubectl get pods -n media
```

---

**Total Applications**: 5  
**Total Config Storage**: 40Gi / 100Gi  
**Total Media Storage**: 2000Gi  
**Namespace**: media  
**NFS Server**: 10.11.11.46  
**Last Updated**: March 2026
