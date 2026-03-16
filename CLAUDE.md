# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

This is a monorepo with the Astro web project living under `web/`. The repo root contains a Nix flake and direnv config. All web development commands run from the `web/` directory.

## Commands

```bash
# All commands run from web/
cd web

bun install          # Install dependencies
bun run dev          # Dev server at localhost:4321
bun run build        # Production build to ./dist/
bun run preview      # Preview production build
bun run astro -- --help  # Astro CLI
```

No automated tests are configured. Verify changes with `bun run build`.

## Architecture

**Framework:** Astro 5 (static site generation), TypeScript strict mode, Bun package manager.

**Content system:** Three Astro Content Collections defined in `src/content.config.ts`:

- `blog` — Markdown/MDX posts in `src/content/blog/` with Zod-validated frontmatter (title, description, pubDate required; tags, author, draft, featured optional)
- `authors` — JSON files in `src/content/authors/`
- `tags` — JSON metadata in `src/content/tags/`

**Routing:** File-based in `src/pages/`. Dynamic routes use `[...slug].astro` for blog posts and `[tag].astro` for tag filtering. RSS feed at `rss.xml.js`.

**Key integrations:** `@astrojs/mdx`, `@astrojs/rss`, `@astrojs/sitemap`, Three.js (3D moon/sun theme toggle in `Moon.astro`).

**Utilities:** `src/lib/utils.ts` has reading time calculation, date formatting, tag extraction, and related posts by tag similarity.

**Styling:** CSS custom properties in `src/styles/global.css`. Dark mode via `.dark` class on `<html>` with localStorage persistence. Responsive breakpoint at 720px. Atkinson Hyperlegible font.

**Site constants:** `src/consts.ts` exports `SITE_TITLE` and `SITE_DESCRIPTION`. Site URL configured in `astro.config.mjs`.

## Conventions

- Components: PascalCase `.astro` files. Pages: lowercase. Content: kebab-case `.md`/`.mdx`.
- Component props typed via `interface Props` in frontmatter fence.
- Scoped `<style>` tags in components; global variables available everywhere.
- Use `import type` for type-only imports.
- Draft posts (`draft: true`) should be filtered from public listings.
