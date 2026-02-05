# AGENTS.md

This document provides essential information for AI coding agents working on the `tbone.dev` project.

## Project Overview

`tbone.dev` is a personal blog website built with [Astro](https://astro.build/), a modern static site generator. It uses the official Astro "Blog" starter template as its foundation. The project is designed as a minimal, fast, and SEO-friendly blog with support for Markdown and MDX content.

**Key Characteristics:**
- Static site generation (SSG) - no server-side runtime required
- Content-focused architecture using Astro Content Collections
- Minimal styling with clean, readable typography
- 100/100 Lighthouse performance target

## Technology Stack

| Category | Technology | Version |
|----------|------------|---------|
| Framework | Astro | ^5.17.1 |
| Language | TypeScript | Strict mode |
| Module System | ES Modules | `"type": "module"` |
| Package Manager | Bun | (via `bun.lock`) |
| Styling | CSS | Custom properties, scoped styles |
| Image Processing | Sharp | ^0.34.3 |

**Astro Integrations:**
- `@astrojs/mdx` - MDX support for interactive content
- `@astrojs/rss` - RSS feed generation
- `@astrojs/sitemap` - XML sitemap generation

## Project Structure

```
├── public/                 # Static assets (copied as-is to dist/)
│   ├── favicon.ico
│   ├── favicon.svg
│   └── fonts/              # Atkinson Hyperlegible Font files
├── src/
│   ├── assets/             # Image assets processed by Astro
│   │   └── blog-placeholder-*.jpg
│   ├── components/         # Reusable Astro components
│   │   ├── BaseHead.astro      # HTML <head> with SEO meta tags
│   │   ├── Footer.astro        # Site footer
│   │   ├── FormattedDate.astro # Date formatting component
│   │   ├── Header.astro        # Site header with navigation
│   │   └── HeaderLink.astro    # Navigation link with active state
│   ├── content/            # Content collections
│   │   └── blog/           # Blog posts (.md, .mdx)
│   ├── layouts/            # Page layout templates
│   │   └── BlogPost.astro      # Layout for individual blog posts
│   ├── pages/              # File-based routing
│   │   ├── index.astro         # Homepage
│   │   ├── about.astro         # About page
│   │   ├── rss.xml.js          # RSS feed endpoint
│   │   └── blog/
│   │       ├── index.astro     # Blog listing page
│   │       └── [...slug].astro # Dynamic blog post routes
│   ├── styles/
│   │   └── global.css          # Global styles, CSS variables
│   ├── consts.ts           # Global constants (SITE_TITLE, etc.)
│   └── content.config.ts   # Content collection schemas
├── astro.config.mjs        # Astro configuration
├── package.json            # Dependencies and scripts
├── tsconfig.json           # TypeScript configuration
└── bun.lock                # Bun lockfile
```

## Build and Development Commands

All commands are run from the project root:

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
```

**Note:** The project uses Bun as the package manager (evidenced by `bun.lock`), but standard npm/yarn commands will also work.

## Content Management

### Blog Posts

Blog posts are stored in `src/content/blog/` and can be `.md` (Markdown) or `.mdx` (MDX) files.

**Frontmatter Schema** (defined in `src/content.config.ts`):
```yaml
---
title: string           # Required: Post title
description: string     # Required: Post description
pubDate: Date          # Required: Publication date (e.g., 'Jul 08 2022')
updatedDate: Date      # Optional: Last updated date
heroImage: string      # Optional: Path to hero image (relative to src/assets/)
---
```

**Example blog post:**
```markdown
---
title: 'My First Post'
description: 'A description of my post'
pubDate: 'Jul 08 2022'
heroImage: '../../assets/blog-placeholder-1.jpg'
---

Your content here...
```

### Content Collections

The project uses Astro's Content Collections API with Zod schema validation:
- Type-safe access to content via `getCollection()`
- Automatic type generation for frontmatter
- Schema defined in `src/content.config.ts`

## Code Style Guidelines

### TypeScript

- **Strict mode enabled** - All strict TypeScript options are active
- Use explicit types for component props via interfaces
- Import types separately: `import type { CollectionEntry } from 'astro:content'`

### Astro Components

- Use `---` frontmatter fences for server-side JavaScript/TypeScript
- Access props via `Astro.props`
- Use scoped `<style>` tags for component-specific styles
- CSS variables are defined in `src/styles/global.css` and available globally

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
- **Typography**: Atkinson Hyperlegible Font (accessibility-focused)
- **Responsive breakpoint**: 720px (mobile-first approach)
- Component styles are scoped by default in Astro

### File Naming

- Components: PascalCase (e.g., `BaseHead.astro`)
- Pages: lowercase with `.astro` extension
- Content: kebab-case with `.md` or `.mdx` extension
- Layouts: PascalCase with descriptive names

## Key Configuration Details

### astro.config.mjs

```javascript
export default defineConfig({
  site: 'https://example.com',  // ⚠️ UPDATE THIS for production
  integrations: [mdx(), sitemap()],
});
```

**Important:** The `site` URL must be updated before deployment. It affects:
- Canonical URLs
- RSS feed links
- Sitemap URLs
- OpenGraph/Twitter card images

### tsconfig.json

- Extends `astro/tsconfigs/strict`
- Includes strict null checks
- Excludes `dist/` directory

### Global Constants (src/consts.ts)

```typescript
export const SITE_TITLE = 'Astro Blog';  // Update for your site
export const SITE_DESCRIPTION = 'Welcome to my website!';
```

Update these constants to match your site's branding.

## SEO and Meta Tags

The `BaseHead.astro` component handles all SEO meta tags:
- Canonical URLs
- OpenGraph / Facebook meta tags
- Twitter Card meta tags
- RSS feed link
- Sitemap link
- Font preloading

**Props for BaseHead:**
- `title` (required): Page title
- `description` (required): Page description
- `image` (optional): Hero image for social sharing

## Testing Strategy

This project does not currently include automated tests. Recommended testing approach:

1. **Manual testing**: Run `bun run build` and `bun run preview` to verify production build
2. **Lighthouse**: Check performance, accessibility, SEO, and best practices
3. **Visual regression**: Compare pages across different viewport sizes
4. **Link checking**: Verify all internal and external links work

## Deployment

The project outputs a static site to the `dist/` directory.

**Build output:**
- All pages pre-rendered as HTML
- Assets hashed for cache busting
- Images optimized by Sharp
- Sitemap and RSS feed generated

**Deployment targets:**
- Any static hosting (Vercel, Netlify, Cloudflare Pages, GitHub Pages, etc.)
- Ensure the `site` config in `astro.config.mjs` matches your deployment URL

## Security Considerations

- No server-side code - pure static output minimizes attack surface
- No environment variables exposed to client (build-time only)
- User-generated content (blog posts) should be reviewed before publishing
- External links in Header/Footer point to Astro's social accounts - update as needed

## Common Tasks

### Adding a New Blog Post

1. Create a new `.md` or `.mdx` file in `src/content/blog/`
2. Add required frontmatter (title, description, pubDate)
3. Optional: Add heroImage (path relative to src/assets/)
4. Write content in Markdown/MDX
5. Build and verify: `bun run build && bun run preview`

### Adding a New Page

1. Create a new `.astro` file in `src/pages/`
2. Import and use `BaseHead`, `Header`, and `Footer` components
3. Add page-specific styles in a scoped `<style>` tag
4. Update navigation in `src/components/Header.astro` if needed

### Customizing Styles

1. Global CSS variables: Edit `src/styles/global.css`
2. Component styles: Edit the `<style>` block in the component
3. Layout styles: Edit `src/layouts/BlogPost.astro` style block

### Updating Site Metadata

1. Update `SITE_TITLE` and `SITE_DESCRIPTION` in `src/consts.ts`
2. Update `site` URL in `astro.config.mjs`
3. Update copyright in `src/components/Footer.astro`
4. Update social links in `Header.astro` and `Footer.astro`

## External Resources

- [Astro Documentation](https://docs.astro.build/)
- [Astro Content Collections](https://docs.astro.build/en/guides/content-collections/)
- [MDX Documentation](https://mdxjs.com/)
- [Atkinson Hyperlegible Font](https://www.brailleinstitute.org/freefont/)
