# NFS Configuration Guide

## Overview

The media *arr apps deployment uses an external NFS server for all persistent storage. This document outlines the required NFS configuration and directory structure.

## NFS Server Details

- **Server IP**: `10.11.11.46`
- **Base Path**: `/srv/vault`
- **Protocol**: NFSv4 (recommended) or NFSv3
- **Access Mode**: ReadWriteMany (RWX)

## Required Directory Structure

You **must create these directories ahead of time** on your NFS server:

```
/srv/vault/
├── config/
│   ├── sonarr/
│   ├── radarr/
│   └── lidarr/
├── downloads/
├── movies/
└── music/
```

### Directory Details

| Directory | Purpose | Size Recommendation | Kubernetes PVC |
|-----------|---------|---------------------|-----------------|
| `/srv/vault/config/sonarr/` | Sonarr application configuration | 10Gi | `sonarr-config` |
| `/srv/vault/config/radarr/` | Radarr application configuration | 10Gi | `radarr-config` |
| `/srv/vault/config/lidarr/` | Lidarr application configuration | 10Gi | `lidarr-config` |
| `/srv/vault/downloads/` | Download staging directory | 500Gi | `media-downloads` |
| `/srv/vault/movies/` | TV shows and movies storage | 1000Gi | `media-tv` & `media-movies` |
| `/srv/vault/music/` | Music library storage | 500Gi | `media-music` |

## NFS Server Setup

### On Your NFS Server (Linux)

Create the directory structure:

```bash
mkdir -p /srv/vault/{config/{sonarr,radarr,lidarr},downloads,movies,music}
```

Set proper permissions (adjust user/group as needed for your environment):

```bash
# Set ownership and permissions
sudo chown -R nobody:nogroup /srv/vault
sudo chmod -R 777 /srv/vault

# Or more restrictively (example with uid/gid 1000):
sudo chown -R 1000:1000 /srv/vault
sudo chmod -R 755 /srv/vault
```

### Export Configuration

Add to your NFS server's `/etc/exports`:

```
/srv/vault *(rw,sync,no_subtree_check,no_root_squash)
```

Then reload the NFS daemon:

```bash
sudo systemctl restart nfs-kernel-server
# or
sudo systemctl restart nfs-server
```

Verify exports:

```bash
exportfs -v
```

## Kubernetes Configuration

The deployment uses direct NFS PersistentVolumes (not dynamic provisioning) with the following structure:

### PersistentVolumes

- `media-config-nfs-pv` → `/srv/vault/config` (100Gi capacity)
- `media-downloads-nfs-pv` → `/srv/vault/downloads` (500Gi capacity)
- `media-tv-nfs-pv` → `/srv/vault/movies` (1000Gi capacity)
- `media-movies-nfs-pv` → `/srv/vault/movies` (1000Gi capacity)
- `media-music-nfs-pv` → `/srv/vault/music` (500Gi capacity)

### PersistentVolumeClaims

Each application has its own config PVC bound to the config NFS volume:
- `sonarr-config` → mounts to `/config` in Sonarr pod
- `radarr-config` → mounts to `/config` in Radarr pod
- `lidarr-config` → mounts to `/config` in Lidarr pod

Media PVCs are shared by all applications as needed:
- `media-downloads` → `/downloads`
- `media-tv` → `/tv`
- `media-movies` → `/movies`
- `media-music` → `/music`

## Verification

### From Kubernetes Cluster

Check that NFS volumes are accessible:

```bash
# List persistent volumes
kubectl get pv

# Check PVC status
kubectl get pvc -n media

# Verify NFS mount points in a running pod
kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv

# Test NFS connectivity
kubectl exec -it -n media deployment/sonarr -- ls -la /config
kubectl exec -it -n media deployment/sonarr -- ls -la /downloads
kubectl exec -it -n media deployment/sonarr -- ls -la /tv
```

### From Your NFS Server

Check which clients are connected:

```bash
showmount -a 10.11.11.46
```

## Troubleshooting

### NFS Connection Issues

If Kubernetes pods cannot mount the NFS volumes:

1. **Verify NFS server is accessible from cluster nodes**:
   ```bash
   # From a Kubernetes node
   showmount -e 10.11.11.46
   ```

2. **Check firewall rules**: Ensure NFS ports (111, 2049) are open between your cluster nodes and NFS server

3. **Test manual mount**:
   ```bash
   # From a cluster node (requires nfs-utils)
   mkdir -p /mnt/test
   sudo mount -t nfs 10.11.11.46:/srv/vault /mnt/test
   ls /mnt/test
   sudo umount /mnt/test
   ```

### Permission Issues

If applications cannot write to NFS:

1. Check directory permissions on NFS server:
   ```bash
   ls -la /srv/vault/config/sonarr/
   ```

2. Check PUID/PGID in application ConfigMaps (should be `1000:1000`)

3. Ensure NFS export allows write access

### Storage Quota Issues

If pods fail due to storage quota:

1. Check available space on NFS server:
   ```bash
   df -h /srv/vault
   ```

2. Increase directory quotas or NFS export sizes if needed

## Adding More Applications

When adding new *arr applications (e.g., Readarr, Prowlarr):

1. Create a new directory on NFS: `/srv/vault/config/<app-name>/`
2. Create corresponding PV and PVC in `pvc.yaml`
3. Reference the PVC in the application deployment
4. Ensure PUID/PGID matches other applications for consistent permissions

## Security Considerations

⚠️ **Note**: The current NFS configuration uses `no_root_squash` for simplicity. In production, consider:

- Using `root_squash` and setting appropriate ownership
- Restricting NFS exports to specific IP ranges
- Using NFS v4 with Kerberos authentication
- Implementing network segmentation/firewall rules
- Regular backups of `/srv/vault` contents

## Performance Notes

- **ReadWriteMany** volumes allow multiple pods to access simultaneously
- Consider network bandwidth limitations for large media libraries
- For large concurrent downloads, ensure adequate NFS server resources
- Monitor NFS server CPU/disk I/O, especially during transcoding operations
