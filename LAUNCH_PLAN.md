# tbone.dev Launch Plan

This document outlines the complete launch process for tbone.dev, from pre-launch verification to post-launch monitoring.

---

## Phase 1: Pre-Launch Verification (Days 1-2)

### 1.1 Content Review

- [ ] Review existing blog post (`welcome-to-tbone-dev.md`)
- [ ] Verify all frontmatter is correct (title, description, pubDate)
- [ ] Check for any placeholder text or TODOs in content
- [ ] Add at least 1-2 more blog posts for launch (recommended)

### 1.2 Site Configuration

- [ ] Verify `SITE_TITLE` and `SITE_DESCRIPTION` in `web/src/consts.ts`
- [ ] Check `astro.config.mjs` site URL is set to `https://tbone.dev`
- [ ] Verify favicon and social meta tags in `BaseHead.astro`

### 1.3 Local Build Testing

```bash
cd web
bun install
bun run build
bun run preview
```

- [ ] Build completes without errors
- [ ] Preview site at `localhost:4321` and verify:
  - [ ] Homepage renders correctly
  - [ ] Blog posts are listed and accessible
  - [ ] Navigation works between pages
  - [ ] Dark mode toggle functions
  - [ ] Responsive design works on mobile viewport

### 1.4 Nix Build Testing

```bash
# From repository root
nix build .#website
```

- [ ] Nix build completes successfully
- [ ] Test local serve: `nix run nixpkgs#caddy -- file-server --root result --listen :8080`
- [ ] Verify site at `localhost:8080`

---

## Phase 2: Infrastructure Preparation (Days 2-3)

### 2.1 Server Requirements

**Minimum Specifications:**
- 1 vCPU
- 512MB RAM (1GB recommended)
- 10GB disk space
- IPv4 address

**Recommended Providers:**
- Hetzner Cloud (CPX11 - ~€4/month)
- DigitalOcean Droplet ($6/month)
- Vultr Cloud Compute ($5/month)

### 2.2 DNS Configuration

At your domain registrar, configure DNS records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | `<server-ip>` | 300 |
| A | www | `<server-ip>` | 300 |

- [ ] DNS A record for `tbone.dev` points to server IP
- [ ] DNS A record for `www.tbone.dev` points to server IP (optional)
- [ ] Wait for DNS propagation (can take up to 24 hours)

### 2.3 SSH Key Preparation

Generate a new SSH key pair for server access (if you don't have one):

```bash
ssh-keygen -t ed25519 -C "tbone-web-deploy" -f ~/.ssh/tbone-web-deploy
```

- [ ] SSH key pair generated
- [ ] Public key: `~/.ssh/tbone-web-deploy.pub`
- [ ] Private key secured with passphrase

### 2.4 Update NixOS Configuration

**CRITICAL:** Update the placeholder SSH key in `nix/hosts/tbone-web/default.nix`:

```nix
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... your-actual-key-here"
];
```

Replace with your actual public key:

```bash
cat ~/.ssh/tbone-web-deploy.pub
```

- [ ] SSH key updated in `default.nix`
- [ ] Configuration committed to git

---

## Phase 3: First Deployment (Day 3)

### 3.1 Prerequisites Check

Ensure you have:
- [ ] Server IP address
- [ ] SSH access to root user with password (for first boot)
- [ ] Nix installed on your local machine with flakes enabled

### 3.2 Test SSH Connectivity

```bash
ssh root@<server-ip>
```

- [ ] Can connect to server via SSH
- [ ] Have root password (for initial connection only)

### 3.3 Deploy with nixos-anywhere

**⚠️ WARNING: This will WIPE the entire disk on the target server.**

```bash
cd /path/to/tbone.dev

nix run github:nix-community/nixos-anywhere -- \
  --flake .#tbone-web \
  --disk main /dev/sda \
  root@<server-ip>
```

Common disk device variations:
- Hetzner Cloud: `/dev/sda` or `/dev/vda`
- DigitalOcean: `/dev/vda`
- Vultr: `/dev/vda`

To check available disks:
```bash
ssh root@<server-ip> lsblk
```

- [ ] nixos-anywhere deployment completes successfully
- [ ] Server reboots automatically

### 3.4 Verify Deployment

After deployment completes (takes 5-15 minutes):

```bash
# Test SSH with new key
ssh -i ~/.ssh/tbone-web-deploy root@<server-ip>

# Check Caddy is running
systemctl status caddy

# Check NixOS version
nixos-version
```

- [ ] SSH login with key works
- [ ] Caddy service is active
- [ ] No firewall blocking ports 80/443

---

## Phase 4: SSL Certificate & Final Verification (Day 3-4)

### 4.1 Initial HTTP Test

Before SSL is configured, test the site over HTTP:

```bash
curl -I http://tbone.dev
```

- [ ] Site responds on port 80
- [ ] Returns 200 OK

### 4.2 Caddy Automatic SSL

Caddy automatically provisions SSL certificates via Let's Encrypt when it receives a request with the correct Host header.

Test HTTPS after a few minutes:

```bash
curl -I https://tbone.dev
```

- [ ] Site responds on port 443
- [ ] SSL certificate is valid
- [ ] Redirect from HTTP to HTTPS works

### 4.3 Final Site Verification

- [ ] Homepage loads with valid SSL
- [ ] All blog posts accessible
- [ ] Images and assets load correctly
- [ ] No mixed content warnings in browser
- [ ] Security headers present (check in DevTools Network tab)

---

## Phase 5: Post-Launch Setup (Days 4-5)

### 5.1 Secret Management Setup (Optional but Recommended)

After first deployment, extract the host's SSH public key to use with sops:

```bash
ssh -i ~/.ssh/tbone-web-deploy root@<server-ip> \
  cat /etc/ssh/ssh_host_ed25519_key.pub
```

Create `secrets/.sops.yaml` with the host key:

```yaml
keys:
  - &host_tbone age1... # derived from SSH host key
creation_rules:
  - path_regex: secrets/tbone-web.yaml$
    key_groups:
      - age:
          - *host_tbone
```

Generate age key from SSH host key:

```bash
ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
```

- [ ] Host SSH key extracted
- [ ] `.sops.yaml` created with proper age key
- [ ] Test secret encryption/decryption

### 5.2 Backup Strategy

- [ ] Document current server provider's backup options
- [ ] Consider enabling automated snapshots (if available)
- [ ] Set up Git repository as source of truth for site content

### 5.3 Monitoring Setup (Optional)

Basic monitoring options:

**Uptime Monitoring (Free):**
- UptimeRobot (free tier: 5-minute checks)
- Pingdom (free tier available)
- HetrixTools (free tier available)

- [ ] Sign up for uptime monitoring service
- [ ] Add `https://tbone.dev` as monitored URL
- [ ] Configure alert notifications (email/Discord/Slack)

---

## Phase 6: Launch Announcement (Day 5+)

### 6.1 Content Preparation

- [ ] Write launch announcement blog post
- [ ] Prepare social media posts
- [ ] Create any launch graphics or assets

### 6.2 Soft Launch

- [ ] Share with close friends/colleagues for feedback
- [ ] Check analytics (if configured)
- [ ] Monitor server logs for any issues

### 6.3 Public Launch

- [ ] Post on relevant social platforms
- [ ] Submit to relevant aggregators (if applicable)
- [ ] Update personal profiles with new site URL

---

## Maintenance & Updates

### Regular Updates

```bash
# Update site content
cd web
# Edit/add blog posts
bun run build

# Deploy updates
nixos-rebuild switch --flake .#tbone-web --target-host root@<server-ip>
```

### Security Updates

```bash
# SSH into server and update
ssh -i ~/.ssh/tbone-web-deploy root@<server-ip>
nixos-rebuild switch --upgrade
```

Or from local machine:
```bash
nixos-rebuild switch --flake .#tbone-web --target-host root@<server-ip> --upgrade
```

---

## Troubleshooting

### Deployment Issues

| Issue | Solution |
|-------|----------|
| `Permission denied (publickey)` | Verify SSH key is correct in `default.nix` |
| `disko` fails with device not found | Check correct disk device (`lsblk` on target) |
| Build fails with bun dependencies | Run `bun2nix -o bun.nix` in `web/` directory |
| Caddy fails to start | Check logs: `journalctl -u caddy -n 50` |

### SSL Issues

| Issue | Solution |
|-------|----------|
| Certificate not provisioned | Ensure DNS points to server; check Caddy logs |
| Certificate expired | Caddy auto-renews; check `systemctl status caddy` |

### Post-Deploy Updates

| Issue | Solution |
|-------|----------|
| Site not updating after rebuild | Run `systemctl restart caddy` on server |
| Nix build fails | Clear `result` symlink: `rm result` and retry |

---

## Checklist Summary

### Before First Deploy
- [ ] Content reviewed and ready
- [ ] Local build tested successfully
- [ ] Nix build tested successfully
- [ ] SSH key updated in `default.nix`
- [ ] Server acquired with known IP
- [ ] DNS A record configured

### During Deploy
- [ ] Tested SSH connectivity
- [ ] Confirmed correct disk device
- [ ] Ran nixos-anywhere successfully
- [ ] Verified server rebooted

### After Deploy
- [ ] SSH key login works
- [ ] HTTP site accessible
- [ ] HTTPS/SSL working
- [ ] All pages functional
- [ ] Uptime monitoring configured (optional)

---

## Emergency Contacts & Resources

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **nixos-anywhere docs**: https://github.com/nix-community/nixos-anywhere
- **Caddy docs**: https://caddyserver.com/docs/
- **Astro docs**: https://docs.astro.build/

---

*Last updated: 2026-03-02*
