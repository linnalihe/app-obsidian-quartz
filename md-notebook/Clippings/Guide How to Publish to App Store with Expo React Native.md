---
title: "Guide: How to Publish to App Store with Expo & React Native"
source: "https://applighter.com/blog/how-to-publish-to-app-store-with-expo"
author:
  - "[[Suraj]]"
published: 2026-07-08
created: 2026-07-21
description: "Step-by-step guide to submitting a React Native Expo app to the Apple App Store using EAS Build and EAS Submit."
tags:
  - "clippings"
draft: false
---

Submitting to the App Store used to require deep knowledge of Xcode, provisioning profiles, and certificates. EAS (Expo Application Services) abstracts most of this. Here's the full flow.

## Prerequisites

- Apple Developer account ($99/year)
- Expo account (free)
- EAS CLI installed: `npm install -g eas-cli`
- Your app running in Expo Go or a development build

## Step 1: Configure EAS

In your project root:

```bash
eas build:configure
```

This creates `eas.json` with build profiles. The production profile is what you'll use for App Store submissions.

```json
{
  "build": {
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {}
  }
}
```

## Step 2: Set Up App Identifiers in Apple Developer

Before building, register your app:

1. Log in to developer.apple.com
2. Go to Certificates, Identifiers & Profiles
3. Create a new App ID with your bundle identifier (e.g., `com.yourname.yourapp`)
4. Enable any capabilities your app needs (Push Notifications, Sign in with Apple, etc.)

EAS can do this automatically with managed credentials — let it handle certificates and provisioning profiles unless you have a specific reason to manage them manually.

## Step 3: Build for Production

```bash
eas build --platform ios --profile production
```

EAS will:
- Ask to set up iOS credentials (let it manage them automatically)
- Upload your project to EAS Build infrastructure
- Compile your app and sign it
- Provide a download link when complete

Build time: typically 10–20 minutes. You can close the terminal and monitor at expo.dev.

## Step 4: Create Your App Store Listing

In App Store Connect (appstoreconnect.apple.com):

1. Create a new app with your bundle identifier
2. Fill out the metadata:
   - App name
   - Subtitle (30 characters)
   - Description (4,000 characters)
   - Keywords (100 characters, comma-separated)
   - Screenshots for all required device sizes
   - App preview video (optional but boosts conversion)
3. Set pricing (free or paid)
4. Configure age rating, privacy policy URL

## Step 5: Submit to App Store

Option A — EAS Submit (easiest):

```bash
eas submit --platform ios --latest
```

This picks up your most recent production build and submits it directly to App Store Connect.

Option B — Manual:
Download the `.ipa` from EAS, open Xcode's Organizer (Window → Organizer), and distribute from there.

## Step 6: Review Process

After submission:
- **Processing**: 15 minutes to a few hours for the binary to process
- **Review queue**: typically 24–48 hours for first submissions; faster for updates
- **Common rejection reasons**:
  - Missing privacy policy
  - App crashes on reviewer's device
  - Misleading screenshots
  - Missing required permission descriptions in Info.plist

If rejected, you'll get an email with the reason. Fix the issue and resubmit — you don't lose your place in the queue entirely.

## Step 7: Release Strategy

Choose your release type:
- **Automatic release** — goes live immediately after approval
- **Manual release** — you control when it goes live (useful for coordinated launches)
- **Phased release** — rolls out to 1% → 2% → 5% → 10% → 20% → 50% → 100% over 7 days

For first-time apps, manual release with a planned launch day works best.

## Common Gotchas

- **NSUserTrackingUsageDescription**: Required if you use any analytics or advertising SDKs
- **App Transport Security**: All HTTP requests must be HTTPS (or explicitly exempted)
- **Permissions**: Every permission your app might use needs a usage description string in app.json
- **Screenshots**: Apple requires exact pixel dimensions; screenshots from a simulator work fine

## TestFlight for Beta Testing

Before full release, test with real users via TestFlight:
- Internal testing: up to 100 testers, instant, no review
- External testing: up to 10,000 testers, requires a brief review
- Invite testers by email or a public link

EAS Submit can push to TestFlight instead of production: `eas submit --platform ios --latest` and choose TestFlight when prompted.

## Related

- [[Building Fully Native iOS Apps with Expo EAS|Building Native iOS Apps with Expo EAS]]
- [[React Native Monorepo with Turborepo and Expo A Platform Team Guide for 2026|React Native Monorepo with Turborepo and Expo]]
- [[How to Build a pnpm Monorepo the Right Way|How to Build a pnpm Monorepo]]
- [[The State of Subscription Apps 2026 - RevenueCat|The State of Subscription Apps 2026]]
