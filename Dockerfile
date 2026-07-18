# ---- Stage 1: build the static site with Quartz ----
FROM node:22-bookworm-slim AS build
WORKDIR /app

# Install deps first for layer caching
COPY quartz/package.json quartz/package-lock.json* ./
RUN npm ci

# Quartz source + the vault as its content
COPY quartz/ ./
COPY md-notebook/ ./content/

# Domain injected at build time; defaults to localhost for local testing
ARG BASE_URL=localhost
RUN sed -i "s|__BASE_URL__|${BASE_URL}|g" quartz.config.ts

# Outputs static site to /app/public
RUN npx quartz build

# ---- Stage 2: serve the static output over plain HTTP for Traefik ----
FROM nginxinc/nginx-unprivileged:1.27-alpine AS serve
# nginx-unprivileged listens on 8080 as a non-root user by default.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/public /usr/share/nginx/html
EXPOSE 8080
