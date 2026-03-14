# Quick Reference

## First-time deploy (wipes target disk)
```bash
nix develop
nixos-anywhere --flake .#tbone-web root@<server-ip> --disk main /dev/vda
```

## Deploy updates
```bash
nix develop
deploy .#tbone-web
```

## Build site locally
```bash
nix build .#website
```

## Dev server
```bash
cd web && bun run dev
```

## Update bun deps
```bash
cd web && bun update && bun2nix
```

## Update nix inputs
```bash
nix flake update
```

## Verify
```bash
curl -I https://tbone.dev
ssh root@tbone.dev systemctl status caddy
```

See `DEPLOY.md` for the full walkthrough.
