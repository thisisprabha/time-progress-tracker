# How to Run Native iOS App

## Quick Start - Run in Xcode

1. **Open the workspace:**
   ```bash
   cd apps/mobile/ios
   open TimeProgressTracker.xcworkspace
   ```

2. **In Xcode:**
   - Select a simulator (e.g., iPhone 16) from the device dropdown at the top
   - Click the **Play** button (▶️) or press `Cmd + R`
   - The app should build and launch in the simulator

## If Build Fails

The project currently has React Native dependencies that may conflict. To fix:

### Option 1: Quick Fix (Recommended)
1. In Xcode, go to **Product** → **Clean Build Folder** (`Cmd + Shift + K`)
2. Select **TimeProgressTracker** scheme (not React Native)
3. Try building again

### Option 2: Remove React Native Dependencies
If you want a pure native app:

1. In Xcode Project Navigator:
   - Select **TimeProgressTracker** project
   - Go to **Build Phases** → **Link Binary With Libraries**
   - Remove all React Native/Expo frameworks (keep only system frameworks)

2. Remove React Native build phases:
   - Go to **Build Phases**
   - Remove scripts related to React Native/Expo

3. Ensure these Swift files are in the target:
   - TimeProgressApp.swift (with @main)
   - ContentView.swift
   - MainHomeView.swift
   - SettingsView.swift
   - OnboardingView.swift
   - TimeCalculator.swift

## Run on Physical iPhone

1. Connect your iPhone via USB
2. Select your iPhone from the device dropdown
3. You may need to:
   - Sign the app with your Apple Developer account
   - Trust the developer certificate on your iPhone
4. Click **Play** to build and install

## Features

✅ Native SwiftUI app (no React Native)
✅ Glass morphism buttons in settings
✅ Time progress tracking (day, month, year)
✅ Tally marks display
✅ Widget support
✅ Onboarding flow
✅ Settings with perspective selection


