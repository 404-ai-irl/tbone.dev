// @ts-check

import mdx from "@astrojs/mdx";
import node from "@astrojs/node";
import sitemap from "@astrojs/sitemap";
import icon from "astro-icon";
import { defineConfig } from "astro/config";

// https://astro.build/config
export default defineConfig({
  site: "https://tbone.dev",
  output: "server",
  adapter: node({ mode: "standalone" }),
  integrations: [
    mdx(),
    sitemap(),
    icon({
      include: {
        "simple-icons": ["github", "codeberg", "x", "rss"],
      },
    }),
  ],
});
