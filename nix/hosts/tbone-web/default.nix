{
  pkgs,
  self,
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
        root * ${self.packages.x86_64-linux.website}
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

  # sops-nix: derive age key from host SSH key
  # Uncomment and configure once secrets/tbone-web.yaml exists and is encrypted.
  # sops = {
  #   defaultSopsFile = ../../../secrets/tbone-web.yaml;
  #   age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  #   secrets.api_key = {
  #     owner = "caddy";
  #     group = "caddy";
  #     mode = "0400";
  #   };
  # };

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
