# Life OS — Setup Guide

## Overview

**Life OS** is your personal iOS app built in SwiftUI with Apple's Liquid Glass UI design language. It syncs directly with your Notion workspace and includes five core modules:

| Tab | Feature | Notion Database |
|---|---|---|
| Morning | Morning Routine Tracker | Morning Routine Tracker |
| Meals | Meal Plan + Recipes | Recipes & Shakes |
| Sleep | Sleep Tracker | 30-Day Sleep Tracker |
| Health | Invisalign + Accutane | Daily Health Tracker |

---

## Step 1 — Create a Notion Integration

The app reads and writes to your Notion workspace via the official Notion API. You need a private integration token.

1. Go to [https://www.notion.so/profile/integrations](https://www.notion.so/profile/integrations)
2. Click **"New integration"**
3. Name it `Life OS App`
4. Select your workspace
5. Under **Capabilities**, enable: **Read content**, **Update content**, **Insert content**
6. Click **Save** and copy the **Internal Integration Token** (starts with `secret_...`)

---

## Step 2 — Connect Your Notion Databases

You must give the integration access to each database. For each database listed below:

1. Open the database in Notion
2. Click the **"..."** menu (top right)
3. Go to **Connections** → **Add connections**
4. Search for `Life OS App` and click **Confirm**

**Databases to connect:**

| Database | Notion URL |
|---|---|
| Morning Routine Tracker | https://www.notion.so/e8320b3bc3d042218de901c8ecffab57 |
| Daily Health Tracker | https://www.notion.so/871a178cdb274d2f9ac9ab87fc368da7 |
| Recipes & Shakes | https://www.notion.so/4aa371f386a648f7bd8e49b379d4946a |
| 30-Day Sleep Tracker | https://www.notion.so/a846b573e33d4f7398a7114afee8b7e1 |

---

## Step 3 — Add Your Token to the App

1. Open `LifeOS/Services/NotionService.swift`
2. Find this line near the bottom:
   ```swift
   static let integrationToken = "YOUR_NOTION_INTEGRATION_TOKEN"
   ```
3. Replace `YOUR_NOTION_INTEGRATION_TOKEN` with your actual token from Step 1.

---

## Step 4 — Open in Xcode

1. Unzip `LifeOS.zip`
2. Open `LifeOS.xcodeproj` in **Xcode 16+**
3. Select your iPhone or Mac as the build target
4. Press **Cmd + R** to build and run

> **Note:** The app targets **iOS 18+** for full Liquid Glass UI support. Make sure your iPhone is running iOS 18 or later.

---

## Step 5 — Deploy to iPhone

1. Connect your iPhone via USB
2. In Xcode, select your iPhone from the device list
3. Click **Run** (or Cmd + R)
4. On first run, you may need to trust the developer certificate:
   - On your iPhone: **Settings → General → VPN & Device Management → [Your Apple ID] → Trust**

---

## Features Summary

### Morning Routine
- Tap each item to check it off — syncs instantly to Notion
- Circular progress ring shows completion percentage
- Evening reflection text field saves notes to Notion
- Resets automatically each day (new Notion entry per day)

### Meal Plan
- Toggle between Week A and Week B
- Tap any meal or shake to see full ingredients and step-by-step instructions
- Macro summary (calories, protein) shown at the top
- Data loaded from your Recipes & Shakes Notion database

### Sleep Tracker
- Automatically shows today's target wake time and bedtime based on your 30-day plan
- Toggle each sleep habit on/off — syncs to Notion
- Log actual wake and bedtime for tracking
- Phase indicator (Phase 1 / 2 / 3) shown at top

### Health Tracker (Invisalign + Accutane)
- **Invisalign:** Tap the button to toggle on/off — tracks daily hours worn
- Circular progress ring shows hours toward the 22-hour daily target
- **Notification:** Fires automatically if Invisalign has been off for 1+ hour
- **Accutane:** Tap the pill icon to mark today's 2-pill dose as taken — logs time automatically

---

## Notion Databases Created

The following databases were created in your AI WORKSPACE:

- **Morning Routine Tracker** — Daily checklist with all 11 routine items + sleep habits + reflection notes
- **Daily Health Tracker** — Invisalign on/off status, hours worn, Accutane tracking
- **Recipes & Shakes** — All Week A and Week B meals and shakes with full ingredients and instructions

The existing **30-Day Sleep Tracker** database was used as-is.
