# Stage 1: Build the Astro site with Bun
FROM oven/bun:1 AS builder
WORKDIR /app

# Install sharp native dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libvips-dev \
    && rm -rf /var/lib/apt/lists/*

# Install JS dependencies (cached layer unless lockfile changes)
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# Copy source and build
COPY . .
RUN bun run build

# Stage 2: Serve with Astro Node standalone server
FROM oven/bun:1-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/dist ./dist
ENV HOST=0.0.0.0
ENV PORT=3669
EXPOSE 3669
CMD ["bun", "dist/server/entry.mjs"]
