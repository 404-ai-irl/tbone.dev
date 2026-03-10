{
  pkgs,
  websitePackage,
  ...
}:
{
  imports = [
    ./disko.nix
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "tbone-web";
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6HvgsduI049k/7HDTt0I/Nyr3/C2FHNzV2N8DwfCfb tbone-web-deploy"
  ];

  # Caddy serves the Nix-built static site
  services.caddy = {
    enable = true;
    virtualHosts."www.tbone.dev" = {
      extraConfig = ''
        redir https://tbone.dev{uri} permanent
      '';
    };
    virtualHosts."tbone.dev" = {
      extraConfig = ''
        root * ${websitePackage}
        file_server
        encode gzip zstd

        header {
          X-Content-Type-Options nosniff
          X-Frame-Options DENY
          Referrer-Policy strict-origin-when-cross-origin
        }

        @immutable path /_astro/*
        header @immutable Cache-Control "public, max-age=31536000, immutable"

        @html {
          path *.html
          path /
        }
        header @html Cache-Control "public, max-age=3600, must-revalidate"
      '';
    };
  };

  # agenix: encrypted secrets management
  # Uncomment and configure once secrets are created and encrypted.
  # age.secrets = {
  #   # Example secret - update path and settings as needed
  #   # api_key = {
  #   #   file = ../../../secrets/tbone-web/api_key.age;
  #   #   owner = "caddy";
  #   #   group = "caddy";
  #   #   mode = "0400";
  #   # };
  # };
  #
  # To add secrets:
  # 1. Generate an age key: age-keygen -o ~/.config/age/keys.txt
  # 2. Create secrets/secrets.nix with recipient public keys
  # 3. Encrypt: agenix -e secrets/tbone-web/api_key.age
  # 4. Reference in age.secrets above

  system.stateVersion = "25.05";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];
}
