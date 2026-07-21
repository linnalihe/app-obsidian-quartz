---
title: "How to Build a pnpm Monorepo, the Right Way"
source: "https://dev.to/ishchhabra/how-to-build-a-pnpm-monorepo-the-right-way-43d3"
author:
  - "[[Ish Chhabra]]"
published: 2026-03-06
created: 2026-07-21
description: "The correct way to configure pnpm workspaces with injected dependencies to avoid peer dependency conflicts across apps in a monorepo."
tags:
  - "clippings"
draft: false
---

pnpm workspaces make monorepos practical, but the default symlink behavior creates peer dependency problems — especially with React and React Native. Here's the setup that actually works.

## The Problem: Two Copies of React

When pnpm installs a workspace package, it creates a symlink: `node_modules/@packages/ui` → `packages/ui/`. When that package calls `require("react")`, Node resolves from the symlink *target*, not the consuming app. You end up with two copies of React — one for the shared package, one for the app.

The errors this causes:
- "Invalid hook call. Hooks can only be called inside of the body of a function component."
- "Error: No QueryClient set, use QueryClientProvider to set one"

Any library that stores state in module closures (React, React Query, Zustand) breaks when loaded twice.

## The Fix: Injected Dependencies

pnpm's `dependenciesMeta.injected: true` flag creates a hard-linked *copy* of the shared package in the consumer's `node_modules` instead of a symlink. Node resolves from the consumer's directory, finding the consumer's React — not the package's.

```json
// apps/mobile/package.json
{
  "dependencies": {
    "react": "^18",
    "@packages/ui": "workspace:*"
  },
  "dependenciesMeta": {
    "@packages/ui": { "injected": true }
  }
}
```

Each consumer gets its own hard-linked copy. App A can run React 18, App B can run React 19, and both resolve correctly.

## Why Not Just Configure the Bundler?

Next.js solves this for its own React by configuring webpack to resolve React from the app's `node_modules`. But you'd need to do this for every consumer, and it only works for that bundler. Metro (React Native), Vite, and webpack each need different config.

With pnpm injected, no bundler config needed — it works at the package manager level regardless of what each consumer uses.

## The Development Experience Problem

Injected dependencies introduce a new problem: changes to shared packages don't propagate automatically. When you edit `packages/ui/Button.tsx` and rebuild, `tsc` writes new files with new inodes — but the hard links in consumers still point to the old files.

### Solution: pnpm-sync

[pnpm-sync](https://github.com/tiktok/pnpm-sync) (by TikTok) re-copies `dist/` into each consumer after every build.

Setup in `packages/ui/package.json`:

```json
{
  "scripts": {
    "build": "tsc",
    "postbuild": "pnpm-sync copy",
    "prepare": "pnpm sync:prepare && pnpm build",
    "build:watch": "tsc-watch --onSuccess \"pnpm postbuild\"",
    "sync:prepare": "pnpm-sync prepare -l ../../apps/my-app/pnpm-lock.yaml -s ../../apps/my-app/node_modules/.pnpm"
  }
}
```

Now `pnpm install` automatically builds the package (`prepare` hook), and every rebuild copies the output to consumers (`postbuild`).

## Hot Reload in Dev

After pnpm-sync copies updated files, the dev server still shows the old version because most bundlers ignore changes in `node_modules`.

**For Vite** — exclude workspace packages from pre-bundling:

```typescript
// vite.config.ts
optimizeDeps: {
  exclude: workspacePackageNames  // computed from pnpm workspace
}
```

**For Webpack/Next.js** — carve out an exception in the watcher:

```typescript
watchOptions: {
  ignored: new RegExp("node_modules/(?!" + workspacePackagePattern + ")")
}
```

## Go-To-Source with Cmd+Click

Since consumers import from `dist/`, Cmd+Click opens `.d.ts` instead of source. Fix:

```json
// packages/ui/tsconfig.json
{
  "compilerOptions": {
    "declarationMap": true,
    "sourceMap": true
  }
}
```

Plus pass an absolute `sourceRoot` at build time:

```json
"build": "tsc --sourceRoot \"$(pwd)/src\""
```

This embeds the absolute path to the source files in declaration maps, so VS Code jumps to the original TypeScript.

## Auto-Build on Fresh Clone

Without setup, `pnpm install` on a fresh clone leaves `dist/` empty. The `prepare` lifecycle hook runs automatically during install:

```json
"prepare": "pnpm sync:prepare && pnpm build"
```

Now `pnpm install` builds all shared packages in topological order automatically.

## Why Not Bun?

Bun's isolated installs provide dependency isolation but still symlink workspace packages to their source directory — no `injected` equivalent exists. Peer dependencies resolve from the *package's* directory, not the consumer's. Until Bun adds an injected mode, pnpm remains the right choice for monorepos.
