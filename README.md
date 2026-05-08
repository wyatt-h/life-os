# Life OS

> A personal iOS app to help you better operate your life — built with SwiftUI and Apple's Liquid Glass UI, synced with Notion.

## Features

| Tab | Description |
|---|---|
| **Morning Routine** | 11-item daily checklist with circular progress ring and evening reflection. Resets daily. |
| **Meal Plan** | Week A / Week B meal plans with full recipes, ingredients, and step-by-step instructions for all meals and shakes. |
| **Sleep Tracker** | 30-day progressive sleep schedule with habit toggles (morning light, wind-down, etc.) and actual time logging. |
| **Health** | Invisalign daily hours tracker (22h target, 1-hour off notification) + Accutane daily pill confirmation. |

All data syncs bidirectionally with your Notion workspace.

## Tech Stack

- **SwiftUI** — iOS 18+ / macOS 15+
- **Liquid Glass UI** — Apple's latest design language (iOS 26 / macOS 26)
- **Notion API** — All data stored and synced via Notion databases
- **UserNotifications** — Local push notifications for Invisalign reminders

## Setup

See [SETUP.md](SETUP.md) for full instructions on:
1. Creating a Notion Integration token
2. Connecting your Notion databases
3. Building and deploying to your iPhone

## Project Structure

```
LifeOS/
├── LifeOS/
│   ├── LifeOSApp.swift              # App entry point
│   ├── LiquidGlass/
│   │   └── LiquidGlassModifier.swift  # Liquid Glass UI modifier
│   ├── Services/
│   │   └── NotionService.swift      # Notion API integration
│   └── Views/
│       ├── MainTabView.swift        # Tab bar navigation
│       ├── MorningRoutineView.swift # Morning routine tracker
│       ├── MealPlanView.swift       # Meal plan + recipes
│       ├── SleepTrackerView.swift   # Sleep tracker
│       └── HealthTrackerView.swift  # Invisalign + Accutane
└── LifeOS.xcodeproj/
```

## Requirements

- Xcode 16+
- iOS 18+ device or simulator
- Notion account with Integration token

---

Built with ❤️ for Wyatt
