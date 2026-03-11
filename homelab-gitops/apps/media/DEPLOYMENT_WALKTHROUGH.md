# Complete Deployment Example

This document shows what happens when you deploy the media apps with nfs-rwx StorageClass.

## Before Deployment

```bash
$ kubectl get namespace media
Error from server (NotFound): namespaces "media" not found

$ kubectl get pvc -n media
Error from server (NotFound): namespaces "media" not found

$ kubectl get pv | grep media
No resources found
```

---

## Running the Deployment

### Option 1: Automated Script

```powershell
cd c:\Users\marcr\repo\ThunderLemon
powershell -ExecutionPolicy Bypass -File homelab-gitops/apps/media/deploy.ps1

==================================
Media Apps Deployment
Using nfs-rwx Storage Class
==================================

Step 1: Checking namespace...
✓ Fresh start - no existing namespace

Step 2: Verifying nfs-rwx storage class...
✓ nfs-rwx storage class found
NAME     PROVISIONER           RECLAIMPOLICY   VOLUMEBINDINGMODE
nfs-rwx  nfs.csi.k8s.io        Retain          Immediate

Step 3: Applying base manifests...
namespace/media created
persistentvolumeclaim/sonarr-config created
persistentvolumeclaim/radarr-config created
persistentvolumeclaim/lidarr-config created
persistentvolumeclaim/bazarr-config created
persistentvolumeclaim/prowlarr-config created
persistentvolumeclaim/media-downloads created
persistentvolumeclaim/media-tv created
persistentvolumeclaim/media-movies created
persistentvolumeclaim/media-music created
configmap/sonarr-config created
deployment.apps/sonarr created
service/sonarr created
... (all 15 resources created)

✓ Base manifests applied

Step 4: Waiting for pods to initialize...

Step 5: Checking PVC binding...

PersistentVolumeClaims:
NAME               STATUS   VOLUME                                     CAPACITY
sonarr-config      Bound    pvc-12345678-1234-1234-1234-123456789012   10Gi
radarr-config      Bound    pvc-abcdefgh-abcd-abcd-abcd-abcdefghijkl   10Gi
lidarr-config      Bound    pvc-qwertyui-qwer-qwer-qwer-qwertyuiopqwe  10Gi
bazarr-config      Bound    pvc-asdfghjk-asdf-asdf-asdf-asdfghjklzxcv  5Gi
prowlarr-config    Bound    pvc-zxcvbnm0-zxcv-zxcv-zxcv-zxcvbnmqwerty  5Gi
media-downloads    Bound    pvc-09876543-0987-0987-0987-098765432109   500Gi
media-tv           Bound    pvc-jhgfdsa0-jhgf-jhgf-jhgf-jhgfdsapqwert  1000Gi
media-movies       Bound    pvc-qazwsx12-qazw-qazw-qazw-qazwsx12edcrf  1000Gi
media-music        Bound    pvc-edcrfvgt-edcr-edcr-edcr-edcrfvgtyhujk  500Gi

✓ All PVCs bound successfully (9/9)

Step 6: Checking pod status...

Pods:
NAME                      READY   STATUS    RESTARTS   AGE
sonarr-6f8d9c4c7-x9p2k   1/1     Running   0          2m
radarr-5c3d2b1a9-p8q7r   1/1     Running   0          2m
lidarr-7b2e5f9c1-m6l3k   1/1     Running   0          2m
bazarr-4a1e3d2c5-n5j2h   1/1     Running   0          2m
prowlarr-3f7e2a1d4-o4i1g 1/1     Running   0          2m

Running pods: 5/5

Step 7: Apply production overlay? (y/n)
n
Skipping production overlay

Step 8: Final status check...

Namespace:
NAME   STATUS   AGE
media  Active   3m

PersistentVolumeClaims:
NAME               STATUS   VOLUME                                     CAPACITY   STORAGECLASS
sonarr-config      Bound    pvc-12345678-1234-1234-1234-123456789012   10Gi       nfs-rwx
radarr-config      Bound    pvc-abcdefgh-abcd-abcd-abcd-abcdefghijkl   10Gi       nfs-rwx
lidarr-config      Bound    pvc-qwertyui-qwer-qwer-qwer-qwertyuiopqwe  10Gi       nfs-rwx
bazarr-config      Bound    pvc-asdfghjk-asdf-asdf-asdf-asdfghjklzxcv  5Gi        nfs-rwx
prowlarr-config    Bound    pvc-zxcvbnm0-zxcv-zxcv-zxcv-zxcvbnmqwerty  5Gi        nfs-rwx
media-downloads    Bound    pvc-09876543-0987-0987-0987-098765432109   500Gi      nfs-rwx
media-tv           Bound    pvc-jhgfdsa0-jhgf-jhgf-jhgf-jhgfdsapqwert  1000Gi     nfs-rwx
media-movies       Bound    pvc-qazwsx12-qazw-qazw-qazw-qazwsx12edcrf  1000Gi     nfs-rwx
media-music        Bound    pvc-edcrfvgt-edcr-edcr-edcr-edcrfvgtyhujk  500Gi      nfs-rwx

Pods:
NAME                      READY   STATUS    RESTARTS   AGE
sonarr-6f8d9c4c7-x9p2k   1/1     Running   0          3m
radarr-5c3d2b1a9-p8q7r   1/1     Running   0          3m
lidarr-7b2e5f9c1-m6l3k   1/1     Running   0          3m
bazarr-4a1e3d2c5-n5j2h   1/1     Running   0          3m
prowlarr-3f7e2a1d4-o4i1g 1/1     Running   0          3m

Services:
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
sonarr    ClusterIP   10.43.123.45    <none>        80/TCP    3m
radarr    ClusterIP   10.43.123.46    <none>        80/TCP    3m
lidarr    ClusterIP   10.43.123.47    <none>        80/TCP    3m
bazarr    ClusterIP   10.43.123.48    <none>        80/TCP    3m
prowlarr  ClusterIP   10.43.123.49    <none>        80/TCP    3m

==================================
✓ Deployment Complete!
==================================

Next steps:
1. Check pod logs: kubectl logs -n media deployment/sonarr
2. Port forward: kubectl port-forward -n media svc/sonarr 8989:8989
3. Access UI: http://localhost:8989

Application Port Mappings:
  Sonarr (TV):      8989
  Radarr (Movies):  7878
  Lidarr (Music):   8686
  Bazarr (Subs):    6767
  Prowlarr (Index): 9696

Verify NFS mounts:
  kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv
```

---

## After Deployment - Verification

### Check PVs Created

```bash
$ kubectl get pv | grep pvc-

NAME                                       CAPACITY   ACCESSMODES   STORAGECLASS   STATUS   CLAIM
pvc-12345678-1234-1234-1234-123456789012   10Gi       RWX           nfs-rwx        Bound    media/sonarr-config
pvc-abcdefgh-abcd-abcd-abcd-abcdefghijkl   10Gi       RWX           nfs-rwx        Bound    media/radarr-config
pvc-qwertyui-qwer-qwer-qwer-qwertyuiopqwe  10Gi       RWX           nfs-rwx        Bound    media/lidarr-config
pvc-asdfghjk-asdf-asdf-asdf-asdfghjklzxcv  5Gi        RWX           nfs-rwx        Bound    media/bazarr-config
pvc-zxcvbnm0-zxcv-zxcv-zxcv-zxcvbnmqwerty  5Gi        RWX           nfs-rwx        Bound    media/prowlarr-config
pvc-09876543-0987-0987-0987-098765432109   500Gi      RWX           nfs-rwx        Bound    media/media-downloads
pvc-jhgfdsa0-jhgf-jhgf-jhgf-jhgfdsapqwert  1000Gi     RWX           nfs-rwx        Bound    media/media-tv
pvc-qazwsx12-qazw-qazw-qazw-qazwsx12edcrf  1000Gi     RWX           nfs-rwx        Bound    media/media-movies
pvc-edcrfvgt-edcr-edcr-edcr-edcrfvgtyhujk  500Gi      RWX           nfs-rwx        Bound    media/media-music

# All created automatically!
```

### Check NFS Mounts

```bash
$ kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv

10.11.11.46:/srv/vault/config/pvc-12345678-1234-1234-1234-123456789012   100Gi   50Gi    50Gi  50% /config
10.11.11.46:/srv/vault/downloads/pvc-09876543-0987-0987-0987-098765432109 500Gi  100Gi   400Gi  20% /downloads
10.11.11.46:/srv/vault/tv/pvc-jhgfdsa0-jhgf-jhgf-jhgf-jhgfdsapqwert     1000Gi  500Gi   500Gi  50% /tv
10.11.11.46:/srv/vault/movies/pvc-qazwsx12-qazw-qazw-qazw-qazwsx12edcrf 1000Gi  800Gi   200Gi  80% /movies
10.11.11.46:/srv/vault/music/pvc-edcrfvgt-edcr-edcr-edcr-edcrfvgtyhujk   500Gi  100Gi   400Gi  20% /music

# All NFS shares mounted!
```

### Check Application Health

```bash
# Check logs
$ kubectl logs -n media deployment/sonarr --tail=20
2026-03-11T12:00:00 INFO: Starting Sonarr v4.0.0.0
2026-03-11T12:00:01 INFO: Initializing database...
2026-03-11T12:00:05 INFO: Database initialized successfully
2026-03-11T12:00:10 INFO: Starting HTTP server on port 8989
2026-03-11T12:00:15 INFO: Application ready

# Check pod status
$ kubectl get pod -n media sonarr-6f8d9c4c7-x9p2k -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP            NODE      NOMINATED NODE
sonarr-6f8d9c4c7-x9p2k     1/1     Running   0          5m    10.42.0.50    k3s-node1 <none>

# Check resource usage
$ kubectl top pod -n media
NAME                      CPU(m)   MEMORY(Mi)
sonarr-6f8d9c4c7-x9p2k    45m      128Mi
radarr-5c3d2b1a9-p8q7r    40m      120Mi
lidarr-7b2e5f9c1-m6l3k    35m      100Mi
bazarr-4a1e3d2c5-n5j2h    25m      80Mi
prowlarr-3f7e2a1d4-o4i1g  30m      90Mi
```

---

## Accessing the Applications

### Port Forwarding

```bash
# Terminal 1: Sonarr
$ kubectl port-forward -n media svc/sonarr 8989:80
Forwarding from 127.0.0.1:8989 -> 8989
Forwarding from [::1]:8989 -> 8989

# Terminal 2: Radarr
$ kubectl port-forward -n media svc/radarr 7878:80
Forwarding from 127.0.0.1:7878 -> 7878
Forwarding from [::1]:7878 -> 7878

# Terminal 3: Lidarr
$ kubectl port-forward -n media svc/lidarr 8686:80
Forwarding from 127.0.0.1:8686 -> 8686
Forwarding from [::1]:8686 -> 8686

# Terminal 4: Bazarr
$ kubectl port-forward -n media svc/bazarr 6767:80
Forwarding from 127.0.0.1:6767 -> 6767
Forwarding from [::1]:6767 -> 6767

# Terminal 5: Prowlarr
$ kubectl port-forward -n media svc/prowlarr 9696:80
Forwarding from 127.0.0.1:9696 -> 9696
Forwarding from [::1]:9696 -> 9696
```

### Browser Access

```
Sonarr:    http://localhost:8989
Radarr:    http://localhost:7878
Lidarr:    http://localhost:8686
Bazarr:    http://localhost:6767
Prowlarr:  http://localhost:9696
```

---

## NFS Server Verification

### Check Directories Created

```bash
# SSH to NFS server
ssh user@10.11.11.46

# List created directories
$ ls -la /srv/vault/
drwxr-xr-x config
drwxr-xr-x downloads
drwxr-xr-x tv
drwxr-xr-x movies
drwxr-xr-x music

$ ls -la /srv/vault/config/
drwx------ pvc-12345678-1234-1234-1234-123456789012  (sonarr-config)
drwx------ pvc-abcdefgh-abcd-abcd-abcd-abcdefghijkl  (radarr-config)
drwx------ pvc-qwertyui-qwer-qwer-qwer-qwertyuiopqwe (lidarr-config)
drwx------ pvc-asdfghjk-asdf-asdf-asdf-asdfghjklzxcv (bazarr-config)
drwx------ pvc-zxcvbnm0-zxcv-zxcv-zxcv-zxcvbnmqwerty (prowlarr-config)

$ ls -la /srv/vault/downloads/
drwx------ pvc-09876543-0987-0987-0987-098765432109

$ ls -la /srv/vault/tv/
drwx------ pvc-jhgfdsa0-jhgf-jhgf-jhgf-jhgfdsapqwert

$ ls -la /srv/vault/movies/
drwx------ pvc-qazwsx12-qazw-qazw-qazw-qazwsx12edcrf

$ ls -la /srv/vault/music/
drwx------ pvc-edcrfvgt-edcr-edcr-edcr-edcrfvgtyhujk

# All created automatically by NFS CSI driver!
```

---

## Monitoring and Logs

### Watch Pods Starting

```bash
$ kubectl get pods -n media --watch
NAME                      READY   STATUS    RESTARTS   AGE
sonarr-6f8d9c4c7-x9p2k   0/1     Pending   0          0s
radarr-5c3d2b1a9-p8q7r   0/1     Pending   0          0s
lidarr-7b2e5f9c1-m6l3k   0/1     Pending   0          0s
bazarr-4a1e3d2c5-n5j2h   0/1     Pending   0          0s
prowlarr-3f7e2a1d4-o4i1g 0/1     Pending   0          0s

sonarr-6f8d9c4c7-x9p2k   0/1     ContainerCreating   0          2s
radarr-5c3d2b1a9-p8q7r   0/1     ContainerCreating   0          2s
... (containers start)

sonarr-6f8d9c4c7-x9p2k   1/1     Running             0          5s
radarr-5c3d2b1a9-p8q7r   1/1     Running             0          5s
... (all reach Running in ~30 seconds)
```

### Check Event Stream

```bash
$ kubectl get events -n media --sort-by='.lastTimestamp'

NAMESPACE   LAST SEEN   TYPE     REASON                OBJECT                      MESSAGE
media       5m          Normal   Scheduled             pod/sonarr-...              Successfully assigned media/sonarr... to k3s-node1
media       5m          Normal   SuccessfulAttachVolume pod/sonarr-...              AttachVolume.Attach succeeded for volume "pvc-..."
media       5m          Normal   Pulling               pod/sonarr-...              Pulling image "ghcr.io/linuxserver/sonarr:latest"
media       4m          Normal   Pulled                pod/sonarr-...              Successfully pulled image "ghcr.io/linuxserver/sonarr:latest"
media       4m          Normal   Created               pod/sonarr-...              Created container sonarr
media       4m          Normal   Started               pod/sonarr-...              Started container sonarr
... (similar for other pods)
```

---

## Success Indicators

### All Green ✅

```
✅ PVCs: All 9 Bound
✅ PVs: All 9 created automatically
✅ Pods: All 5 Running
✅ Services: All 5 created
✅ NFS mounts: All accessible
✅ Applications: All responding
✅ Logs: No errors
✅ Event stream: No warnings
```

### Deployment Time

```
Total deployment time: ~3-5 minutes
  ├─ Manifest parsing: ~5 seconds
  ├─ PVC creation: ~2 seconds
  ├─ StorageClass processing: ~3 seconds
  ├─ PV auto-creation: ~5 seconds
  ├─ NFS mount setup: ~10 seconds
  ├─ Pod scheduling: ~5 seconds
  ├─ Container pull: ~1 minute (depends on network)
  ├─ Container startup: ~30 seconds
  └─ Application init: ~30 seconds
```

---

## Summary

✅ **Deployment successful**  
✅ **All PVCs bound automatically**  
✅ **All pods running**  
✅ **NFS mounts functional**  
✅ **Applications accessible**  
✅ **Zero manual configuration needed**  

You're ready to configure the applications and start using them!
