# sops-nix and age Resources

A curated list of official documentation, tutorials, and community resources.

---

## Official Documentation

### sops-nix (NixOS Integration)
| Resource | URL | Description |
|----------|-----|-------------|
| **GitHub Repository** | https://github.com/Mic92/sops-nix | Official repo with full README |
| **NixOS Wiki** | https://wiki.nixos.org/wiki/Sops | NixOS-specific setup guide |

### SOPS (Mozilla)
| Resource | URL | Description |
|----------|-----|-------------|
| **Official Docs** | https://getsops.io/docs/ | Complete SOPS documentation |
| **GitHub** | https://github.com/getsops/sops | SOPS source code and README |

### age (Encryption Tool)
| Resource | URL | Description |
|----------|-----|-------------|
| **GitHub** | https://github.com/FiloSottile/age | Official age repository |
| **age-encryption.org** | https://age-encryption.org/v1 | Format specification |
| **age man page** | `man age` (if installed) | Command-line reference |

---

## Quick Reference

### Essential Commands

```bash
# Generate age key pair
age-keygen -o ~/.config/sops/age/keys.txt

# View public key
age-keygen -y ~/.config/sops/age/keys.txt

# Convert SSH key to age
ssh-to-age -i ~/.ssh/id_ed25519.pub
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt

# Create/edit encrypted secrets
sops secrets/tbone-web.yaml

# Decrypt to stdout
sops decrypt secrets/tbone-web.yaml

# Re-key when adding/removing recipients
sops updatekeys secrets/tbone-web.yaml
```

### File Locations

| File | Purpose |
|------|---------|
| `~/.config/sops/age/keys.txt` | Your private age key |
| `secrets/.sops.yaml` | Key definitions (public keys only) |
| `secrets/*.yaml` | Encrypted secrets |
| `/run/secrets/` | Decrypted secrets on NixOS host |

---

## Video Tutorials

| Title | Author | Platform | Length |
|-------|--------|----------|--------|
| **sops-nix Tutorial** | vimjoyer | YouTube | ~6 min |
| **SOPS Introduction** | Mozilla (official) | YouTube | Various |

Search: `vimjoyer sops-nix` on YouTube for a great quickstart.

---

## Blog Posts & Articles

### sops-nix Specific
- **"Nix secrets for dummies"** by Farid Zakaria  
  https://fzakaria.com/2024/07/12/nix-secrets-for-dummies  
  *Beginner-friendly guide focusing on agenix but covers concepts well*

- **"NixOS Secrets Management"** by Unmoved Centre  
  https://unmovedcentre.com/posts/secrets-management/  
  *Complete walkthrough with sops-nix + home-manager*

- **"Handling Secrets in NixOS: An Overview"** by lgug2z  
  https://lgug2z.com/articles/handling-secrets-in-nixos-an-overview/  
  *Compares git-crypt, agenix, and sops-nix*

### SOPS General
- **Official SOPS Examples**  
  https://github.com/getsops/sops/tree/master/examples  
  *CI/CD integration examples*

---

## Related Projects & Alternatives

| Project | Description | URL |
|---------|-------------|-----|
| **agenix** | Simpler age-based alternative | https://github.com/ryantm/agenix |
| **ragenix** | Rust implementation of agenix | https://github.com/yaxitech/ragenix |
| **secrix** | Minimal decryption time focus | https://github.com/ohkrab/secrix |
| **git-crypt** | Git-transparent encryption | https://github.com/AGWA/git-crypt |

---

## Tools & Utilities

| Tool | Purpose | Installation |
|------|---------|--------------|
| `sops` | Edit encrypted files | `nix-shell -p sops` |
| `age` | Encryption tool | `nix-shell -p age` |
| `ssh-to-age` | Convert SSH keys to age | `nix-shell -p ssh-to-age` |
| `age-keygen` | Generate age keys | Included with `age` |

---

## Community & Support

### Discourse & Forums
- **NixOS Discourse** - Search "sops-nix" or "secrets"  
  https://discourse.nixos.org/

### Matrix/IRC
- **NixOS Matrix**: #nix:nixos.org  
- **NixOS IRC**: #nixos on Libera.Chat

### Commercial Support
- **Numtide** - Nix consulting (sops-nix contributors)  
- **Helsinki Systems** - NixOS support

---

## NixOS Options Reference

Key `sops` options in `configuration.nix`:

```nix
sops = {
  # Path to encrypted secrets file
  defaultSopsFile = ./secrets.yaml;
  
  # Key source for decryption
  age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  # OR
  age.keyFile = "/var/lib/sops-nix/key.txt";
  age.generateKey = true;
  
  # Individual secrets
  secrets.my_secret = {
    owner = "caddy";
    group = "caddy";
    mode = "0400";
    path = "/var/lib/app/secret";  # Symlink target
    restartUnits = [ "myapp.service" ];
    neededForUsers = true;  # For user passwords
  };
  
  # Templates for config file substitution
  templates.my_config = {
    content = ''
      password = "${config.sops.placeholder.my_secret}"
    '';
    owner = "caddy";
  };
};
```

---

## .sops.yaml Reference

```yaml
keys:
  # Define recipients with YAML anchors
  - &server age1...      # Server key (from SSH)
  - &admin age1...       # Your personal key
  - &backup age1...      # Backup key

creation_rules:
  # Match by path regex
  - path_regex: secrets/production\.yaml$
    key_groups:
      - age:
          - *server
          - *admin
          - *backup
  
  # Different keys for different environments
  - path_regex: secrets/staging\.yaml$
    key_groups:
      - age:
          - *server
          - *admin
```

---

## Troubleshooting Resources

### Common Issues

| Error | Solution |
|-------|----------|
| `no valid keys found` | Check `~/.config/sops/age/keys.txt` exists |
| `failed to decrypt` | Verify key is in `.sops.yaml` recipients |
| `Cannot decrypt data key` | Run `sops updatekeys` after adding keys |
| Secrets not at `/run/secrets/` | Check `systemctl status sops-nix` |

### Debug Commands

```bash
# Check sops-nix service status
systemctl status sops-nix

# View sops-nix logs
journalctl -u sops-nix -n 50

# Verify age key is detected
sops decrypt secrets/tbone-web.yaml

# Check secret permissions
ls -la /run/secrets/

# Inspect encrypted file metadata
sops decrypt --verbose secrets/tbone-web.yaml
```

---

## Recommended Reading Order

1. **Start here**: vimjoyer's sops-nix video (YouTube)
2. **Skim**: sops-nix README (GitHub)
3. **Deep dive**: "Handling Secrets in NixOS: An Overview" article
4. **Reference**: This repo's `SOPS_SETUP.md` file
5. **Advanced**: Official SOPS docs for cloud KMS integration

---

## Contributing

Found a great resource? Add it here and submit a PR!

---

*Last updated: 2026-03-02*
