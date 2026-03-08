# Sabnzbd (Kubernetes)

This directory contains a kustomize-based deployment for **sabnzbd**.

## Structure

- `base/` - common manifests (namespace, deployment, service, ingress, PVCs, config, secrets)
- `overlays/prod/` - production overlay (currently just includes base)
- `overlays/dev/` - development overlay (can be customized without affecting prod)

## Secrets

This deployment uses a sealed secret to store sabnzbd credentials.

### To generate the sealed secret (recommended)

```bash
kubectl create secret generic sabnzbd-credentials \
  --from-literal=SABNZBD_USER=<username> \
  --from-literal=SABNZBD_PASS=<password> \
  -n sabnzbd -o yaml | kubeseal --format=yaml > apps/sabnzbd/base/sealedsecrets.yaml
```

Then commit `apps/sabnzbd/base/sealedsecrets.yaml`.

### Alternative (plain secret)

If you want to use a plain Kubernetes secret instead of sealed, create `apps/sabnzbd/base/secret.yaml` with base64 values and apply it to the cluster.

## Deploying

### Production (ArgoCD)

ArgoCD application is configured in `argocd/apps/sabnzbd-app.yaml` and points at:

- `path: homelab-gitops/apps/sabnzbd/overlays/prod`

### Development

To deploy the dev overlay manually:

```bash
kubectl apply -k apps/sabnzbd/overlays/dev
```

You can add overlays patches to change e.g. replica count, image tag, ingress host, etc.
