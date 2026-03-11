#!/bin/bash
# Quick Recovery Script - Re-deploy Media Apps with Fixed PV/PVC

echo "=== Media Deployment Recovery Script ==="
echo ""

# Step 1: Delete namespace (cleans up broken PVCs)
echo "Step 1: Deleting media namespace (PVs are retained)..."
kubectl delete namespace media
sleep 5

# Step 2: Delete stuck PVs if they exist
echo "Step 2: Checking for and deleting stuck PVs..."
for pv in media-config-nfs-pv media-downloads-nfs-pv media-tv-nfs-pv media-movies-nfs-pv media-music-nfs-pv; do
  if kubectl get pv $pv &> /dev/null; then
    echo "  Deleting $pv..."
    kubectl delete pv $pv
  fi
done

sleep 5

# Step 3: Re-deploy with fixed configuration
echo "Step 3: Re-deploying with fixed PV/PVC configuration..."
kubectl apply -k homelab-gitops/apps/media/overlays/prod

sleep 10

# Step 4: Verify PVs are created
echo ""
echo "Step 4: Verifying PersistentVolumes..."
echo "=========================================="
kubectl get pv | grep media
echo ""

# Step 5: Verify PVCs are bound
echo "Step 5: Verifying PersistentVolumeClaims..."
echo "============================================"
kubectl get pvc -n media
echo ""

# Step 6: Check pod status
echo "Step 6: Checking pod status..."
echo "=============================="
kubectl get pods -n media
echo ""

# Step 7: Wait and verify again
echo "Step 7: Waiting 30 seconds for pods to initialize..."
sleep 30
echo ""
echo "Final pod status:"
kubectl get pods -n media -o wide
echo ""

# Step 8: Summary
echo "=========================================="
echo "Recovery Summary:"
echo "=========================================="
echo ""
echo "PV/PVC Status:"
kubectl get pv,pvc -n media -o wide
echo ""
echo "To check if all PVCs are Bound:"
echo "  kubectl get pvc -n media"
echo ""
echo "To check pod logs:"
echo "  kubectl logs -n media deployment/sonarr"
echo ""
echo "To access web UIs:"
echo "  kubectl port-forward -n media svc/sonarr 8989:80"
echo "  kubectl port-forward -n media svc/radarr 7878:80"
echo "  kubectl port-forward -n media svc/lidarr 8686:80"
echo "  kubectl port-forward -n media svc/bazarr 6767:80"
echo "  kubectl port-forward -n media svc/prowlarr 9696:80"
echo ""
echo "✅ Recovery script complete!"
