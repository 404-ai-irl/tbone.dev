# Launch Guide: VPS to Live Site

Complete walkthrough for deploying tbone.dev from scratch.

---

## Overview

```
Local machine                          VPS (NixOS)
+-----------------+    deploy-rs     +--------------------+
| flake.nix       | ──────────────>  | Caddy (auto-HTTPS) |
| nix/            |   SSH + Nix      | serves /nix/store   |
| web/ (Astro)    |   closures       | firewall: 80, 443  |
+-----------------+                  +--------------------+
                                           |
                                     tbone.dev (DNS)
                                           |
                                       Visitors
```

**Stack:** Nix flake -> Bun + Astro static build -> NixOS + Caddy -> deploy-rs

---

## Phase 1: Local Prep

### 1.1 Verify the build works

```bash
cd /path/to/tbone.dev

# Enter the dev shell (provides all tooling)
nix develop

# Build the site with Nix
nix build .#website

# Inspect the output
ls result/
# Should contain: index.html, _astro/, etc.
```

### 1.2 Preview locally (optional)

```bash
cd web
bun install
bun run build
bun run preview
# Open http://localhost:4321
```

### 1.3 Checklist

- [ ] `nix build .#website` succeeds
- [ ] Output contains `index.html` and `_astro/` directory
- [ ] Site looks correct in local preview
- [ ] `astro.config.mjs` has `site: 'https://tbone.dev'`
- [ ] Verify `SITE_TITLE` and `SITE_DESCRIPTION` in `web/src/consts.ts`

---

## Phase 2: VPS Setup

### 2.1 Provision a server

**Minimum specs:**
- 1 vCPU, 512MB RAM (1GB recommended), 10GB disk
- IPv4 address
- Any Linux distro (nixos-anywhere replaces it)

**Providers:**

| Provider | Plan | Cost | Disk Device |
|----------|------|------|-------------|
| Hetzner Cloud | CPX11 | ~$4/mo | `/dev/sda` or `/dev/vda` |
| Vultr | Cloud Compute | $5/mo | `/dev/vda` |
| DigitalOcean | Droplet | $6/mo | `/dev/vda` |

### 2.2 Verify SSH access

```bash
# Test that you can reach the server
ssh root@<server-ip>

# While connected, check the disk device name
lsblk
# Note the primary disk (e.g., vda, sda, nvme0n1)
```

### 2.3 SSH key for deployment

If you don't already have the `tbone-web-deploy` key:

```bash
ssh-keygen -t ed25519 -C "tbone-web-deploy" -f ~/.ssh/tbone-web-deploy
cat ~/.ssh/tbone-web-deploy.pub
```

Make sure this public key matches what's in `nix/hosts/tbone-web/default.nix`:

```nix
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... tbone-web-deploy"
];
```

---

## Phase 3: DNS

### 3.1 Create A records

At your domain registrar, point both `tbone.dev` and `www.tbone.dev` to your server:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | `@` | `<server-ip>` | 300 |
| A | `www` | `<server-ip>` | 300 |

### 3.2 Verify propagation

```bash
dig tbone.dev +short
# Should return your server IP

dig www.tbone.dev +short
# Should return your server IP
```

DNS can take minutes to hours. You can proceed with installation using the IP address directly and set up DNS while it propagates.

---

## Phase 4: Install NixOS

This is the one-time setup. It wipes the VPS disk and installs NixOS with your entire configuration.

### 4.1 Run nixos-anywhere

```bash
nix develop  # if not already in dev shell

nixos-anywhere --flake .#tbone-web root@<server-ip> \
  --disk main /dev/vda
```

Replace `/dev/vda` with your actual disk device from step 2.2.

**What happens:**
1. Uploads a temporary NixOS installer to the VPS via kexec
2. Partitions the disk (GPT: 1M BIOS boot + 512M EFI + ext4 root)
3. Installs NixOS with your full configuration
4. Sets up Caddy, SSH, firewall, Nix garbage collection
5. Deploys your Astro site to `/nix/store`
6. Reboots

Takes 5-15 minutes depending on network speed.

### 4.2 Verify the install

```bash
# Wait ~60 seconds for reboot, then connect with your deploy key
ssh -i ~/.ssh/tbone-web-deploy root@<server-ip>

# Check NixOS is running
nixos-version

# Check Caddy is active
systemctl status caddy

# Check the site is being served
curl -sI localhost
```

**Troubleshooting:**
- Can't connect? Wait longer, or check the VPS console in your provider's dashboard.
- Wrong SSH key? You'll need to use the provider console to fix `default.nix` and redeploy.
- Disk not found? Double-check the device name with `lsblk` from the provider console.

---

## Phase 5: SSL and Domain Verification

Caddy automatically provisions Let's Encrypt SSL certificates when it receives HTTPS requests with the correct `Host` header. No manual configuration needed.

### 5.1 Test the site

```bash
# HTTP -> should redirect to HTTPS (once DNS is pointing)
curl -I http://tbone.dev

# HTTPS -> should return 200 with your site
curl -I https://tbone.dev

# www -> should 301 redirect to apex
curl -I https://www.tbone.dev

# Verify security headers
curl -sI https://tbone.dev | grep -E '(Cache-Control|X-Content|X-Frame|Referrer)'
```

Expected:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
```

### 5.2 Test caching

```bash
# Immutable assets (1 year cache)
curl -sI https://tbone.dev/_astro/some-file.css | grep Cache-Control
# Cache-Control: public, max-age=31536000, immutable

# HTML pages (1 hour, must-revalidate)
curl -sI https://tbone.dev/ | grep Cache-Control
# Cache-Control: public, max-age=3600, must-revalidate
```

### 5.3 Checklist

- [ ] `https://tbone.dev` returns 200 OK
- [ ] SSL certificate is valid (check browser padlock)
- [ ] `http://tbone.dev` redirects to HTTPS
- [ ] `https://www.tbone.dev` redirects to `https://tbone.dev`
- [ ] Security headers present
- [ ] All pages render correctly
- [ ] Images and assets load
- [ ] Dark mode toggle works
- [ ] No mixed content warnings in browser console

---

## Phase 6: Ongoing Deployments

From here on, use deploy-rs for all updates.

### 6.1 Deploy changes

```bash
nix develop  # if not already in dev shell

# Dry run (preview what changes)
deploy .#tbone-web --dry-activate

# Deploy for real
deploy .#tbone-web
```

deploy-rs will:
1. Build the new NixOS configuration + website locally
2. Copy the Nix closure to the VPS over SSH
3. Activate the new configuration
4. Auto-rollback if activation fails or SSH drops mid-deploy

### 6.2 Typical content update workflow

```bash
# Edit content
cd web
vim src/content/blog/my-new-post.md

# Test locally
bun run build && bun run preview

# Deploy
cd ..
deploy .#tbone-web
```

### 6.3 Update Nix inputs (nixpkgs, etc.)

```bash
nix flake update
deploy .#tbone-web
```

### 6.4 Update Bun dependencies

```bash
cd web
bun update
bun2nix    # regenerate bun.nix from the updated bun.lock
cd ..
nix build .#website  # sanity check
deploy .#tbone-web
```

---

## Rollback

### Automatic

deploy-rs monitors the activation over SSH. If activation fails or the connection drops, it automatically rolls back to the previous configuration. No action needed.

### Manual

```bash
ssh -i ~/.ssh/tbone-web-deploy root@tbone.dev

# List available system generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to a previous generation (replace N with the number)
/nix/var/nix/profiles/system-N-link/bin/switch-to-configuration switch
```

---

## Server Maintenance

### SSH access

```bash
ssh -i ~/.ssh/tbone-web-deploy root@tbone.dev
```

### Useful commands on the server

```bash
# Service status
systemctl status caddy

# Live Caddy logs
journalctl -u caddy -f

# Disk usage
df -h

# Current NixOS generation
nixos-version

# Manual garbage collection (auto runs weekly)
nix-collect-garbage -d
```

### Secrets (future)

agenix is configured but not yet active. When you need secrets (API keys, etc.):

1. Generate an age key: `age-keygen -o ~/.config/age/keys.txt`
2. Get the server's host key: `ssh root@tbone.dev cat /etc/ssh/ssh_host_ed25519_key.pub`
3. Convert to age: `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`
4. Create `secrets/secrets.nix` with recipient public keys
5. Encrypt: `agenix -e secrets/tbone-web/my-secret.age`
6. Reference in `nix/hosts/tbone-web/default.nix` under `age.secrets`

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Permission denied (publickey)` | SSH key mismatch | Update key in `default.nix`, redeploy |
| nixos-anywhere: "device not found" | Wrong disk device | SSH in via provider console, run `lsblk` |
| SSL cert not provisioning | DNS not pointed yet | `dig tbone.dev` — wait for propagation |
| `deploy` connection refused | Firewall or SSH issue | Check port 22 open, verify hostname resolves |
| Build fails on bun deps | `bun.nix` out of date | `cd web && bun2nix` then rebuild |
| Site content not updating | Nix store path unchanged | Check `nix path-info .#website` changed |
| Caddy errors in logs | Config syntax issue | `journalctl -u caddy -n 50` for details |
| Out of disk space | Nix store full | `ssh root@tbone.dev nix-collect-garbage -d` |

---

## Architecture Quick Reference

```
flake.nix                            Single composition root
  inputs:
    nixpkgs                          NixOS packages (unstable)
    disko                            Declarative disk partitioning
    agenix                           Encrypted secrets management
    deploy-rs                        Push-based NixOS deployment
    bun2nix                          Bun package management for Nix

  outputs:
    packages.x86_64-linux.website    Static site (Bun + Astro -> dist/)
    devShells (4 systems)            Dev tools for all platforms
    nixosConfigurations.tbone-web    Full server configuration
    deploy.nodes.tbone-web           deploy-rs target

nix/hosts/tbone-web/
  default.nix                        Caddy, SSH, firewall, system packages
  disko.nix                          GPT: BIOS + EFI + ext4 root

nix/packages/
  website.nix                        callPackage derivation for Astro build

web/                                 Astro source code
  src/content/blog/                  Blog posts (Markdown/MDX)
  src/components/                    Astro components
  src/pages/                         File-based routing
  bun.nix                            Generated Bun dependency hashes
  bun.lock                           Bun lockfile
```
