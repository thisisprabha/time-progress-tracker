# How to Fix Fonts in Widget Extension

## Problem
The Sabdevi fonts are not loading in the widget because they're only in the main app bundle, not the widget extension bundle.

## Solution Steps

### Step 1: Add Fonts to Widget Target
1. In Xcode, navigate to the font files:
   - `ios/TimeProgressTracker/Assets/Fonts/Sabdevi-Regular.ttf`
   - `ios/TimeProgressTracker/Assets/Fonts/Sabdevi-Bold.ttf`
   - `ios/TimeProgressTracker/Assets/Fonts/Sabdevi-Light.ttf`

2. Select all 3 font files (hold Cmd and click each one)

3. In the **File Inspector** panel (right side):
   - Look for "Target Membership" section
   - Check ✅ **TimeLeftTrackerWidgetExtension**
   - Keep ✅ **TimeProgressTracker** checked too

### Step 2: Verify Info.plist
The fonts are already listed in `TimeLeftTrackerWidget/Info.plist`:
```xml
<key>UIAppFonts</key>
<array>
    <string>Assets/Fonts/Sabdevi-Regular.ttf</string>
    <string>Assets/Fonts/Sabdevi-Bold.ttf</string>
    <string>Assets/Fonts/Sabdevi-Light.ttf</string>
</array>
```

### Step 3: Clean and Rebuild
1. In Xcode: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Build and run again

### Step 4: Verify Fonts Loaded
Check the console logs for:
```
✅ [Widget] Registered font: Sabdevi-Regular -> Sabdevi-Regular-xxxxx
📦 Family: Sabdevi
    - Sabdevi-Regular-xxxxx
    - Sabdevi-Bold-xxxxx
```

## Alternative: Use System Fonts (Current Approach)
If fonts still don't load, the current code uses **system fonts** as a reliable fallback, which is why the widgets are working now.

To switch back to custom fonts after fixing:
1. Replace `.system(size: 14)` with `.custom("Sabdevi-Regular", size: 14)`
2. Replace `.system(size: 14, weight: .bold)` with `.custom("Sabdevi-Bold", size: 14)`

## Why This Happens
- Widget extensions are **separate processes** with their own bundles
- Resources must be explicitly added to the extension target
- The main app and widget don't share the same bundle by default
