---
title: "React Native Monorepo with Turborepo and Expo: A Platform Team's Guide for 2026"
source: "https://reactnativerelay.com/posts/react-native-monorepo-turborepo-expo-platform-team-guide-2026"
author:
  - "[[Yelena Petrov]]"
published: 2026-06-16
created: 2026-07-21
description: "How platform teams structure large-scale React Native apps using Turborepo and Expo for shared packages, parallel builds, and fast CI in 2026."
tags:
  - "clippings"
draft: false
---

As React Native codebases grow, the monorepo question becomes unavoidable. Turborepo has emerged as the go-to build orchestration layer for React Native monorepos in 2026 — here's how platform teams set it up.

## Why a Monorepo for React Native

The core problem: sharing code between a React Native app, a web app, and backend packages while keeping each deployable independently. Options:

- **Separate repos**: painful to keep in sync, no shared types, duplicate dependencies
- **Yarn/pnpm workspaces alone**: works but no build caching or task orchestration
- **Turborepo + pnpm workspaces**: shared packages, build caching, parallel task execution

For teams shipping both a mobile app and a web dashboard, Turborepo cuts CI time by 60–80% via caching.

## The Standard Structure

```
apps/
  mobile/           # Expo React Native app
  web/              # Next.js web app
  admin/            # Internal admin dashboard

packages/
  ui/               # Shared React components (design system)
  api-client/       # Shared API types and fetch helpers
  utils/            # Shared utilities (formatters, validators)
  config/           # Shared ESLint, TypeScript, Tailwind configs
```

Each package is independently versioned (or not, if you use a single-version policy). Shared packages are private — they're consumed by apps but not published to npm.

## Turborepo Configuration

`turbo.json` at the repo root defines task pipelines:

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"]
    }
  }
}
```

The `^build` means "build all dependencies first." Turborepo figures out the dependency graph from `package.json` dependencies and runs tasks in the correct order with maximum parallelism.

## The Metro Bundler Challenge

Metro (React Native's bundler) has limited monorepo awareness. Required configuration in `metro.config.js`:

```js
const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);

// Watch all packages in the monorepo
config.watchFolders = [workspaceRoot];

// Resolve modules from workspace root first
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];

module.exports = config;
```

Without `watchFolders`, changes to shared packages won't trigger hot reloads in the mobile app.

## pnpm with Injected Dependencies

Metro's static require resolution can't follow symlinks the way webpack can. The fix: use pnpm's `dependenciesMeta.injected` to hard-copy shared packages instead of symlinking them.

```json
// apps/mobile/package.json
{
  "dependenciesMeta": {
    "@repo/ui": { "injected": true },
    "@repo/utils": { "injected": true }
  }
}
```

This ensures Metro resolves React and React Native to the mobile app's single copy, preventing "Invalid hook call" errors from duplicate React instances.

## Build Caching in CI

Turborepo's remote caching is the biggest CI time savings. Configure with Vercel's remote cache (free) or self-host:

```yaml
# .github/workflows/ci.yml
- name: Build
  run: pnpm turbo build
  env:
    TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
    TURBO_TEAM: ${{ secrets.TURBO_TEAM }}
```

On cache hit, a full build that took 8 minutes runs in under 30 seconds. The cache key includes source files, environment, and dependency hashes.

## EAS Build in a Monorepo

EAS Build needs to know your app is in a subdirectory. In `eas.json`:

```json
{
  "build": {
    "production": {
      "autoIncrement": true,
      "android": {
        "buildType": "app-bundle"
      }
    }
  }
}
```

Run EAS builds from the `apps/mobile` directory, not the root. Alternatively, configure `EXPO_PUBLIC_*` environment variables at the workspace root and Expo picks them up automatically.

## Shared TypeScript Config

A root `tsconfig.base.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "jsx": "react-jsx"
  }
}
```

Each package extends it:

```json
// packages/ui/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  }
}
```

## When a Monorepo Isn't the Answer

A monorepo adds real complexity. It's worth it when:

- You're actively sharing code between 2+ apps
- Your team is 3+ developers
- Build performance is a bottleneck

For a solo developer building one app, a single Expo project with no workspace overhead is faster to iterate on. Add the monorepo structure when you genuinely need the shared packages.

## Related

- [[How to Build a pnpm Monorepo the Right Way|How to Build a pnpm Monorepo]]
- [[Guide How to Publish to App Store with Expo React Native|Guide: Publish to App Store with Expo]]
- [[Building Fully Native iOS Apps with Expo EAS|Building Native iOS Apps with Expo EAS]]
- [[How to Build a SaaS Quickly in 2026 - AI Agents Boilerplates and Vibe Coding|How to Build a SaaS Quickly in 2026]]
