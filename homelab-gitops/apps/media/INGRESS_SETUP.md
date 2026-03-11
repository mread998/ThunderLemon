# Accessing Your Media Apps - Ingress Setup

## 🎯 What Was Added

Created 5 ingress resources for your applications:
- **sonarr-ingress.yaml** → sonarr.local
- **radarr-ingress.yaml** → radarr.local
- **lidarr-ingress.yaml** → lidarr.local
- **bazarr-ingress.yaml** → bazarr.local
- **prowlarr-ingress.yaml** → prowlarr.local

All ingress files have been added to `base/kustomization.yaml`.

## 🌐 Accessing Your Applications

### Method 1: Using Traefik (Recommended)

Your k3s cluster comes with Traefik ingress controller pre-installed. The ingress resources automatically route traffic to your services.

#### Option A: Via DNS (Local Network)

Add these entries to your **hosts file**:

**Windows**: `C:\Windows\System32\drivers\etc\hosts`
```
<your-k3s-node-ip> sonarr.local
<your-k3s-node-ip> radarr.local
<your-k3s-node-ip> lidarr.local
<your-k3s-node-ip> bazarr.local
<your-k3s-node-ip> prowlarr.local
```

**Linux/Mac**: `/etc/hosts`
```
<your-k3s-node-ip> sonarr.local
<your-k3s-node-ip> radarr.local
<your-k3s-node-ip> lidarr.local
<your-k3s-node-ip> bazarr.local
<your-k3s-node-ip> prowlarr.local
```

Then access:
- http://sonarr.local
- http://radarr.local
- http://lidarr.local
- http://bazarr.local
- http://prowlarr.local

#### Option B: Via Traefik Dashboard

Find your Traefik service:
```powershell
kubectl get svc -n kube-system | grep traefik
```

Port-forward to it:
```powershell
kubectl port-forward -n kube-system svc/traefik 8080:8080 &
```

Access Traefik dashboard: http://localhost:8080/dashboard/

### Method 2: Port Forwarding (Quick Access)

If you don't want to modify your hosts file, use port forwarding:

```powershell
# In separate terminal windows:
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

## 🔍 Verify Ingress Status

Check if ingress resources are created:
```powershell
kubectl get ingress -n media
```

Expected output:
```
NAME       CLASS    HOSTS          ADDRESS   PORTS   AGE
bazarr     <none>   bazarr.local   <IP>      80      2m
lidarr     <none>   lidarr.local   <IP>      80      2m
prowlarr   <none>   prowlarr.local <IP>      80      2m
radarr     <none>   radarr.local   <IP>      80      2m
sonarr     <none>   sonarr.local   <IP>      80      2m
```

Check ingress details:
```powershell
kubectl describe ingress sonarr -n media
```

## ⚙️ Deploy Changes

Apply the updated manifests with ingress:

```powershell
# Redeploy with new ingress resources
kubectl apply -k homelab-gitops/apps/media/base/

# Or with Kustomize
kubectl apply -k homelab-gitops/apps/media/overlays/prod/
```

## 🐛 Troubleshooting 404 Errors

### Issue 1: Ingress Has No ADDRESS
```powershell
kubectl get ingress -n media
```

If ADDRESS column is empty, Traefik might not have picked up the ingress yet.

**Solution**:
```powershell
# Restart Traefik
kubectl rollout restart deployment/traefik -n kube-system

# Wait a few seconds and check again
kubectl get ingress -n media
```

### Issue 2: Host Not Resolving
Make sure you added entries to your **hosts file**.

**Windows**:
```powershell
# Edit as Administrator
notepad C:\Windows\System32\drivers\etc\hosts
```

Add lines:
```
10.11.11.x sonarr.local
10.11.11.x radarr.local
10.11.11.x lidarr.local
10.11.11.x bazarr.local
10.11.11.x prowlarr.local
```

(Replace `10.11.11.x` with your k3s node IP)

### Issue 3: Still Getting 404

Check if the ingress is properly configured:
```powershell
# Check ingress resource
kubectl get ingress -n media -o yaml

# Check if services exist and are running
kubectl get svc -n media

# Check if pods are running
kubectl get pods -n media

# Check logs
kubectl logs -n media deployment/sonarr
```

### Issue 4: Services Returning 404

If the ingress exists but services return 404, the application might not be serving at the root path.

**Solution**: Add URL prefix to your service if the app expects it:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sonarr
  namespace: media
spec:
  rules:
    - host: sonarr.local
      http:
        paths:
          - path: /sonarr  # Add path prefix if app needs it
            pathType: Prefix
            backend:
              service:
                name: sonarr
                port:
                  number: 80
```

## 🔄 Updating Hostnames

If you want to use different hostnames (e.g., `media-sonarr.example.com`), edit the ingress files:

```yaml
spec:
  rules:
    - host: media-sonarr.example.com  # Change this
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: sonarr
                port:
                  number: 80
```

Then:
```powershell
kubectl apply -f homelab-gitops/apps/media/base/sonarr-ingress.yaml
```

## 📋 Current Configuration

| App | Hostname | Port | Method |
|-----|----------|------|--------|
| Sonarr | sonarr.local | 80 | Ingress |
| Radarr | radarr.local | 80 | Ingress |
| Lidarr | lidarr.local | 80 | Ingress |
| Bazarr | bazarr.local | 80 | Ingress |
| Prowlarr | prowlarr.local | 80 | Ingress |

## 🎯 Next Steps

1. **Apply the updated manifests**:
   ```powershell
   kubectl apply -k homelab-gitops/apps/media/base/
   ```

2. **Add hosts file entries** (if not using port-forward)

3. **Verify ingress is created**:
   ```powershell
   kubectl get ingress -n media
   ```

4. **Access your app**:
   - Via ingress: http://sonarr.local (after hosts file update)
   - Via port-forward: http://localhost:8989

5. **Configure your applications** (add indexers, providers, etc.)

## 💡 Pro Tips

- **Keep terminal windows open** for port-forward to stay active
- **Use ingress for production**, port-forward for quick testing
- **Check Traefik dashboard** to see all ingress routes being served
- **Monitor ingress logs** if routes aren't working:
  ```powershell
  kubectl logs -n kube-system -l app=traefik --tail=50
  ```

---

**Your ingress is now ready! Access your media apps without 404 errors!** 🎉
