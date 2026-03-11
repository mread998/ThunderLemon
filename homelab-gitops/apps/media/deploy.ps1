# Deploy media apps using nfs-rwx storage class
# PowerShell version - Run with: powershell -ExecutionPolicy Bypass -File deploy.ps1

param(
    [switch]$SkipProdOverlay = $false
)

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Media Apps Deployment" -ForegroundColor Cyan
Write-Host "Using nfs-rwx Storage Class" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Step 1: Check if media namespace exists
Write-Host "`nStep 1: Checking namespace..." -ForegroundColor Yellow
$namespaceExists = kubectl get namespace media 2>$null

if ($namespaceExists) {
    Write-Host "Media namespace exists. Deleting..." -ForegroundColor Yellow
    kubectl delete namespace media --wait=true
    Start-Sleep -Seconds 10
    Write-Host "✓ Namespace deleted" -ForegroundColor Green
} else {
    Write-Host "✓ Fresh start - no existing namespace" -ForegroundColor Green
}

# Step 2: Verify storage class
Write-Host "`nStep 2: Verifying nfs-rwx storage class..." -ForegroundColor Yellow
try {
    $sc = kubectl get storageclass nfs-rwx -o wide 2>$null
    Write-Host "✓ nfs-rwx storage class found" -ForegroundColor Green
    $sc
} catch {
    Write-Host "✗ nfs-rwx storage class NOT found!" -ForegroundColor Red
    Write-Host "Available storage classes:" -ForegroundColor Yellow
    kubectl get storageclass
    exit 1
}

# Step 3: Apply base manifests
Write-Host "`nStep 3: Applying base manifests..." -ForegroundColor Yellow
kubectl apply -k homelab-gitops/apps/media/base/
Write-Host "✓ Base manifests applied" -ForegroundColor Green

# Step 4: Wait for namespace to be ready
Write-Host "`nStep 4: Waiting for pods to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Step 5: Check PVC status
Write-Host "`nStep 5: Checking PVC binding..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
Write-Host "`nPersistentVolumeClaims:" -ForegroundColor Green
$pvcs = kubectl get pvc -n media
$pvcs

# Count bound PVCs
$boundCount = ($pvcs | Select-String "Bound" | Measure-Object).Count
$totalCount = ($pvcs | Select-String "media-" | Measure-Object).Count

if ($boundCount -eq $totalCount) {
    Write-Host "✓ All PVCs bound successfully ($boundCount/$totalCount)" -ForegroundColor Green
} else {
    Write-Host "⚠ Some PVCs still binding ($boundCount/$totalCount)" -ForegroundColor Yellow
    Write-Host "Waiting additional time..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    kubectl get pvc -n media
}

# Step 6: Check pod status
Write-Host "`nStep 6: Checking pod status..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Write-Host "`nPods:" -ForegroundColor Green
$pods = kubectl get pods -n media
$pods
$runningCount = ($pods | Select-String "Running" | Measure-Object).Count
Write-Host "Running pods: $runningCount/5" -ForegroundColor Yellow

# Step 7: Apply production overlay (if you want replicas)
if (-not $SkipProdOverlay) {
    Write-Host "`nStep 7: Apply production overlay? (y/n)" -ForegroundColor Yellow
    $response = Read-Host "Enter choice"
    
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "Applying production overlay..." -ForegroundColor Yellow
        kubectl apply -k homelab-gitops/apps/media/overlays/prod/
        Write-Host "✓ Production overlay applied" -ForegroundColor Green
    } else {
        Write-Host "Skipping production overlay" -ForegroundColor Yellow
    }
}

# Step 8: Final status check
Write-Host "`nStep 8: Final status check..." -ForegroundColor Yellow
Write-Host "`nNamespace:" -ForegroundColor Green
kubectl get namespace media

Write-Host "`nPersistentVolumeClaims:" -ForegroundColor Green
kubectl get pvc -n media

Write-Host "`nPods:" -ForegroundColor Green
kubectl get pods -n media

Write-Host "`nServices:" -ForegroundColor Green
kubectl get svc -n media

Write-Host "`n==================================" -ForegroundColor Cyan
Write-Host "✓ Deployment Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Check pod logs: kubectl logs -n media deployment/sonarr"
Write-Host "2. Port forward: kubectl port-forward -n media svc/sonarr 8989:8989"
Write-Host "3. Access UI: http://localhost:8989"

Write-Host "`nApplication Port Mappings:" -ForegroundColor Yellow
Write-Host "  Sonarr (TV):      8989"
Write-Host "  Radarr (Movies):  7878"
Write-Host "  Lidarr (Music):   8686"
Write-Host "  Bazarr (Subs):    6767"
Write-Host "  Prowlarr (Index): 9696"

Write-Host "`nVerify NFS mounts:" -ForegroundColor Yellow
Write-Host "  kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv"
