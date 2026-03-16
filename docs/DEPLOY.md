# Deploying tbone.dev

End-to-end guide: from bare VPS to live site at `tbone.dev`.

## What You're Deploying

A single NixOS server running Caddy, serving a static Astro site built with Bun.
Everything is defined in one flake — the site build, the server config, the deployment tooling.

```
You (local) ──deploy-rs──> VPS (NixOS + Caddy) ──serves──> tbone.dev
```

---

## Prerequisites

| What                              | Why                   |
| --------------------------------- | --------------------- |
| Nix with flakes enabled           | Builds everything     |
| A VPS with SSH root access        | Runs the site         |
| `tbone.dev` domain                | Points to the VPS     |
| SSH key pair (`tbone-web-deploy`) | Authenticates deploys |

### Generate SSH Key (if needed)

```bash
ssh-keygen -t ed25519 -C "tbone-web-deploy" -f ~/.ssh/tbone-web-deploy
```

Update the public key in `nix/hosts/tbone-web/default.nix` if it differs from what's there.

---

## Step 1: Get a VPS

**Minimum specs:** 1 vCPU, 512MB RAM, 10GB disk, IPv4 address.

Recommended providers:

- Hetzner Cloud CPX11 (~$4/mo)
- Vultr Cloud Compute ($5/mo)
- DigitalOcean Droplet ($6/mo)

Any Linux distro is fine — nixos-anywhere will wipe and replace it.

Note your server's **IP address** and **disk device name** (usually `/dev/vda` or `/dev/sda`).
If unsure about the disk: `ssh root@<ip> lsblk`

---

## Step 2: Configure DNS

At your registrar, create two A records pointing to your server IP:

| Type | Name  | Value         | TTL |
| ---- | ----- | ------------- | --- |
| A    | `@`   | `<server-ip>` | 300 |
| A    | `www` | `<server-ip>` | 300 |

DNS can take minutes to hours to propagate. You can proceed with the install using the IP directly.

---

## Step 3: Enter Dev Shell

```bash
cd /path/to/tbone.dev
nix develop
```

This gives you: `nixos-anywhere`, `deploy-rs`, `agenix`, `age`, `bun`, `nodejs`, `bun2nix`.

---

## Step 4: Install NixOS (One-Time)

This **wipes the target disk** and installs NixOS with your full configuration.

```bash
nixos-anywhere --flake .#tbone-web root@<server-ip> \
  --disk main /dev/vda
```

Adjust `--disk main /dev/vda` to match your VPS disk device.

What this does:

1. Boots a temporary NixOS installer via kexec
2. Partitions the disk (GPT: BIOS boot + EFI + ext4 root)
3. Installs your NixOS config (Caddy, SSH, firewall, site)
4. Reboots into the final system

Takes 5-15 minutes. Wait for it to finish, then verify:

```bash
ssh -i ~/.ssh/tbone-web-deploy root@tbone.dev
systemctl status caddy
```

---

## Step 5: Verify the Site

Caddy automatically provisions Let's Encrypt SSL certificates on first request.

```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://tbone.dev

# Test HTTPS
curl -I https://tbone.dev

# Test www redirect
curl -I https://www.tbone.dev
```

Expected responses:

- `http://tbone.dev` → 308 redirect to HTTPS (Caddy default)
- `https://tbone.dev` → 200 OK with security headers
- `https://www.tbone.dev` → 301 permanent redirect to `https://tbone.dev`

Check security headers:

```bash
curl -sI https://tbone.dev | grep -E '(Cache-Control|X-Content|X-Frame|Referrer)'
```

---

## Deploying Updates

After the initial install, all updates go through deploy-rs:

```bash
nix develop  # if not already in dev shell

# Preview what will change (dry run)
deploy .#tbone-web --dry-activate

# Deploy for real
deploy .#tbone-web
```

What happens:

1. Builds new NixOS config + website locally
2. Copies the closure to the VPS over SSH
3. Activates the new configuration
4. **Auto-rollback** if activation fails or SSH drops

### Typical workflow

```bash
# 1. Edit site content
cd web
vim src/content/blog/new-post.md

# 2. Test locally
bun run build
bun run preview   # check at localhost:4321

# 3. Build with Nix (optional sanity check)
cd ..
nix build .#website

# 4. Deploy
deploy .#tbone-web

# 5. Commit
git add -A && git commit -m "new post"
```

---

## Rollback

### Automatic

deploy-rs rolls back automatically if activation fails or SSH disconnects during deployment.

### Manual

```bash
ssh root@tbone.dev

# List system generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to a previous generation
/nix/var/nix/profiles/system-<N>-link/bin/switch-to-configuration switch
```

---

## Updating Dependencies

### Nix inputs (nixpkgs, deploy-rs, etc.)

```bash
nix flake update
deploy .#tbone-web
```

### Bun packages

```bash
cd web
bun update
bun2nix          # regenerate bun.nix from bun.lock
cd ..
nix build .#website  # verify build
deploy .#tbone-web
```

---

## Server Administration

```bash
# SSH in
ssh -i ~/.ssh/tbone-web-deploy root@tbone.dev

# Service status
systemctl status caddy

# Caddy logs
journalctl -u caddy -f

# Disk usage
df -h

# What Nix generation is active
nixos-version
```

---

## Troubleshooting

| Problem                          | Fix                                                                              |
| -------------------------------- | -------------------------------------------------------------------------------- |
| `Permission denied (publickey)`  | Check your SSH key matches what's in `default.nix`                               |
| nixos-anywhere can't find disk   | `ssh root@<ip> lsblk` and use correct device                                     |
| SSL certificate not provisioning | Verify DNS A records resolve to server IP: `dig tbone.dev`                       |
| Build fails on bun deps          | `cd web && bun2nix` to regenerate `bun.nix`                                      |
| Caddy won't start                | `journalctl -u caddy -n 50` for error details                                    |
| Site not updating after deploy   | Check `nix path-info .#website` changed; try `systemctl restart caddy` on server |
| deploy-rs connection refused     | Verify port 22 is open and hostname resolves                                     |

---

## Architecture Reference

```
flake.nix                          # Single composition root
├── inputs: nixpkgs, disko, agenix, deploy-rs, bun2nix
├── packages.x86_64-linux.website  # Static site build (Bun + Astro → dist/)
├── devShells (4 platforms)        # bun, nodejs, deploy-rs, agenix, etc.
├── nixosConfigurations.tbone-web  # Full server: Caddy + SSH + firewall
└── deploy.nodes.tbone-web        # deploy-rs target at tbone.dev

nix/hosts/tbone-web/
├── default.nix    # Server config: Caddy, SSH, firewall, packages
└── disko.nix      # Disk layout: GPT, BIOS+EFI boot, ext4 root

nix/packages/
└── website.nix    # Astro build derivation (bun2nix + sharp/autoPatchelf)

web/               # Astro source (content, components, styles)
```
