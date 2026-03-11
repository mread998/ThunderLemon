# Quick Recovery Script - Re-deploy Media Apps with Fixed PV/PVC (PowerShell)

Write-Host "=== Media Deployment Recovery Script ===" -ForegroundColor Green
Write-Host ""

# Step 1: Delete namespace (cleans up broken PVCs)
Write-Host "Step 1: Deleting media namespace (PVs are retained)..." -ForegroundColor Yellow
kubectl delete namespace media
Start-Sleep -Seconds 5

# Step 2: Delete stuck PVs if they exist
Write-Host "Step 2: Checking for and deleting stuck PVs..." -ForegroundColor Yellow
$pvs = @("media-config-nfs-pv", "media-downloads-nfs-pv", "media-tv-nfs-pv", "media-movies-nfs-pv", "media-music-nfs-pv")
foreach ($pv in $pvs) {
  $exists = kubectl get pv $pv 2>$null
  if ($exists) {
    Write-Host "  Deleting $pv..."
    kubectl delete pv $pv
  }
}

Start-Sleep -Seconds 5

# Step 3: Re-deploy with fixed configuration
Write-Host "Step 3: Re-deploying with fixed PV/PVC configuration..." -ForegroundColor Yellow
kubectl apply -k homelab-gitops/apps/media/overlays/prod

Start-Sleep -Seconds 10

# Step 4: Verify PVs are created
Write-Host ""
Write-Host "Step 4: Verifying PersistentVolumes..." -ForegroundColor Cyan
Write-Host "=========================================="
kubectl get pv | Select-String "media"
Write-Host ""

# Step 5: Verify PVCs are bound
Write-Host "Step 5: Verifying PersistentVolumeClaims..." -ForegroundColor Cyan
Write-Host "============================================"
kubectl get pvc -n media
Write-Host ""

# Step 6: Check pod status
Write-Host "Step 6: Checking pod status..." -ForegroundColor Cyan
Write-Host "=============================="
kubectl get pods -n media
Write-Host ""

# Step 7: Wait and verify again
Write-Host "Step 7: Waiting 30 seconds for pods to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host ""
Write-Host "Final pod status:" -ForegroundColor Cyan
kubectl get pods -n media -o wide
Write-Host ""

# Step 8: Summary
Write-Host "=========================================="
Write-Host "Recovery Summary:" -ForegroundColor Green
Write-Host "=========================================="
Write-Host ""

Write-Host "PV/PVC Status:" -ForegroundColor Cyan
kubectl get pv,pvc -n media -o wide
Write-Host ""

Write-Host "To check if all PVCs are Bound:" -ForegroundColor Cyan
Write-Host "  kubectl get pvc -n media" -ForegroundColor White
Write-Host ""

Write-Host "To check pod logs:" -ForegroundColor Cyan
Write-Host "  kubectl logs -n media deployment/sonarr" -ForegroundColor White
Write-Host ""

Write-Host "To access web UIs:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n media svc/sonarr 8989:80"
Write-Host "  kubectl port-forward -n media svc/radarr 7878:80"
Write-Host "  kubectl port-forward -n media svc/lidarr 8686:80"
Write-Host "  kubectl port-forward -n media svc/bazarr 6767:80"
Write-Host "  kubectl port-forward -n media svc/prowlarr 9696:80"
Write-Host ""

Write-Host "✅ Recovery script complete!" -ForegroundColor Green
