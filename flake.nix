{
  description = "tbone.dev website flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    sops-nix,
    bun2nix,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [bun2nix.overlays.default];
    };
  in {
    packages.${system} = {
      website = pkgs.stdenv.mkDerivation {
        pname = "tbone-dev";
        version = "0.0.1";
        src = ./web;

        nativeBuildInputs = [pkgs.bun pkgs.bun2nix.hook pkgs.autoPatchelfHook];
        buildInputs = [pkgs.vips pkgs.glib pkgs.stdenv.cc.cc.lib];

        bunDeps = pkgs.bun2nix.fetchBunDeps {
          bunNix = ./web/bun.nix;
        };

        # Astro uses its own build command, not `bun build`
        dontUseBunBuild = true;
        dontUseBunCheck = true;
        # We copy dist/ ourselves, not a standalone binary
        dontUseBunInstall = true;

        # Musl variants of sharp are unused on glibc — skip their missing deps
        autoPatchelfIgnoreMissingDeps = ["libc.musl-*"];

        # Patch sharp native binaries before build (autoPatchelfHook only runs in fixupPhase)
        preBuild = ''
          autoPatchelf node_modules
        '';

        buildPhase = ''
          runHook preBuild
          bun run build
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp -r dist $out
          runHook postInstall
        '';
      };

      default = self.packages.${system}.website;
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.bun
        pkgs.nodejs
        pkgs.bun2nix
        pkgs.sops
        pkgs.age
      ];
    };

    nixosConfigurations.tbone-web = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit self;};
      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./nix/hosts/tbone-web
      ];
    };
  };
}
