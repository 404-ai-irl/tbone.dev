# Quick Start Deployment

## Initial Setup (run once)

```bash
# 1. Find your VPS disk device
ssh root@YOUR_VPS_IP "lsblk"

# 2. Install NixOS (DESTRUCTIVE - wipes VPS)
nix develop
nixos-anywhere --flake .#tbone-web root@YOUR_VPS_IP --disk main /dev/vda
# Replace /dev/vda with your actual disk from step 1

# Wait for reboot (~60 seconds)
```

## Deploy Updates (every time)

```bash
nix run github:serokell/deploy-rs -- .#tbone-web
```

That's it! Your site is now live at `https://tbone.dev`.

## Verify

```bash
curl https://tbone.dev
ssh root@tbone.dev systemctl status caddy
```

## Next Steps

- See `DEPLOY.md` for detailed documentation
- See `SOPS_SETUP.md` for secrets management
- Update `flake.nix` hostname if using IP instead of domain
