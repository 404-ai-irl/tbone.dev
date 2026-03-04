# sops-nix Setup Guide for tbone.dev

This guide walks you through setting up sops-nix for encrypted secrets management.

**Current Status:** ✅ sops-nix is already configured in your flake and NixOS module. You just need to generate keys and create secrets.

---

## Project-Level vs System-Level sops-nix

### Project-Level (Flake-level)
Used for secrets needed **during build time** or in the **development environment**.

```nix
# In flake.nix - for dev shells or build-time secrets
{
  devShells.default = pkgs.mkShell {
    # Inject secrets as env vars for local development
    MY_API_KEY = builtins.readFile ./secrets/api-key.txt;
  };
}
```

**Characteristics:**
- Secrets accessible during `nix build`, `nix develop`
- Secrets may end up in the nix store (if not careful)
- Used for: API keys in dev shells, build-time credentials
- **Not recommended for production server secrets**

### System-Level (NixOS-level) ← **YOU ARE USING THIS**
Used for secrets needed **on the running server** by services.

```nix
# In nix/hosts/tbone-web/default.nix
{
  sops = {
    defaultSopsFile = ../../../secrets/tbone-web.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
  
  # Secrets are available at runtime
  sops.secrets.my_password = {};
}
```

**Characteristics:**
- Secrets stay encrypted in `/nix/store`
- Decrypted at system activation to `/run/secrets/`
- Accessible only to specified users/services
- **Recommended for all production secrets**

### Summary Table

| Aspect | Project-Level | System-Level |
|--------|--------------|--------------|
| **When decrypted** | Build/eval time | System activation |
| **Storage** | May be in store | Encrypted in store |
| **Runtime access** | ❌ | ✅ via `/run/secrets/` |
| **Use case** | Dev shells, builds | Service credentials |
| **Security** | Lower | Higher |

---

## Step-by-Step Setup

### Step 1: Generate Your Personal age Key

This key will let you encrypt/decrypt secrets on your development machine.

```bash
# Create config directory
mkdir -p ~/.config/sops/age

# Generate age key pair
age-keygen -o ~/.config/sops/keys.txt

# View your public key (starts with age1...)
age-keygen -y ~/.config/sops/keys.txt
```

**Output example:**
```
age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9cqmc682
```

Copy this public key - you'll need it in Step 3.

---

### Step 2: First Deploy (Without Secrets)

Deploy the server first so we can extract its SSH host key.

```bash
# Deploy using nixos-anywhere (this won't use secrets yet)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#tbone-web \
  --disk main /dev/sda \
  root@<server-ip>
```

Wait for deployment to complete and server to reboot.

---

### Step 3: Extract Server's age Key

After the server is running, extract its SSH host key and convert to age format:

```bash
# Get the server's SSH public key and convert to age
ssh root@<server-ip> "cat /etc/ssh/ssh_host_ed25519_key.pub" | \
  nix run nixpkgs#ssh-to-age
```

**Output example:**
```
age1s3q0z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9cqmxyz
```

---

### Step 4: Update .sops.yaml

Edit `secrets/.sops.yaml` and replace the placeholders:

```yaml
keys:
  # Server age key (from Step 3)
  - &server age1s3q0z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9cqmxyz

  # Your personal age key (from Step 1)
  - &admin age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9cqmc682

creation_rules:
  - path_regex: secrets/tbone-web\.yaml$
    key_groups:
      - age:
          - *server
          - *admin
```

Save the file and commit it (it's safe to commit - only public keys).

---

### Step 5: Create Your First Secret

Enter the dev shell (which has `sops` installed):

```bash
nix develop
```

Create the secrets file:

```bash
# Create/edit the encrypted secrets file
sops secrets/tbone-web.yaml
```

This opens your `$EDITOR`. Enter secrets in YAML format:

```yaml
# Example secrets
database:
  password: "my-super-secret-db-password"
  
api:
  key: "sk-abcdef123456"
  
# For Caddy basic auth (if needed later)
admin_password: "$2a$14$..."  # bcrypt hash
```

Save and exit. The file is automatically encrypted.

**Verify it's encrypted:**
```bash
cat secrets/tbone-web.yaml
# Should show encrypted content starting with:
# database:
#     password: ENC[AES256_GCM,data:...,iv:...,type:str]
```

---

### Step 6: Configure Secrets in NixOS

Edit `nix/hosts/tbone-web/default.nix` to declare which secrets to use:

```nix
{
  # sops-nix configuration
  sops = {
    defaultSopsFile = ../../../secrets/tbone-web.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    
    # Declare secrets - each becomes a file in /run/secrets/
    secrets = {
      # Simple secret
      db_password = {
        # Available at /run/secrets/db_password
        owner = "caddy";  # Which user owns the file
        group = "caddy";
        mode = "0400";    # Read-only
      };
      
      # Secret that needs a specific path
      api_key = {
        owner = "caddy";
        group = "caddy";
        mode = "0400";
        # Creates symlink from /var/lib/myapp/api_key to /run/secrets/api_key
        path = "/var/lib/myapp/api_key";
      };
      
      # Secret for template substitution
      admin_password = {
        owner = "caddy";
        group = "caddy";
        mode = "0400";
      };
    };
    
    # Templates: substitute secrets into config files
    templates = {
      "caddy-envfile" = {
        content = ''
          DATABASE_PASSWORD="${config.sops.placeholder.db_password}"
          API_KEY="${config.sops.placeholder.api_key}"
        '';
        owner = "caddy";
        group = "caddy";
        mode = "0400";
      };
    };
  };
  
  # Use secrets in services
  services.caddy = {
    # Reference template in Caddy config
    virtualHosts."api.tbone.dev".extraConfig = ''
      reverse_proxy localhost:8080
      basicauth {
        admin ${config.sops.placeholder.admin_password}
      }
    '';
  };
}
```

---

### Step 7: Deploy with Secrets

```bash
# Deploy the updated configuration
nixos-rebuild switch --flake .#tbone-web --target-host root@<server-ip>
```

---

### Step 8: Verify Secrets on Server

SSH into the server and verify:

```bash
ssh root@<server-ip>

# Check secrets exist and are decrypted
ls -la /run/secrets/

# View a secret (as root)
cat /run/secrets/db_password

# Check permissions
ls -la /run/secrets/db_password
# Should show: -r-------- 1 caddy caddy ...

# Check template was created
ls -la /run/secrets/caddy-envfile
```

---

## Common Operations

### Edit Existing Secrets

```bash
nix develop
sops secrets/tbone-web.yaml
# Edit and save
```

Then redeploy:
```bash
nixos-rebuild switch --flake .#tbone-web --target-host root@<server-ip>
```

### Add a New Secret

1. Edit `secrets/tbone-web.yaml` with sops
2. Declare it in `nix/hosts/tbone-web/default.nix`
3. Redeploy

### Rotate/Change a Secret

```bash
sops secrets/tbone-web.yaml
# Change the value
# Save and redeploy
```

### Add Another Admin (Re-key)

If you need another person to access secrets:

1. Get their age public key
2. Add to `secrets/.sops.yaml`:

```yaml
keys:
  - &server age1...
  - &admin age1...        # Your key
  - &colleague age1...    # New person's key

creation_rules:
  - path_regex: secrets/tbone-web\.yaml$
    key_groups:
      - age:
          - *server
          - *admin
          - *colleague    # Add here
```

3. Re-key the secrets file:

```bash
sops updatekeys secrets/tbone-web.yaml
```

---

## Directory Structure

```
.
├── flake.nix                    # Has sops-nix input + module
├── secrets/
│   ├── .sops.yaml               # Key definitions (public keys only)
│   └── tbone-web.yaml           # Encrypted secrets
└── nix/hosts/tbone-web/
    └── default.nix              # sops secrets configuration
```

---

## Security Notes

1. **What's safe to commit:**
   - ✅ `secrets/.sops.yaml` (only public keys)
   - ✅ `secrets/tbone-web.yaml` (encrypted)

2. **What's NOT safe to commit:**
   - ❌ `~/.config/sops/age/keys.txt` (your private key!)
   - ❌ Any unencrypted secrets

3. **Secret locations:**
   - Encrypted: In `/nix/store` (safe, encrypted)
   - Decrypted: In `/run/secrets/` (tmpfs, cleared on reboot)
   - Templates: In `/run/secrets/` (with substituted values)

4. **Permissions:**
   - Always set `owner`, `group`, and `mode` for each secret
   - Use least-privilege (e.g., `0400` = read-only for owner)

---

## Troubleshooting

### "Failed to decrypt: no valid keys found"

Your age private key isn't available. Ensure:
```bash
# Check key exists
ls ~/.config/sops/age/keys.txt

# Check SOPS can find it
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops secrets/tbone-web.yaml
```

### "Cannot decrypt data key with master key"

The server's SSH key changed or wasn't added to `.sops.yaml` correctly.

### Secrets not appearing on server

Check systemd service:
```bash
ssh root@<server-ip>
systemctl status sops-nix
journalctl -u sops-nix -n 50
```

### Wrong file permissions

Check your secret definition:
```nix
sops.secrets.my_secret = {
  owner = "caddy";    # Must be a valid user
  group = "caddy";    # Must be a valid group
  mode = "0400";      # Octal format
};
```

---

## Next Steps for tbone.dev

Since tbone.dev is a static site, you likely don't need secrets immediately. However, you might want them for:

1. **Caddy basic auth** - Password-protect staging/preview
2. **Analytics** - API keys for Plausible/GoatCounter
3. **Contact forms** - SMTP credentials for sending email
4. **Webhook secrets** - For GitHub/GitLab integrations

When you're ready to add a secret, follow Steps 5-7 above.
