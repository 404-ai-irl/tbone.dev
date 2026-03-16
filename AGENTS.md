# AGENTS.md

This document provides essential information for AI coding agents working on the `tbone.dev` project.

## Project Overview

`tbone.dev` is a personal blog and portfolio website deployed on NixOS. The project consists of:

1. **Web Application**: An Astro 5 static site (located in `web/`) built with Bun
2. **Infrastructure**: NixOS configuration for server deployment using nixos-anywhere
3. **Secret Management**: sops-nix for encrypted secrets

**Key Characteristics:**

- Static site generation (SSG) with Astro 5
- Nix-based reproducible builds and deployment
- Declarative disk partitioning with disko
- Encrypted secret management with sops-nix
- Served by Caddy on NixOS

## Repository Structure

```
.
├── flake.nix                    # Nix flake: inputs, packages, NixOS config
├── flake.lock                   # Nix flake lockfile
├── web/                         # Astro web application
│   ├── src/
│   │   ├── components/          # Astro components (.astro files)
│   │   ├── content/             # Content collections (blog, authors, tags)
│   │   ├── layouts/             # Page layout templates
│   │   ├── pages/               # File-based routing
│   │   ├── lib/                 # Utility functions
│   │   ├── styles/              # Global CSS
│   │   ├── consts.ts            # Site constants
│   │   └── content.config.ts    # Content collection schemas
│   ├── public/                  # Static assets (fonts, favicon)
│   ├── astro.config.mjs         # Astro configuration
│   ├── package.json             # Bun dependencies
│   ├── bun.lock                 # Bun lockfile
│   ├── bun.nix                  # Generated Nix expressions from bun.lock
│   └── tsconfig.json            # TypeScript configuration
├── nix/hosts/tbone-web/
│   ├── default.nix              # NixOS configuration (Caddy, SSH, GRUB)
│   └── disko.nix                # Disk partitioning configuration
├── secrets/
│   └── .sops.yaml               # sops creation rules for age keys
├── .claude/agents/              # Claude Code agent definitions
└── .vscode/                     # VS Code settings and extensions
```

## Technology Stack

### Web Stack (web/)

| Category         | Technology       | Version          |
| ---------------- | ---------------- | ---------------- |
| Framework        | Astro            | ^5.17.1          |
| Language         | TypeScript       | Strict mode      |
| Package Manager  | Bun              | (via `bun.lock`) |
| Integrations     | @astrojs/mdx     | ^4.3.13          |
|                  | @astrojs/rss     | ^4.0.15          |
|                  | @astrojs/sitemap | ^3.7.0           |
| 3D Graphics      | three            | ^0.182.0         |
| Image Processing | sharp            | ^0.34.3          |

### Infrastructure Stack

| Category           | Technology     | Purpose                   |
| ------------------ | -------------- | ------------------------- |
| Build System       | Nix Flakes     | Reproducible builds       |
| Deployment         | nixos-anywhere | Remote NixOS installation |
| Disk Partitioning  | disko          | Declarative disk setup    |
| Secret Management  | sops-nix       | Encrypted secrets         |
| Web Server         | Caddy          | Static file serving       |
| Package Conversion | bun2nix        | Convert bun.lock to Nix   |

## Build and Development Commands

### Web Development (from `web/` directory)

```bash
# Install dependencies
bun install

# Start development server (localhost:4321)
bun run dev

# Build for production (outputs to ./dist/)
bun run build

# Preview production build locally
bun run preview

# Run Astro CLI commands
bun run astro -- [command]

# Type checking
bun run astro check

# Content validation
bun run astro validate
```

### Nix Operations (from repository root)

```bash
# Enter development shell (provides bun, nodejs, bun2nix, sops, age)
nix develop

# Build the website package
nix build .#website

# Build and serve locally (for testing)
nix build .#website && nix run nixpkgs#caddy -- file-server --root result --listen :8080

# Generate bun.nix from bun.lock
cd web && bun2nix -o bun.nix
```

### Testing Strategy

This project does not currently include automated tests. Recommended testing approach:

```bash
# Build verification
bun run build && bun run preview

# Type checking
bun run astro check

# Content validation
bun run astro validate

# Nix build verification
nix build .#website

# Lighthouse performance testing
# Install Lighthouse: npm install -g lighthouse
# Run: lighthouse http://localhost:4321 --output html --output-path=./lighthouse-report.html
```

### Linting and Code Quality

```bash
# Check TypeScript types
bun run astro check

# Validate content collections
bun run astro validate

# Build verification (most comprehensive test)
bun run build
```

### Single Test Commands

Since this project doesn't have automated tests, the closest equivalent is:

```bash
# Validate a single content file
bun run astro validate -- --file src/content/blog/your-post.md

# Type check a single file
bun run astro check -- --file src/components/YourComponent.astro
```

## Deployment

### First Deploy (wipes disk)

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#tbone-web --disk main /dev/sda root@<ip>
```

### Subsequent Updates

```bash
nixos-rebuild switch --flake .#tbone-web --target-host root@<ip>
```

### Build Pipeline

1. `bun2nix` converts `bun.lock` into `bun.nix` (per-package `fetchurl` calls)
2. `bun2nix.hook` installs dependencies from the pre-fetched cache (no network)
3. `autoPatchelf` patches sharp's native binaries for NixOS before build
4. `bun run build` produces static output in `dist/`
5. `dist/` is copied to the Nix store as the package output
6. Caddy config references the store path directly: `root * ${self.packages...website}`

## Content Management

### Blog Posts

Blog posts are stored in `web/src/content/blog/` as `.md` or `.mdx` files.

**Frontmatter Schema** (defined in `web/src/content.config.ts`):

```yaml
---
title: string # Required: Post title
description: string # Required: Post description
pubDate: Date # Required: Publication date
updatedDate: Date # Optional: Last updated date
heroImage: string # Optional: Hero image path (relative to src/assets/)
tags: string[] # Optional: Array of tag slugs
author: string # Optional: Author ID (default: 'tbone')
draft: boolean # Optional: Draft status (default: false)
featured: boolean # Optional: Featured post (default: false)
---
```

### Content Collections

Three Astro Content Collections are defined:

1. **`blog`** - Markdown/MDX posts in `src/content/blog/`
2. **`authors`** - JSON files in `src/content/authors/`
3. **`tags`** - JSON metadata in `src/content/tags/`

Use `getCollection()` from `astro:content` for type-safe access.

## Code Style Guidelines

### TypeScript

- **Strict mode enabled** - All strict TypeScript options are active
- Use explicit types for component props via interfaces
- Import types separately: `import type { CollectionEntry } from 'astro:content'`

### Astro Components

- Components: PascalCase `.astro` files (e.g., `BaseHead.astro`)
- Pages: lowercase `.astro` files (e.g., `index.astro`)
- Content: kebab-case `.md`/`.mdx` files
- Use `---` frontmatter fences for server-side JavaScript/TypeScript
- Access props via `Astro.props`
- Use scoped `<style>` tags for component-specific styles

**Example component structure:**

```astro
---
// Imports and type definitions
interface Props {
  title: string;
}
const { title } = Astro.props;
---

<!-- HTML template -->
<h1>{title}</h1>

<style>
  /* Scoped styles */
  h1 { color: var(--accent); }
</style>
```

### Styling Conventions

- **CSS Variables** (defined in `global.css`):
  - `--accent` / `--accent-dark` - Primary brand colors
  - `--black` / `--gray` / `--gray-light` / `--gray-dark` - Neutral colors
  - `--box-shadow` - Consistent shadow style
  - `--bg-color` / `--text-color` - Theme-aware colors
- **Typography**: Atkinson Hyperlegible Font (accessibility-focused)
- **Responsive breakpoint**: 720px (mobile-first approach)
- Dark mode via `.dark` class on `<html>` with localStorage persistence

### Nix Conventions

- Use `pkgs.lib` for utility functions
- Pin nixpkgs to specific revisions
- Prefer overlays over patching nixpkgs
- Structure derivations to maximize cache hits

## Key Configuration Files

### astro.config.mjs

```javascript
export default defineConfig({
  site: "https://tbone.dev",
  integrations: [mdx(), sitemap()],
});
```

### web/src/consts.ts

```typescript
export const SITE_TITLE = "tbone.dev";
export const SITE_DESCRIPTION =
  "A developer blog about software engineering, web development, and technology.";
```

### nix/hosts/tbone-web/default.nix

- Caddy virtual host configured for `tbone.dev`
- Security headers: X-Content-Type-Options, X-Frame-Options, Referrer-Policy
- Cache control: immutable for `/_astro/*`, 1 hour for HTML
- SSH with key-based auth (placeholder key - must be updated)

## Testing Strategy

This project does not currently include automated tests. Recommended testing approach:

1. **Build verification**: Run `bun run build` and `bun run preview` to verify production build
2. **Nix build**: Run `nix build .#website` to verify the Nix derivation builds successfully
3. **Lighthouse**: Check performance, accessibility, SEO, and best practices
4. **Visual regression**: Compare pages across different viewport sizes
5. **Link checking**: Verify all internal and external links work

## Security Considerations

### Application Security

- No server-side code - pure static output minimizes attack surface
- No environment variables exposed to client (build-time only)
- User-generated content (blog posts) should be reviewed before publishing

### Infrastructure Security

- SSH key-based authentication only (PasswordAuthentication disabled)
- Root login with prohibit-password (key-only)
- Security headers set by Caddy:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy: strict-origin-when-cross-origin`
- sops-nix for encrypted secrets (derive age key from host SSH key)

### Pre-deploy Checklist

- [ ] Replace placeholder SSH key in `nix/hosts/tbone-web/default.nix`
- [ ] Point DNS for `tbone.dev` to server IP
- [ ] After first deploy: extract host age key and populate `secrets/.sops.yaml`

## Claude Code Agents

This repository includes specialized Claude Code agents in `.claude/agents/`:

- **nix-bun-deploy-advisor**: Expert in Nix + Bun deployment patterns, flake configuration, and troubleshooting
- **nix-flake-parts**: Expert in flake-parts framework for structuring complex Nix flakes

Use these agents when working on their respective domains.

## Common Tasks

### Adding a New Blog Post

1. Create a new `.md` or `.mdx` file in `web/src/content/blog/`
2. Add required frontmatter (title, description, pubDate)
3. Optional: Add heroImage, tags, author, draft, featured
4. Write content in Markdown/MDX
5. Build and verify: `cd web && bun run build && bun run preview`

### Adding a New Page

1. Create a new `.astro` file in `web/src/pages/`
2. Import and use `BaseHead`, `Header`, and `Footer` components
3. Add page-specific styles in a scoped `<style>` tag
4. Update navigation in `web/src/components/Header.astro` if needed

### Updating Dependencies

1. `cd web && bun add [package]` or `bun update`
2. `bun2nix -o bun.nix` to regenerate Nix expressions
3. Test with `nix build .#website`

### Updating NixOS Configuration

1. Edit files in `nix/hosts/tbone-web/`
2. Test with `nixos-rebuild switch --flake .#tbone-web --target-host root@<ip>`

## External Resources

- [Astro Documentation](https://docs.astro.build/)
- [Astro Content Collections](https://docs.astro.build/en/guides/content-collections/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [disko](https://github.com/nix-community/disko)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [bun2nix](https://github.com/nix-community/bun2nix)
- [Atkinson Hyperlegible Font](https://www.brailleinstitute.org/freefont/)
