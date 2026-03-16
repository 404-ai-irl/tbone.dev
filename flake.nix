{
  description = "tbone.dev website flake";

  inputs = {
    # keep-sorted start
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";
    bun2nix.url = "github:nix-community/bun2nix";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    # keep-sorted end
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.bun2nix.overlays.default ];
          };
          imports = [ ./dev/shell.nix ];
          treefmt = import ./dev/treefmt.nix;
        };

      flake =
        let
          deploySystem = "x86_64-linux";
          pkgs = import inputs.nixpkgs {
            system = deploySystem;
            overlays = [ inputs.bun2nix.overlays.default ];
          };
          websitePackage = pkgs.callPackage ./nix/packages/website.nix { };
        in
        {
          packages.${deploySystem} = {
            website = websitePackage;
            default = websitePackage;
          };

          nixosConfigurations.tbone-web = inputs.nixpkgs.lib.nixosSystem {
            system = deploySystem;
            specialArgs = {
              inherit websitePackage;
            };
            modules = [
              inputs.disko.nixosModules.disko
              inputs.agenix.nixosModules.default
              ./nix/hosts/tbone-web
            ];
          };

          deploy.nodes.tbone-web = {
            hostname = "tbone.dev";
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${deploySystem}.activate.nixos self.nixosConfigurations.tbone-web;
            };
          };

          checks = builtins.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
        };
    };
}
