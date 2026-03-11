#!/bin/bash
# NFS Directory Setup Script
# Run this on your NFS server (10.11.11.46) to create the required directory structure

# Exit on error
set -e

BASE_PATH="/srv/vault"

echo "Creating NFS directory structure at $BASE_PATH..."

# Create main directories
mkdir -p "$BASE_PATH/config/sonarr"
mkdir -p "$BASE_PATH/config/radarr"
mkdir -p "$BASE_PATH/config/lidarr"
mkdir -p "$BASE_PATH/downloads"
mkdir -p "$BASE_PATH/movies"
mkdir -p "$BASE_PATH/music"

echo "✓ Directory structure created"

# Set permissions (adjust as needed for your environment)
# Option 1: Open permissions (simplest, less secure)
echo "Setting permissions (open mode - adjust for your security needs)..."
chmod -R 777 "$BASE_PATH"
chown -R nobody:nogroup "$BASE_PATH"

echo "✓ Permissions set"

# Verify structure
echo ""
echo "Directory structure created:"
tree "$BASE_PATH" 2>/dev/null || find "$BASE_PATH" -type d | sort

echo ""
echo "✓ NFS setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure /etc/exports on your NFS server:"
echo "   $BASE_PATH *(rw,sync,no_subtree_check,no_root_squash)"
echo "2. Reload NFS: sudo systemctl restart nfs-kernel-server"
echo "3. Verify exports: exportfs -v"
echo "4. Deploy to Kubernetes: kubectl apply -k homelab-gitops/apps/media/overlays/prod"
