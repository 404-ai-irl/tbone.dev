# Deployment Guide

Self-hosted deployment workflow for tbone.dev using NixOS and deploy-rs.

## Prerequisites

- VPS with SSH access (currently running Ubuntu/Debian)
- Domain name pointing to VPS (`tbone.dev`)
- SSH key for deployment already configured (`tbone-web-deploy`)

## One-Time Setup: Install NixOS on VPS

Convert your existing VPS to NixOS using nixos-anywhere:

```bash
# Enter dev shell (has nixos-anywhere available)
nix develop

# Deploy NixOS to your VPS
# Replace YOUR_VPS_IP with actual IP if DNS isn't set up yet
nixos-anywhere --flake .#tbone-web root@tbone.dev \
  --disk main /dev/vda  # adjust disk device as needed (common: /dev/vda, /dev/sda, /dev/nvme0n1)
```

**Important:** Check your VPS disk device name before running. Common names:
- DigitalOcean, Hetzner, Vultr: `/dev/vda`
- Some providers: `/dev/sda` or `/dev/nvme0n1`

This will:
- Partition and format the disk (destructive!)
- Install NixOS with your configuration
- Set up Caddy with auto-HTTPS
- Configure SSH access
- Deploy your Astro site

## Ongoing Deployments with deploy-rs

After initial setup, deploy updates with a single command:

```bash
# From dev shell
nix develop

# Deploy configuration and website updates
nix run github:serokell/deploy-rs -- .#tbone-web
```

Or add deploy-rs to your profile and run:

```bash
deploy .#tbone-web
```

### What happens during deployment:

1. Builds new NixOS configuration locally
2. Builds updated website package
3. Copies closures to VPS
4. Activates new configuration
5. Automatic rollback if activation fails (magic!)

## Manual Deployment Steps

If you prefer more control:

```bash
# Build locally
nix build .#website

# Check what will be deployed
nix flake show

# Deploy
nix run github:serokell/deploy-rs -- .#tbone-web --dry-activate  # preview
nix run github:serokell/deploy-rs -- .#tbone-web                 # actually deploy
```

## Updating the Website

1. Make changes to `web/` directory
2. Commit to git (optional but recommended)
3. Run `nix run github:serokell/deploy-rs -- .#tbone-web`
4. Site updates immediately (Caddy serves from `/nix/store`)

## Rollback

If something breaks:

```bash
# SSH to server
ssh root@tbone.dev

# List generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
/nix/var/nix/profiles/system-{N}-link/bin/switch-to-configuration switch
```

Or use deploy-rs's automatic rollback:
- If SSH disconnects during activation, previous config is restored automatically

## Forgejo Integration (Future)

To trigger deploys from Forgejo:

### Option 1: Webhook + deploy script on jump box
```bash
# On your local machine or CI runner
curl -X POST https://forgejo.example.com/api/webhooks/... && \
nix run github:serokell/deploy-rs -- .#tbone-web
```

### Option 2: Forgejo Actions (when enabled)
```yaml
# .forgejo/workflows/deploy.yml
name: Deploy
on: [push]
jobs:
  deploy:
    runs-on: nix
    steps:
      - uses: actions/checkout@v3
      - run: nix run github:serokell/deploy-rs -- .#tbone-web
```

## Verifying Deployment

```bash
# Check service status
ssh root@tbone.dev systemctl status caddy

# View logs
ssh root@tbone.dev journalctl -u caddy -f

# Test site
curl https://tbone.dev
```

## Common Issues

### Can't connect after nixos-anywhere
- Wait 30-60 seconds for reboot
- Check VPS console if available
- Verify SSH key is correct in `nix/hosts/tbone-web/default.nix`

### deploy-rs fails with "connection refused"
- Check firewall allows SSH (port 22)
- Verify hostname resolves: `ping tbone.dev`

### Website not updating
- Caddy caches: `ssh root@tbone.dev systemctl reload caddy`
- Check Nix store path changed: `nix path-info .#website`

### Disk device not found
- SSH to VPS: `lsblk` to see available disks
- Update command with correct device: `--disk main /dev/YOUR_DISK`
