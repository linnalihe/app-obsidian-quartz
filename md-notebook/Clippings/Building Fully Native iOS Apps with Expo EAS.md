---
title: "Building Fully Native iOS Apps with Expo EAS"
source: "https://swmansion.com/blog/building-fully-native-ios-apps-with-expo-eas-760b5480d7c5/"
author:
  - "[[Patryk Mleczek]]"
published: 2025-10-02
created: 2026-07-21
description: "A step-by-step tutorial for building and deploying fully native Swift iOS apps using Expo Application Services and custom build workflows."
tags:
  - "clippings"
draft: false
---

Expo Application Services (EAS) isn't just for React Native. You can use it to build, sign, and distribute fully native Swift iOS apps — with CI/CD workflows out of the box.

## Why Use EAS for a Native iOS App?

EAS handles the painful parts of iOS distribution: code signing, provisioning profiles, certificates, and the App Store submission process. For a solo developer or small team, replacing manual Xcode Archive workflows with EAS saves hours per release.

## Step 1: Project Setup

Create a native iOS app in Xcode using the iOS Application template with SwiftUI. Configure your app name and bundle identifier.

Add external Swift package dependencies via Xcode's package manager (File → Add Package Dependencies). This example uses SVGView to render SVG images.

## Step 2: Configure EAS

Add a minimal `package.json` to your project root (EAS requires this even for native apps):

```json
{
  "name": "my-native-app",
  "version": "1.0.0",
  "private": true
}
```

Install EAS dependencies and configure:

```bash
npm install expo expo-dev-client
eas build:configure
```

This generates `app.json` (with your EAS project ID) and `eas.json` (with build profiles).

## Step 3: Custom Build Workflow

For a native app, you need a custom build configuration that symlinks your project root as the expected `ios/` directory:

Create `.eas/build/build-ios.yml`:

```yaml
build:
  name: Build iOS app
  steps:
    - eas/checkout
    - eas/install_node_modules
    - run:
        name: Symlink ios
        command: ln -sf . ios
    - eas/resolve_build_config
    - eas/generate_gymfile_from_template:
        inputs:
          scheme: YourSchemeName
    - eas/run_fastlane
    - eas/find_and_upload_build_artifacts
```

Update `eas.json` to reference this workflow:

```json
{
  "build": {
    "base": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "config": "build-ios.yml"
      },
      "withoutCredentials": true
    },
    "development-simulator": {
      "extends": "base",
      "ios": {
        "simulator": true
      }
    }
  }
}
```

## Step 4: Build Locally First

Test the configuration before running on EAS cloud:

```bash
eas build -p ios -e development-simulator --local
```

Common issue: scheme not found. Open Xcode → Product → Scheme → Edit Scheme → check the "Shared" checkbox.

Once local build succeeds, run on EAS cloud:

```bash
eas build -p ios -e development-simulator
```

EAS uploads your project, runs the build, and sends a notification with a download link when complete.

## Step 5: EAS Workflows for CI/CD

EAS Workflows provide CI/CD without a separate GitHub Actions setup. Create `.eas/workflows/create-ios-build.yml`:

```yaml
name: Create iOS build (simulator)

jobs:
  build_ios_simulator:
    name: Build for iOS simulator (development)
    type: build
    params:
      platform: ios
      profile: development-simulator
```

Trigger a workflow run:

```bash
eas workflow:run create-ios-build.yml
```

Workflows support triggers: CRON schedules, branch pushes, and pull requests. Add post-build actions like Slack notifications or automated TestFlight distribution.

## Credentials Management

EAS manages certificates and provisioning profiles automatically. For the simulator build (`withoutCredentials: true`), no credentials are needed. For distribution builds:

```bash
eas credentials
```

EAS creates and stores your certificates in its secure vault. For teams, credentials are shared automatically — no more "your certificate isn't on my machine" problems.

## Production Submission

For App Store submission from an EAS build:

```bash
eas submit --platform ios --latest
```

EAS Submit connects to App Store Connect and uploads the binary directly. You still need to fill out the App Store listing (screenshots, description, keywords) in App Store Connect manually.

## The Key Insight

EAS treats build configuration as code (`eas.json`, workflow YAML files). This means your entire build and distribution process is reproducible, version-controlled, and not dependent on any one developer's machine setup. For teams or solo developers releasing regularly, this is a significant quality-of-life improvement over manual Xcode Archive workflows.
