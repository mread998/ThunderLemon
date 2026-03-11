# Media *arr Apps Deployment

This directory contains Kubernetes manifests for deploying a suite of *arr applications in your homelab.

## Overview

The media deployment includes:

- **Sonarr** - Automatic TV show management and downloads
- **Radarr** - Automatic movie management and downloads  
- **Lidarr** - Automatic music management and downloads
- **Bazarr** - Automatic subtitle management
- **Prowlarr** - Centralized indexer management

All applications share NFS-backed persistent volumes for both configuration and media storage.

## Architecture

### Namespace
All applications are deployed in the `media` namespace for isolation and organization.

### Storage

#### Dynamic NFS Provisioning via nfs-rwx StorageClass
The cluster has the `nfs-rwx` StorageClass configured for automatic NFS volume provisioning:
- **Server**: `10.11.11.46`
- **Path**: `/srv/vault`
- **Storage Class**: `nfs-rwx` (NFS CSI Driver)
- **Access Mode**: ReadWriteMany (shared access)
- **Volume Binding Mode**: Immediate

#### Application Configuration
Each application has its own NFS-backed PVC for configuration:
- `sonarr-config` - 10Gi mounted at `/config`
- `radarr-config` - 10Gi mounted at `/config`
- `lidarr-config` - 10Gi mounted at `/config`
- `bazarr-config` - 5Gi mounted at `/config`
- `prowlarr-config` - 5Gi mounted at `/config`

#### Media Storage
Shared across all *arr applications via NFS PVCs:
- `media-downloads` - 500Gi mounted at `/downloads` (staging area)
- `media-tv` - 1000Gi mounted at `/tv` (TV show storage)
- `media-movies` - 1000Gi mounted at `/movies` (movie storage)
- `media-music` - 500Gi mounted at `/music` (music storage)

### Services

Each application exposes a ClusterIP service:
- `sonarr:80` → container port `8989` (TV management)
- `bazarr:80` → container port `6767`
- `prowlarr:80` → container port `9696`

## Directory Structure

```
media/
├── base/
│   ├── namespace.yaml              # media namespace definition
│   ├── pvc.yaml                    # NFS PV/PVC and app config PVCs
│   ├── sonarr-configmap.yaml       # Sonarr environment variables
│   ├── sonarr-deployment.yaml      # Sonarr deployment spec
│   ├── sonarr-service.yaml         # Sonarr service
│   ├── radarr-configmap.yaml       # Radarr environment variables
│   ├── radarr-deployment.yaml      # Radarr deployment spec
│   ├── radarr-service.yaml         # Radarr service
│   ├── lidarr-configmap.yaml       # Lidarr environment variables
│   ├── lidarr-deployment.yaml      # Lidarr deployment spec
│   ├── lidarr-service.yaml         # Lidarr service
│   ├── bazarr-configmap.yaml       # Bazarr environment variables
│   ├── bazarr-deployment.yaml      # Bazarr deployment spec
│   ├── bazarr-service.yaml         # Bazarr service
│   ├── prowlarr-configmap.yaml     # Prowlarr environment variables
│   ├── prowlarr-deployment.yaml    # Prowlarr deployment spec
│   ├── prowlarr-service.yaml       # Prowlarr service
│   └── kustomization.yaml          # Base kustomization
└── overlays/
    └── prod/
        ├── kustomization.yaml      # Production overlay
        ├── sonarr-replicas.yaml    # Production Sonarr config
        ├── radarr-replicas.yaml    # Production Radarr config
        ├── lidarr-replicas.yaml    # Production Lidarr config
        ├── bazarr-replicas.yaml    # Production Bazarr config
        └── prowlarr-replicas.yaml  # Production Prowlarr config
```

## Deployment

### Using Kustomize

```bash
# Deploy base configuration
kubectl apply -k homelab-gitops/apps/media/base

# Deploy production overlay
kubectl apply -k homelab-gitops/apps/media/overlays/prod
```

### Using ArgoCD

The ArgoCD application manifest is configured in `homelab-gitops/argocd/apps/media-app.yaml`.

```bash
# Apply the ArgoCD application
kubectl apply -f homelab-gitops/argocd/apps/media-app.yaml
```

## Configuration

### Environment Variables

All applications use standard LinuxServer.io environment variables. Key variables are configured in ConfigMaps:

- `PUID: 1000` - User ID for file permissions
- `PGID: 1000` - Group ID for file permissions
- `TZ: UTC` - Timezone

For Sonarr:
- `SONARR_PORT: 8989`
- `SONARR_BRANCH: main`

For Radarr:
- `RADARR_PORT: 7878`
- `RADARR_BRANCH: master`

For Lidarr:
- `LIDARR_PORT: 8686`
- `LIDARR_BRANCH: master`

### Secrets

Sensitive data (API keys, authentication) should be stored in Kubernetes Secrets. You can create secrets for application API keys:

```bash
kubectl create secret generic sonarr-credentials \
  --from-literal=SONARR_APIKEY=<your-api-key> \
  -n media
```

Then reference them in deployments using `secretRef`.

## Resource Requirements

Each application is configured with:
- **Requests**: 256Mi memory, 100m CPU
- **Limits**: 1Gi memory, 1000m CPU

Adjust these based on your workload and cluster capacity.

## NFS Configuration

The NFS volume is configured as a Kubernetes PersistentVolume with:
- **Access Mode**: ReadWriteMany (allows multiple pods to access simultaneously)
- **Reclaim Policy**: Retain (data persists after volume deletion)
- **Storage**: 500Gi allocated

Ensure your NFS server is accessible from all Kubernetes nodes.

## Adding More *arr Applications

To add more *arr applications (e.g., Readarr, Prowlarr), follow this pattern:

1. Create ConfigMap in `base/<app>-configmap.yaml`
2. Create Deployment in `base/<app>-deployment.yaml`
3. Create Service in `base/<app>-service.yaml`
4. Add resources to `base/kustomization.yaml`
5. Create overlay patches in `overlays/prod/<app>-replicas.yaml`
6. Update `overlays/prod/kustomization.yaml`

## Troubleshooting

### Check deployment status
```bash
kubectl get deployments -n media
kubectl describe deployment sonarr -n media
```

### View application logs
```bash
kubectl logs -n media deployment/sonarr
kubectl logs -n media deployment/radarr
kubectl logs -n media deployment/lidarr
```

### Access application web UI (port forwarding)
```bash
kubectl port-forward -n media svc/sonarr 8989:80
# Then access http://localhost:8989
```

### Check persistent volume mounts
```bash
kubectl get pvc -n media
kubectl describe pvc media-nfs -n media
```

## Notes

- Update the NFS server IP and path in `pvc.yaml` if your NFS configuration is different
- The applications can be accessed via internal DNS names: `sonarr.media.svc.cluster.local`, etc.
- Ensure proper RBAC permissions are configured if using RBAC
- Consider adding Ingress manifests for external access to the applications
- Backup your configuration PVCs regularly
