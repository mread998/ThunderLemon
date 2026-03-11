# Documentation Index - Media Deployment

Welcome! Here's where to find everything you need.

## 🚀 Getting Started (Start Here!)

### [QUICK_START.md](QUICK_START.md) ⭐
**For the impatient** - Just want to deploy? This is it!
- One-line deploy commands
- Manual alternative steps
- Verification checklist
- Port mappings

### [README.md](README.md)
**Main documentation** - Architecture and overview
- What each app does
- How storage is configured
- Service details
- Mount points

---

## 📚 Understanding The Migration

### [STORAGE_CLASS_SUMMARY.md](STORAGE_CLASS_SUMMARY.md)
**Best overview** - Complete picture of what changed
- Your cluster's storage classes explained
- Before/after comparison
- How dynamic provisioning works
- Step-by-step deployment
- Verification procedures
- Troubleshooting guide
- Why this is better

### [BEFORE_AND_AFTER.md](BEFORE_AND_AFTER.md)
**Visual comparison** - See the differences clearly
- File structure comparison
- Binding flow diagrams
- Configuration complexity analysis
- Error scenarios
- Operational overhead comparison

### [STORAGE_CLASS_UPDATE.md](STORAGE_CLASS_UPDATE.md)
**Detailed explanation** - Deep dive into nfs-rwx
- Old approach vs. new approach
- Key advantages explained
- Configuration details
- Deployment instructions
- Troubleshooting with examples
- Reverting if needed

### [MIGRATION_COMPLETE.md](MIGRATION_COMPLETE.md)
**Quick summary** - At-a-glance overview
- What changed in a nutshell
- Storage configuration table
- Quick deploy options
- Verification steps
- Files that were modified

---

## 🔧 Deployment Scripts

### [deploy.ps1](deploy.ps1)
**Windows PowerShell** - Automated deployment
- Cleans up old namespace
- Verifies storage class
- Applies manifests
- Waits for PVC binding
- Shows final status
- No manual steps needed!

### [deploy.sh](deploy.sh)
**Linux/Mac Bash** - Automated deployment
- Same functionality as PowerShell version
- For *nix systems
- Colored output for easy reading
- Handles all prerequisites

---

## 📋 Kubernetes Configuration Files

### [base/pvc.yaml](base/pvc.yaml)
**The core** - All persistent volume claims
- 9 PVCs using nfs-rwx
- Configuration storage (sonarr, radarr, lidarr, bazarr, prowlarr)
- Media storage (downloads, tv, movies, music)
- Clean, simple format

### [base/kustomization.yaml](base/kustomization.yaml)
**Resource orchestration** - What gets deployed
- References all 18 resources
- Namespace management
- Kustomization patches

### [base/namespace.yaml](base/namespace.yaml)
**Kubernetes namespace** - Isolation for media apps
- Creates `media` namespace

### [base/\*-configmap.yaml](base/)
**App configurations** - Environment settings
- sonarr-configmap.yaml
- radarr-configmap.yaml
- lidarr-configmap.yaml
- bazarr-configmap.yaml
- prowlarr-configmap.yaml

### [base/\*-deployment.yaml](base/)
**Container deployments** - The actual apps
- sonarr-deployment.yaml
- radarr-deployment.yaml
- lidarr-deployment.yaml
- bazarr-deployment.yaml
- prowlarr-deployment.yaml

### [base/\*-service.yaml](base/)
**Kubernetes services** - Network exposure
- sonarr-service.yaml
- radarr-service.yaml
- lidarr-service.yaml
- bazarr-service.yaml
- prowlarr-service.yaml

---

## 📊 Documentation By Use Case

### I Want to Deploy Now
1. Read: [QUICK_START.md](QUICK_START.md)
2. Run: `powershell -ExecutionPolicy Bypass -File deploy.ps1`
3. Done! ✅

### I Want to Understand the Change
1. Read: [STORAGE_CLASS_SUMMARY.md](STORAGE_CLASS_SUMMARY.md)
2. See: [BEFORE_AND_AFTER.md](BEFORE_AND_AFTER.md)
3. Deep dive: [STORAGE_CLASS_UPDATE.md](STORAGE_CLASS_UPDATE.md)

### I Want Technical Details
1. Study: [base/pvc.yaml](base/pvc.yaml)
2. Understand: [STORAGE_CLASS_UPDATE.md](STORAGE_CLASS_UPDATE.md) - NFS Integration section
3. Reference: [STORAGE_CLASS_SUMMARY.md](STORAGE_CLASS_SUMMARY.md) - How This Works Now section

### I'm Troubleshooting an Issue
1. Check: [STORAGE_CLASS_SUMMARY.md](STORAGE_CLASS_SUMMARY.md) - Troubleshooting Guide section
2. Run: Verification commands from [QUICK_START.md](QUICK_START.md)
3. Debug: Use kubectl commands from [STORAGE_CLASS_UPDATE.md](STORAGE_CLASS_UPDATE.md)

### I Want to Review the Architecture
1. Read: [README.md](README.md) - Architecture section
2. See: [BEFORE_AND_AFTER.md](BEFORE_AND_AFTER.md) - File Structure Comparison
3. Check: [base/kustomization.yaml](base/kustomization.yaml) for complete resource list

---

## 📝 What Each File Does

| File | Purpose | Read When |
|------|---------|-----------|
| **QUICK_START.md** | Just deploy it | You want to get apps running ASAP |
| **README.md** | Architecture overview | You want to understand the setup |
| **STORAGE_CLASS_SUMMARY.md** | Complete reference | You want full details and examples |
| **BEFORE_AND_AFTER.md** | Visual comparison | You want to see what changed |
| **STORAGE_CLASS_UPDATE.md** | Deep technical dive | You want to understand NFS integration |
| **MIGRATION_COMPLETE.md** | Executive summary | You want the quick version |
| **deploy.ps1** | Auto deployment (Windows) | You want hands-off deployment |
| **deploy.sh** | Auto deployment (Linux/Mac) | You want hands-off deployment |
| **base/pvc.yaml** | PVC definitions | You want to see the YAML |
| **README.md** | Architecture diagram | You want visual layout |

---

## 🎯 Quick Navigation

### By Level of Detail
- **Minimal**: QUICK_START.md
- **Medium**: STORAGE_CLASS_SUMMARY.md
- **Detailed**: STORAGE_CLASS_UPDATE.md
- **Visual**: BEFORE_AND_AFTER.md

### By Purpose
- **Deploy**: deploy.ps1 / deploy.sh
- **Learn**: STORAGE_CLASS_SUMMARY.md
- **Troubleshoot**: STORAGE_CLASS_UPDATE.md
- **Verify**: QUICK_START.md

### By File Type
- **Deploy Scripts**: deploy.ps1, deploy.sh
- **Documentation**: All .md files
- **Configuration**: base/*.yaml, overlays/prod/*.yaml

---

## 🆘 Troubleshooting Quick Links

### PVCs not binding?
→ See [STORAGE_CLASS_SUMMARY.md](STORAGE_CLASS_SUMMARY.md#if-pvcs-dont-bind-immediately)

### Pods failing to start?
→ See [STORAGE_CLASS_UPDATE.md](STORAGE_CLASS_UPDATE.md#nfs-mount-not-working)

### NFS mount issues?
→ See [STORAGE_CLASS_SUMMARY.md](STORAGE_CLASS_SUMMARY.md#if-nfs-mounts-arent-working)

### Confused about changes?
→ See [BEFORE_AND_AFTER.md](BEFORE_AND_AFTER.md)

### Want manual steps?
→ See [QUICK_START.md](QUICK_START.md#if-you-prefer-manual-steps)

---

## 📌 Key Takeaways

✅ **Changed**: From static PVs to dynamic provisioning via nfs-rwx StorageClass  
✅ **Simpler**: YAML reduced by 56%  
✅ **Cleaner**: No more label selectors and manual volume bindings  
✅ **Better**: Automatic provisioning and error handling  
✅ **Faster**: PVCs bind in seconds instead of debugging label mismatches  

---

## 🚀 Next Steps

1. **Choose your deployment method**:
   - Automated: Run `deploy.ps1` or `deploy.sh`
   - Manual: Follow steps in QUICK_START.md

2. **Verify deployment**:
   - Run verification commands from QUICK_START.md
   - Check all PVCs are Bound
   - Check all pods are Running

3. **Access applications**:
   - Use kubectl port-forward
   - Access web UIs
   - Configure indexers/providers

4. **Monitor**:
   - Watch logs: `kubectl logs -n media deployment/sonarr`
   - Monitor pods: `kubectl get pods -n media --watch`
   - Check NFS mounts: `kubectl exec -it -n media deployment/sonarr -- df -h`

---

## 📞 Finding Information

Can't find what you need?

1. **For deployment**: [QUICK_START.md](QUICK_START.md)
2. **For understanding**: [STORAGE_CLASS_SUMMARY.md](STORAGE_CLASS_SUMMARY.md)
3. **For troubleshooting**: [STORAGE_CLASS_UPDATE.md](STORAGE_CLASS_UPDATE.md)
4. **For visuals**: [BEFORE_AND_AFTER.md](BEFORE_AND_AFTER.md)
5. **For reference**: [README.md](README.md)

---

**Status**: ✅ Everything is ready. Pick a document above and start! 🚀
