#!/bin/bash

# Deploy media apps using nfs-rwx storage class
# This script handles the deployment of Sonarr, Radarr, Lidarr, Bazarr, and Prowlarr

set -e

echo "=================================="
echo "Media Apps Deployment"
echo "Using nfs-rwx Storage Class"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Check if media namespace exists
echo -e "\n${YELLOW}Step 1: Checking namespace...${NC}"
if kubectl get namespace media &> /dev/null; then
    echo -e "${YELLOW}Media namespace exists. Deleting...${NC}"
    kubectl delete namespace media --wait=true
    sleep 10
    echo -e "${GREEN}✓ Namespace deleted${NC}"
else
    echo -e "${GREEN}✓ Fresh start - no existing namespace${NC}"
fi

# Step 2: Verify storage class
echo -e "\n${YELLOW}Step 2: Verifying nfs-rwx storage class...${NC}"
if kubectl get storageclass nfs-rwx &> /dev/null; then
    echo -e "${GREEN}✓ nfs-rwx storage class found${NC}"
    kubectl get storageclass nfs-rwx -o wide
else
    echo -e "${RED}✗ nfs-rwx storage class NOT found!${NC}"
    echo "Available storage classes:"
    kubectl get storageclass
    exit 1
fi

# Step 3: Apply base manifests
echo -e "\n${YELLOW}Step 3: Applying base manifests...${NC}"
kubectl apply -k homelab-gitops/apps/media/base/
echo -e "${GREEN}✓ Base manifests applied${NC}"

# Step 4: Wait for namespace to be ready
echo -e "\n${YELLOW}Step 4: Waiting for namespace to be ready...${NC}"
kubectl wait --for=condition=ready pod --all -n media --timeout=300s || true

# Step 5: Check PVC status
echo -e "\n${YELLOW}Step 5: Checking PVC binding...${NC}"
sleep 5
kubectl get pvc -n media

# Count bound PVCs
BOUND_COUNT=$(kubectl get pvc -n media | grep -c "Bound" || true)
TOTAL_COUNT=$(kubectl get pvc -n media | grep -c "media-" || true)

if [ "$BOUND_COUNT" -eq "$TOTAL_COUNT" ]; then
    echo -e "${GREEN}✓ All PVCs bound successfully ($BOUND_COUNT/$TOTAL_COUNT)${NC}"
else
    echo -e "${YELLOW}⚠ Some PVCs still binding ($BOUND_COUNT/$TOTAL_COUNT)${NC}"
    echo "Waiting additional time..."
    sleep 10
    kubectl get pvc -n media
fi

# Step 6: Check pod status
echo -e "\n${YELLOW}Step 6: Checking pod status...${NC}"
sleep 5
RUNNING_PODS=$(kubectl get pods -n media --no-headers | grep -c "Running" || true)
echo "Running pods: $RUNNING_PODS/5"
kubectl get pods -n media

# Step 7: Apply production overlay (if you want replicas)
echo -e "\n${YELLOW}Step 7: Apply production overlay? (y/n)${NC}"
read -r -t 10 APPLY_PROD || APPLY_PROD="n"
if [ "$APPLY_PROD" == "y" ] || [ "$APPLY_PROD" == "Y" ]; then
    echo -e "${YELLOW}Applying production overlay...${NC}"
    kubectl apply -k homelab-gitops/apps/media/overlays/prod/
    echo -e "${GREEN}✓ Production overlay applied${NC}"
else
    echo -e "${YELLOW}Skipping production overlay${NC}"
fi

# Step 8: Final status check
echo -e "\n${YELLOW}Step 8: Final status check...${NC}"
echo -e "${GREEN}Namespace: ${NC}"
kubectl get namespace media

echo -e "\n${GREEN}PersistentVolumeClaims: ${NC}"
kubectl get pvc -n media

echo -e "\n${GREEN}Pods: ${NC}"
kubectl get pods -n media

echo -e "\n${GREEN}Services: ${NC}"
kubectl get svc -n media

echo -e "\n=================================="
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo "=================================="

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Check pod logs: kubectl logs -n media deployment/sonarr"
echo "2. Port forward: kubectl port-forward -n media svc/sonarr 8989:8989"
echo "3. Access UI: http://localhost:8989"

echo -e "\n${YELLOW}Application Port Mappings:${NC}"
echo "  Sonarr (TV):      8989"
echo "  Radarr (Movies):  7878"
echo "  Lidarr (Music):   8686"
echo "  Bazarr (Subs):    6767"
echo "  Prowlarr (Index): 9696"

echo -e "\n${YELLOW}Verify NFS mounts:${NC}"
echo "  kubectl exec -it -n media deployment/sonarr -- df -h | grep /srv"
