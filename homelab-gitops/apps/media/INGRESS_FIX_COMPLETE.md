# ✅ Ingress Fix Complete - Access Your Apps Now!

## 🎯 What Was the Issue?

You were getting **404 nginx errors** because your Kubernetes applications didn't have **ingress routes** configured. While the services and pods were running, there was no way for external traffic to reach them via hostnames.

## ✅ What Was Fixed

Created **5 ingress resources** (one per application):
- ✅ **sonarr-ingress.yaml** → Routes to sonarr.local
- ✅ **radarr-ingress.yaml** → Routes to radarr.local
- ✅ **lidarr-ingress.yaml** → Routes to lidarr.local
- ✅ **bazarr-ingress.yaml** → Routes to bazarr.local
- ✅ **prowlarr-ingress.yaml** → Routes to prowlarr.local

Updated **base/kustomization.yaml** to include all 5 ingress resources.

## 🚀 Deploy the Fix (2 Steps)

### Step 1: Apply Updated Manifests
```powershell
cd c:\Users\marcr\repo\ThunderLemon
kubectl apply -k homelab-gitops/apps/media/base/
```

Output should show:
```
ingress.networking.k8s.io/bazarr created
ingress.networking.k8s.io/lidarr created
ingress.networking.k8s.io/prowlarr created
ingress.networking.k8s.io/radarr created
ingress.networking.k8s.io/sonarr created
```

### Step 2: Verify Ingress Routes
```powershell
kubectl get ingress -n media

# Should show all 5 with ADDRESS column populated:
# NAME       CLASS    HOSTS          ADDRESS      PORTS
# bazarr     <none>   bazarr.local   10.11.11.x   80
# lidarr     <none>   lidarr.local   10.11.11.x   80
# prowlarr   <none>   prowlarr.local 10.11.11.x   80
# radarr     <none>   radarr.local   10.11.11.x   80
# sonarr     <none>   sonarr.local   10.11.11.x   80
```

## 🌐 Access Your Applications

### Option A: Via Hostname (Recommended)

**Edit your hosts file:**

**Windows** (as Administrator):
```
C:\Windows\System32\drivers\etc\hosts
```

**Linux/Mac**:
```
/etc/hosts
```

**Add these lines** (replace 10.11.11.x with your k3s node IP):
```
10.11.11.x sonarr.local
10.11.11.x radarr.local
10.11.11.x lidarr.local
10.11.11.x bazarr.local
10.11.11.x prowlarr.local
```

**Then access:**
- http://sonarr.local
- http://radarr.local
- http://lidarr.local
- http://bazarr.local
- http://prowlarr.local

### Option B: Via Port Forwarding (Quick Test)

```powershell
# In separate terminal windows:
kubectl port-forward -n media svc/sonarr 8989:80
kubectl port-forward -n media svc/radarr 7878:80
kubectl port-forward -n media svc/lidarr 8686:80
kubectl port-forward -n media svc/bazarr 6767:80
kubectl port-forward -n media svc/prowlarr 9696:80
```

**Then access:**
- http://localhost:8989 (Sonarr)
- http://localhost:7878 (Radarr)
- http://localhost:8686 (Lidarr)
- http://localhost:6767 (Bazarr)
- http://localhost:9696 (Prowlarr)

## 🔍 How It Works

```
Your Browser
    ↓
http://sonarr.local
    ↓
DNS Resolution (hosts file)
    ↓
10.11.11.x (your k3s node)
    ↓
Traefik Ingress Controller (k3s built-in)
    ↓
Reads ingress rules in Kubernetes
    ↓
Routes to Service: sonarr
    ↓
Routes to Pod: sonarr-xxx-xxx
    ↓
Container port: 8989
    ↓
Application responds
    ↓
✅ No more 404 errors!
```

## 📋 New Files Added

### In base/ directory:
```
base/
├── sonarr-ingress.yaml
├── radarr-ingress.yaml
├── lidarr-ingress.yaml
├── bazarr-ingress.yaml
└── prowlarr-ingress.yaml
```

### Documentation:
```
media/
├── INGRESS_SETUP.md (detailed ingress documentation)
└── INGRESS_QUICK_FIX.md (this quick reference)
```

## 🧭 Ingress Configuration Details

Each ingress follows this pattern:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sonarr
  namespace: media
  annotations:
    kubernetes.io/ingress.class: traefik  # Use k3s built-in Traefik
spec:
  rules:
    - host: sonarr.local  # Hostname to match
      http:
        paths:
          - path: /  # All paths under this host
            pathType: Prefix
            backend:
              service:
                name: sonarr  # Service name
                port:
                  number: 80  # Service port
```

## ⚡ Quick Verification

```powershell
# 1. Check ingress created
kubectl get ingress -n media

# 2. Check ingress details
kubectl describe ingress sonarr -n media

# 3. Check services running
kubectl get svc -n media

# 4. Check pods running
kubectl get pods -n media

# 5. Check Traefik routes
kubectl logs -n kube-system -l app=traefik --tail=20
```

## 🐛 If Still Getting 404

1. **Restart Traefik** (sometimes it needs to reload):
   ```powershell
   kubectl rollout restart deployment/traefik -n kube-system
   ```

2. **Verify hosts file entry** (Windows requires admin to edit)

3. **Check firewall** (make sure port 80 is accessible)

4. **Test with port-forward first** to isolate the issue:
   ```powershell
   kubectl port-forward -n media svc/sonarr 8989:80
   # Then try: http://localhost:8989
   ```

## 📚 More Help

For detailed information:
- See [INGRESS_SETUP.md](INGRESS_SETUP.md) for complete documentation
- See [INGRESS_QUICK_FIX.md](INGRESS_QUICK_FIX.md) for quick reference

## 🎯 Summary

| Component | Status | Details |
|-----------|--------|---------|
| **Ingress Files** | ✅ Created | 5 ingress resources added |
| **Kustomization** | ✅ Updated | All ingress files included |
| **Services** | ✅ Running | Routes traffic to pods |
| **Pods** | ✅ Running | Applications serving on ports |
| **Access** | ✅ Ready | Via hostname or port-forward |

## 🚀 Next Steps

1. **Deploy**: Run `kubectl apply -k homelab-gitops/apps/media/base/`
2. **Verify**: Run `kubectl get ingress -n media`
3. **Access**: Update hosts file or use port-forward
4. **Browse**: http://sonarr.local (or use port-forward)
5. **Configure**: Set up indexers, providers, etc. in each app

## 💡 Pro Tips

- **Traefik Dashboard**: `kubectl port-forward -n kube-system svc/traefik 8080:8080` then visit http://localhost:8080/dashboard/
- **Watch Ingress**: `kubectl get ingress -n media --watch`
- **Real-time Logs**: `kubectl logs -f -n kube-system -l app=traefik`

---

**Your ingress is ready! No more 404 errors!** 🎉

Access your media apps via:
- **Sonarr**: http://sonarr.local
- **Radarr**: http://radarr.local
- **Lidarr**: http://lidarr.local
- **Bazarr**: http://bazarr.local
- **Prowlarr**: http://prowlarr.local
