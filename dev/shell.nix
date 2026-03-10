{
  pkgs,
  inputs',
  ...
}:
{
  devshells.default = {
    name = "tbone-dev";
    packages = with pkgs; [
      bun
      bun2nix
      inputs'.agenix.packages.default
      age
      nixos-anywhere
      git
      jq
    ];
    commands = [
      {
        name = "dev";
        help = "Start the Astro development server";
        category = "development";
        command = "cd web && bun run dev";
      }
      {
        name = "build";
        help = "Build the website for production";
        category = "development";
        command = "cd web && bun run build";
      }
      {
        name = "preview";
        help = "Preview the production build locally";
        category = "development";
        command = "cd web && bun run preview";
      }
      {
        name = "check";
        help = "Run Astro type checking";
        category = "development";
        command = "cd web && bun run astro check";
      }
      {
        name = "regen-deps";
        help = "Regenerate bun.nix from bun.lock (run after adding/updating deps)";
        category = "development";
        command = "cd web && bun2nix -o bun.nix";
      }
      {
        name = "install";
        help = "Install JavaScript dependencies with bun";
        category = "development";
        command = "cd web && bun install";
      }
      {
        name = "update-deps";
        help = "Update all JavaScript dependencies and regenerate bun.nix";
        category = "development";
        command = "cd web && bun update && bun2nix -o bun.nix";
      }
      {
        name = "nix-build";
        help = "Build the website package with Nix";
        category = "nix";
        command = "nix build .#website";
      }
      {
        name = "nix-build-verbose";
        help = "Build with verbose logs and timing";
        category = "nix";
        command = "nix build .#website -L --verbose";
      }
      {
        name = "deploy";
        help = "Deploy to tbone.dev using deploy-rs";
        category = "deployment";
        command = "nix run .#deploy-rs -- .#tbone-web";
      }
      {
        name = "deploy-dry";
        help = "Dry-run deployment (check what would change)";
        category = "deployment";
        command = "nix run .#deploy-rs -- .#tbone-web --dry-activate";
      }
      {
        name = "deploy-magic";
        help = "Deploy with magic rollback enabled";
        category = "deployment";
        command = "nix run .#deploy-rs -- .#tbone-web --magic-rollback";
      }
      {
        name = "nixos-rebuild";
        help = "Build and activate NixOS config locally (for testing)";
        category = "deployment";
        command = "nixos-rebuild switch --flake .#tbone-web --target-host root@tbone.dev";
      }
      {
        name = "fmt";
        help = "Format all files with treefmt";
        category = "maintenance";
        command = "nix fmt";
      }
      {
        name = "flake-check";
        help = "Run flake checks (includes deploy-rs checks)";
        category = "maintenance";
        command = "nix flake check";
      }
      {
        name = "flake-update";
        help = "Update flake inputs (nixpkgs, etc.)";
        category = "maintenance";
        command = "nix flake update";
      }
      {
        name = "clean";
        help = "Clean build artifacts";
        category = "maintenance";
        command = "rm -rf web/dist result";
      }
      {
        name = "gc";
        help = "Run nix garbage collector";
        category = "maintenance";
        command = "nix-collect-garbage -d";
      }
    ];
  };
}
