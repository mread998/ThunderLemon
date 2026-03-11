# 🚀 Quick Fix: Deploy Ingress Now

## The Problem
You were getting 404 nginx errors because ingress routes weren't configured for your applications.

## The Solution
Created 5 ingress resources (sonarr, radarr, lidarr, bazarr, prowlarr) and updated kustomization.yaml.

## Deploy Now

### Step 1: Apply Updated Manifests
```powershell
# From your repo root
kubectl apply -k homelab-gitops/apps/media/base/

# Or if using overlays:
kubectl apply -k homelab-gitops/apps/media/overlays/prod/
```

### Step 2: Verify Ingress Created
```powershell
kubectl get ingress -n media

# Should show:
# NAME       CLASS    HOSTS          ADDRESS      PORTS   AGE
# bazarr     <none>   bazarr.local   10.11.11.x   80      10s
# lidarr     <none>   lidarr.local   10.11.11.x   80      10s
# prowlarr   <none>   prowlarr.local 10.11.11.x   80      10s
# radarr     <none>   radarr.local   10.11.11.x   80      10s
# sonarr     <none>   sonarr.local   10.11.11.x   80      10s
```

### Step 3: Choose Your Access Method

**Option A: Update Hosts File (Recommended)**

Get your k3s node IP:
```powershell
kubectl get nodes -o wide
```

Edit your hosts file (Windows):
```
C:\Windows\System32\drivers\etc\hosts
```

Add these lines (replace `10.11.11.x` with your node IP):
```
10.11.11.x sonarr.local
10.11.11.x radarr.local
10.11.11.x lidarr.local
10.11.11.x bazarr.local
10.11.11.x prowlarr.local
```

Then access:
- http://sonarr.local
- http://radarr.local
- http://lidarr.local
- http://bazarr.local
- http://prowlarr.local

**Option B: Port Forwarding (Quick Test)**

```powershell
kubectl port-forward -n media svc/sonarr 8989:80 &
kubectl port-forward -n media svc/radarr 7878:80 &
kubectl port-forward -n media svc/lidarr 8686:80 &
kubectl port-forward -n media svc/bazarr 6767:80 &
kubectl port-forward -n media svc/prowlarr 9696:80 &
```

Then access:
- http://localhost:8989 (Sonarr)
- http://localhost:7878 (Radarr)
- http://localhost:8686 (Lidarr)
- http://localhost:6767 (Bazarr)
- http://localhost:9696 (Prowlarr)

### Step 4: Done! ✅

You should now be able to access your applications without 404 errors.

## What Was Added

**New Files** (in base/):
- sonarr-ingress.yaml
- radarr-ingress.yaml
- lidarr-ingress.yaml
- bazarr-ingress.yaml
- prowlarr-ingress.yaml

**Updated Files**:
- base/kustomization.yaml (added 5 ingress resources)

## Troubleshooting

### Still Getting 404?

1. **Check ingress has ADDRESS**:
   ```powershell
   kubectl get ingress -n media
   ```
   If ADDRESS is blank, restart Traefik:
   ```powershell
   kubectl rollout restart deployment/traefik -n kube-system
   ```

2. **Check pods are running**:
   ```powershell
   kubectl get pods -n media
   ```

3. **Check services exist**:
   ```powershell
   kubectl get svc -n media
   ```

4. **Check Traefik logs**:
   ```powershell
   kubectl logs -n kube-system -l app=traefik --tail=20
   ```

## More Info

See [INGRESS_SETUP.md](INGRESS_SETUP.md) for detailed documentation.

---

**Quick Start**: Apply manifests → Update hosts file → Access http://sonarr.local ✅
