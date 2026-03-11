# NFS Directory Setup Script (Windows)
# Run this on your NFS server (10.11.11.46) if running NFS on Windows

# Note: This requires running on a Windows NFS server (e.g., Windows Server with NFS role)
# For Linux NFS servers, use setup-nfs-dirs.sh instead

$BasePath = "X:\vault"  # Adjust drive letter as needed
$ErrorActionPreference = "Stop"

Write-Host "Creating NFS directory structure at $BasePath..."

# Create main directories
New-Item -ItemType Directory -Path "$BasePath\config\sonarr" -Force | Out-Null
New-Item -ItemType Directory -Path "$BasePath\config\radarr" -Force | Out-Null
New-Item -ItemType Directory -Path "$BasePath\config\lidarr" -Force | Out-Null
New-Item -ItemType Directory -Path "$BasePath\downloads" -Force | Out-Null
New-Item -ItemType Directory -Path "$BasePath\movies" -Force | Out-Null
New-Item -ItemType Directory -Path "$BasePath\music" -Force | Out-Null

Write-Host "✓ Directory structure created"

# Set NTFS permissions (basic - adjust for your security needs)
Write-Host "Setting directory permissions..."

# Grant everyone modify permissions (adjust as needed)
foreach ($dir in @(
    "$BasePath\config\sonarr",
    "$BasePath\config\radarr",
    "$BasePath\config\lidarr",
    "$BasePath\downloads",
    "$BasePath\movies",
    "$BasePath\music"
)) {
    $acl = Get-Acl $dir
    $ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($ar)
    Set-Acl $dir $acl
}

Write-Host "✓ Permissions set"

# Display directory structure
Write-Host ""
Write-Host "Directory structure created:"
Get-ChildItem -Path $BasePath -Recurse -Directory | Select-Object FullName | Format-Table -AutoSize

Write-Host ""
Write-Host "✓ NFS setup complete!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Configure NFS Share Properties:"
Write-Host "   - Right-click on $BasePath"
Write-Host "   - Select 'Properties' > 'NFS Sharing'"
Write-Host "   - Enable NFS sharing with appropriate permissions"
Write-Host "2. Ensure NFS Server role is installed and running"
Write-Host "3. Configure firewall rules for NFS (ports 111, 2049)"
Write-Host "4. Deploy to Kubernetes: kubectl apply -k homelab-gitops/apps/media/overlays/prod"
