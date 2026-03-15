# Uninstalling Longhorn (Installed via ArgoCD)

Longhorn requires a careful ordered teardown — deleting the ArgoCD app directly without prep will leave orphaned CRDs, volumes, and potentially brick PVCs in other namespaces.

---

## Step 1 — Scale down all workloads using Longhorn volumes

Any pod with a Longhorn PVC must be stopped first, otherwise the uninstall will hang.

```bash
# Find all PVCs using the longhorn storage class
kubectl get pvc -A | grep longhorn
```

Scale down or delete the deployments/statefulsets that use those PVCs.

---

## Step 2 — Delete all Longhorn PVCs and PVs

```bash
# Delete PVCs in each namespace that uses Longhorn
kubectl delete pvc -n <namespace> <pvc-name>

# Confirm no Longhorn PVs remain
kubectl get pv | grep longhorn
```

---

## Step 3 — Set the deletion confirmation flag

Longhorn requires explicit confirmation before it will allow itself to be uninstalled.

```bash
kubectl -n longhorn-system patch settings.longhorn.io deleting-confirmation-flag \
  --type=merge -p '{"value":"true"}'
```

Or via the Longhorn UI: **Settings → General → Deleting Confirmation Flag → true**

---

## Step 4 — Delete the ArgoCD Application

```bash
# Cascade delete — removes all managed resources
argocd app delete longhorn --cascade

# Or via kubectl
kubectl delete application longhorn -n argocd
```

This triggers the Helm pre-delete hook which runs Longhorn's uninstaller job inside the cluster. Watch it complete:

```bash
kubectl get jobs -n longhorn-system -w
```

---

## Step 5 — Clean up CRDs (if they remain)

Helm/ArgoCD often leaves CRDs behind by design to protect data.

```bash
kubectl get crd | grep longhorn

# Delete each one
kubectl delete crd \
  backingimagedatasources.longhorn.io \
  backingimagemanagers.longhorn.io \
  backingimages.longhorn.io \
  backupbackingimages.longhorn.io \
  backups.longhorn.io \
  backuptargets.longhorn.io \
  backupvolumes.longhorn.io \
  engineimages.longhorn.io \
  engines.longhorn.io \
  instancemanagers.longhorn.io \
  nodes.longhorn.io \
  orphans.longhorn.io \
  recurringjobs.longhorn.io \
  replicas.longhorn.io \
  settings.longhorn.io \
  sharemanagers.longhorn.io \
  snapshots.longhorn.io \
  supportbundles.longhorn.io \
  systembackups.longhorn.io \
  systemrestores.longhorn.io \
  volumes.longhorn.io \
  volumeattachments.longhorn.io
```

---

## Step 6 — Delete the namespace

```bash
kubectl delete namespace longhorn-system
```

If the namespace gets stuck in `Terminating`, it usually means a CRD finalizer is blocking it:

```bash
kubectl get namespace longhorn-system -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/longhorn-system/finalize" -f -
```

---

**Key gotcha:** Skipping Step 3 (the confirmation flag) is the most common reason Longhorn uninstalls hang indefinitely.
