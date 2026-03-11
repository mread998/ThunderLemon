# Architecture Diagram - nfs-rwx Provisioning

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │           media Namespace                                  │  │
│  │  ┌──────────┬──────────┬──────────┬──────────┬──────────┐ │  │
│  │  │  Sonarr  │  Radarr  │  Lidarr  │  Bazarr  │ Prowlarr │ │  │
│  │  │  Pod     │  Pod     │  Pod     │  Pod     │  Pod     │ │  │
│  │  └─────┬────┴─────┬────┴─────┬────┴─────┬────┴────┬──────┘ │  │
│  │        │          │          │          │         │        │  │
│  │  ┌─────▼──┐  ┌────▼───┐  ┌──▼───┐  ┌───▼───┐  ┌──▼────┐   │  │
│  │  │ sonarr-│  │ radarr-│  │lidarr│  │bazarr │  │prowlarr   │   │  │
│  │  │ config │  │ config │  │config│  │config │  │config  │   │  │
│  │  │  PVC   │  │  PVC   │  │ PVC  │  │ PVC   │  │ PVC    │   │  │
│  │  │ (10Gi) │  │ (10Gi) │  │(10Gi)   │(5Gi)  │  │(5Gi)   │   │  │
│  │  └────┬───┘  └────┬───┘  └──┬───┘  └───┬───┘  └────┬───┘   │  │
│  │       │           │         │          │           │       │  │
│  │  ┌────▼───────────▼─────────▼──────────▼───────────▼────┐  │  │
│  │  │   StorageClass: nfs-rwx                              │  │  │
│  │  │   (NFS CSI Driver)                                    │  │  │
│  │  │                                                       │  │  │
│  │  │   Provisioner: nfs.csi.k8s.io                        │  │  │
│  │  │   Reclaim Policy: Retain                             │  │  │
│  │  │   Binding Mode: Immediate                            │  │  │
│  │  └────┬──────────────────────────────────────────────┬──┘  │  │
│  │       │                                              │     │  │
│  │  ┌────▼────────────┐  ┌──────────────────────────┬──▼─────┐│  │
│  │  │ media-downloads │  │ media-tv │ media-movies ││ media- ││  │
│  │  │   PVC (500Gi)   │  │   PVC    │   PVC        ││ music  ││  │
│  │  │                 │  │(1000Gi)  │  (1000Gi)    ││PVC    ││  │
│  │  │                 │  │          │              ││(500Gi)││  │
│  │  └────┬────────────┘  └────┬─────┴──────────┬───┘└───┬───┘│  │
│  │       │                    │                │        │    │  │
│  │  ┌────▼────────────────────▼────────────────▼────────▼────┐│  │
│  │  │        Dynamically Created PersistentVolumes           ││  │
│  │  │        (One per PVC - Automatic)                       ││  │
│  │  └────┬─────────────────────────────────────────────────┬─┘│  │
│  └───────┼──────────────────────────────────────────────────┼──┘  │
│          │                                                  │      │
└──────────┼──────────────────────────────────────────────────┼──────┘
           │                                                  │
           │              NFS Server                          │
      ┌────▼──────────────────────────────────────────────┬──▼──┐
      │  10.11.11.46                                       │     │
      │  /srv/vault/                                       │     │
      │  ├── config/                                       │     │
      │  │   ├── pvc-sonarr-*/                             │     │
      │  │   ├── pvc-radarr-*/                             │     │
      │  │   ├── pvc-lidarr-*/                             │     │
      │  │   ├── pvc-bazarr-*/                             │     │
      │  │   └── pvc-prowlarr-*/                           │     │
      │  ├── downloads/                                     │     │
      │  │   └── pvc-*/                                    │     │
      │  ├── tv/                                            │     │
      │  │   └── pvc-*/                                    │     │
      │  ├── movies/                                        │     │
      │  │   └── pvc-*/                                    │     │
      │  └── music/                                         │     │
      │      └── pvc-*/                                    │     │
      └─────────────────────────────────────────────────────┘
```

---

## Data Flow - Application to NFS

```
Application Pod (e.g., Sonarr)
    │
    ├─ Mounts: /config ← sonarr-config PVC
    │              │
    │              └─→ StorageClass: nfs-rwx
    │                     │
    │                     └─→ Creates PV automatically
    │                            │
    │                            └─→ NFS CSI Driver
    │                                   │
    │                                   └─→ Mounts NFS
    │                                          │
    │                                          └─→ 10.11.11.46:/srv/vault/config
    │
    ├─ Mounts: /downloads ← media-downloads PVC
    │              │
    │              └─→ StorageClass: nfs-rwx
    │                     │
    │                     └─→ Creates PV automatically
    │                            │
    │                            └─→ NFS CSI Driver
    │                                   │
    │                                   └─→ Mounts NFS
    │                                          │
    │                                          └─→ 10.11.11.46:/srv/vault/downloads
    │
    ├─ Mounts: /tv ← media-tv PVC
    │              │
    │              └─→ StorageClass: nfs-rwx
    │                     │
    │                     └─→ Creates PV automatically
    │                            │
    │                            └─→ NFS CSI Driver
    │                                   │
    │                                   └─→ Mounts NFS
    │                                          │
    │                                          └─→ 10.11.11.46:/srv/vault/tv
    │
    └─ Mounts: /movies, /music (same pattern)
```

---

## Binding Process - Old vs New

### BEFORE (Static PVs - Complex)
```
User creates PVC
       │
       ├─ PVC says: "I need a volume with label pv-type=nfs-config"
       │
       └─→ Kubernetes looks for matching PV
              │
              ├─ PV has label pv-type=nfs-config? ✓
              ├─ PVC name matches volumeName? ✓
              ├─ StorageClass matches? ✓
              ├─ Size request ≤ PV capacity? ✓
              │
              └─ ✓ BIND
              
              BUT: If ANY check fails → ✗ PENDING (stuck forever)
                  ├─ Label typo → Pending
                  ├─ Name mismatch → Pending
                  ├─ Size mismatch → Pending
                  ├─ StorageClass mismatch → Pending
                  └─ Only 1 PVC can bind per PV → 4 Pending if 5 PVCs
```

### AFTER (Dynamic - Simple)
```
User creates PVC
       │
       ├─ PVC says: "I need 10Gi via storageClass: nfs-rwx"
       │
       └─→ Kubernetes triggers nfs-rwx StorageClass
              │
              └─→ NFS CSI Driver
                     │
                     ├─ Create unique PV ✓
                     ├─ Configure NFS mount ✓
                     ├─ Bind PVC to PV ✓
                     │
                     └─ ✓ BOUND (in seconds)
                     
              No complex matching logic
              No label selectors
              No name matching
              No manual configuration
              
              Each PVC gets its own PV automatically!
```

---

## Resource Creation Flow

```
┌─────────────────────────────────────┐
│  kubectl apply -k base/             │
└──────────────┬──────────────────────┘
               │
      ┌────────▼────────┐
      │ Kustomization   │
      │ processes       │
      └────────┬────────┘
               │
   ┌───────────┼───────────┐
   │           │           │
   ▼           ▼           ▼
Namespace   PVCs (9)   Deployments (5)
  media    sonarr-config    Sonarr
          radarr-config     Radarr
          lidarr-config     Lidarr
          bazarr-config     Bazarr
          prowlarr-config   Prowlarr
          media-downloads   (+ ConfigMaps & Services)
          media-tv
          media-movies
          media-music
               │
               ▼
        StorageClass
           nfs-rwx
               │
               ▼
        NFS CSI Driver
               │
      ┌────────┴────────┐
      │                 │
      ▼                 ▼
  Create PVs      Configure NFS
  (automatic)     (automatic)
      │                 │
      └────────┬────────┘
               │
               ▼
        PVCs Bound
        (instant)
               │
               ▼
        Pods Start
        (can mount)
               │
               ▼
        NFS Shares
        Available
```

---

## Pod Mount Points

```
pod: sonarr
├── /config (from sonarr-config PVC)
│   └─ mounted at /srv/vault/config/pvc-sonarr-xxx
├── /downloads (from media-downloads PVC)
│   └─ mounted at /srv/vault/downloads/pvc-xxx
├── /tv (from media-tv PVC)
│   └─ mounted at /srv/vault/tv/pvc-xxx
├── /movies (from media-movies PVC)
│   └─ mounted at /srv/vault/movies/pvc-xxx
└── /music (from media-music PVC)
    └─ mounted at /srv/vault/music/pvc-xxx

pod: radarr (same pattern, different PVC for config)
├── /config (from radarr-config PVC)
│   └─ mounted at /srv/vault/config/pvc-radarr-xxx
├── /downloads (from media-downloads PVC - SHARED)
│   └─ mounted at /srv/vault/downloads/pvc-xxx
├── /tv (from media-tv PVC - SHARED)
│   └─ mounted at /srv/vault/tv/pvc-xxx
├── /movies (from media-movies PVC - SHARED)
│   └─ mounted at /srv/vault/movies/pvc-xxx
└── /music (from media-music PVC - SHARED)
    └─ mounted at /srv/vault/music/pvc-xxx

... (same for lidarr, bazarr, prowlarr)
```

---

## Storage Tier Breakdown

### Tier 1: Application Configuration (Separate per App)
```
sonarr-config (10Gi)     → /srv/vault/config/pvc-sonarr-xxx/
radarr-config (10Gi)     → /srv/vault/config/pvc-radarr-xxx/
lidarr-config (10Gi)     → /srv/vault/config/pvc-lidarr-xxx/
bazarr-config (5Gi)      → /srv/vault/config/pvc-bazarr-xxx/
prowlarr-config (5Gi)    → /srv/vault/config/pvc-prowlarr-xxx/
                            Total: 40Gi for configs
```

### Tier 2: Shared Media (Accessed by All Apps)
```
media-downloads (500Gi)  → /srv/vault/downloads/pvc-xxx/
media-tv (1000Gi)        → /srv/vault/tv/pvc-xxx/
media-movies (1000Gi)    → /srv/vault/movies/pvc-xxx/
media-music (500Gi)      → /srv/vault/music/pvc-xxx/
                            Total: 3000Gi for media
```

---

## Service Exposure

```
┌─────────────────────────────────────────────────────────┐
│           Kubernetes Services (ClusterIP)               │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  sonarr:80          ──────→  sonarr Pod :8989         │
│  radarr:80          ──────→  radarr Pod :7878        │
│  lidarr:80          ──────→  lidarr Pod :8686        │
│  bazarr:80          ──────→  bazarr Pod :6767        │
│  prowlarr:80        ──────→  prowlarr Pod :9696      │
│                                                         │
└─────────────────────────────────────────────────────────┘
        │
        └──→ Accessible within cluster
             (use kubectl port-forward to access externally)
```

---

## Summary

✅ **9 PVCs** request storage from nfs-rwx StorageClass  
✅ **NFS CSI Driver** automatically creates matching PVs  
✅ **PVC-to-PV binding** happens instantly  
✅ **NFS mounts** configured automatically  
✅ **Pods** can mount and access storage immediately  

No manual configuration, no label matching, no error-prone bindings!
