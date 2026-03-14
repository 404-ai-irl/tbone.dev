# Stage 1: Build the Astro static site with Bun
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

# Stage 2: Serve with Nginx
FROM nginx:alpine AS runtime
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
