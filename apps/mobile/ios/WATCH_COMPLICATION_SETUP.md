# Apple Watch Complication Setup - Step by Step

## Issue: No Complication Showing on Apple Watch

The complication code is ready, but you need to **add a WatchKit app target** in Xcode. The Swift file alone isn't enough - Xcode needs a proper Watch app target.

## Step-by-Step Instructions

### 1. Fix App Group (Red Color Issue)

**In Xcode:**
1. Select **TimeProgressTracker** target (main iOS app)
2. Go to **Signing & Capabilities** tab
3. Find **App Groups** section
4. Check that the App Group shows: `group.com.prabhakaran.timeprogresstracker` (full name)
5. If it's truncated or red:
   - Click the **+** button
   - Type: `group.com.prabhakaran.timeprogresstracker`
   - Press Enter
   - Make sure it's checked ✅

**If still red:**
- Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list/applicationGroup)
- Create App Group: `group.com.prabhakaran.timeprogresstracker`
- Then add it in Xcode again

### 2. Add WatchKit App Target

**In Xcode:**
1. File → **New → Target**
2. Choose **watchOS** tab
3. Select **App**
4. Click **Next**
5. Configure:
   - **Product Name:** `TimeProgressWatch`
   - **Bundle Identifier:** `com.prabhakaran.timeprogresstracker.watchkitapp`
   - **Language:** Swift
   - ✅ **Include Complication** (IMPORTANT!)
   - ✅ **Include Notification Scene**
6. Click **Finish**
7. When asked "Activate 'TimeProgressWatch' scheme?" → Click **Activate**

### 3. Add Watch Widget Extension

**In Xcode:**
1. File → **New → Target**
2. Choose **watchOS** tab
3. Select **Widget Extension**
4. Click **Next**
5. Configure:
   - **Product Name:** `TimeProgressWatchExtension`
   - **Bundle Identifier:** `com.prabhakaran.timeprogresstracker.watchkitapp.watchkitextension`
   - **Language:** Swift
   - ✅ **Include Configuration Intent** (optional)
6. Click **Finish**

### 4. Add Complication Code to Watch Extension

**In Xcode:**
1. In Project Navigator, find `TimeProgressWatchExtension` folder
2. Right-click → **Add Files to "TimeProgressWatchExtension"...**
3. Navigate to `TimeProgressWatch/TimeProgressWatch.swift`
4. Select the file
5. **IMPORTANT:** Make sure:
   - ✅ **Copy items if needed** is UNCHECKED (file already exists)
   - ✅ **Add to targets: TimeProgressWatchExtension** is CHECKED
6. Click **Add**

### 5. Configure Watch Extension App Groups

**In Xcode:**
1. Select **TimeProgressWatchExtension** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** button in App Groups
6. Type: `group.com.prabhakaran.timeprogresstracker`
7. Make sure it's checked ✅

### 6. Update Watch Extension Bundle

**In Xcode:**
1. Select **TimeProgressWatchExtension** target
2. Go to **General** tab
3. Find **Deployment Info**
4. Set **Minimum Deployments:** watchOS 9.0 or higher (for WidgetKit support)

### 7. Update Watch Extension Info.plist

**In Xcode:**
1. Find `TimeProgressWatchExtension/Info.plist`
2. Make sure it has:
   ```xml
   <key>NSExtension</key>
   <dict>
       <key>NSExtensionPointIdentifier</key>
       <string>com.apple.widgetkit-extension</string>
   </dict>
   ```

### 8. Build & Run

**In Xcode:**
1. Select **TimeProgressWatch** scheme (from scheme dropdown at top)
2. Choose **Apple Watch** simulator (e.g., "Apple Watch Series 9 (45mm)")
3. Press **Cmd + R** to build and run
4. Wait for Watch app to install

### 9. Add Complication to Watch Face

**On Watch Simulator:**
1. Long press on watch face
2. Tap **Edit**
3. Swipe to find complication slot
4. Tap the slot
5. Scroll and find **"Time Progress"**
6. Select it
7. Press Digital Crown to save

## Verification Checklist

- [ ] App Group added to iOS app (not red)
- [ ] App Group added to Watch Extension (not red)
- [ ] WatchKit App target created
- [ ] Watch Widget Extension target created
- [ ] TimeProgressWatch.swift added to Watch Extension target
- [ ] Watch Extension has App Groups capability
- [ ] Watch app builds successfully
- [ ] Complication appears in watch face editor

## Troubleshooting

**If App Group is still red:**
- Make sure you're signed in with Apple Developer account in Xcode
- Go to Xcode → Preferences → Accounts
- Add your Apple ID if not present
- Select your team in Signing & Capabilities

**If complication doesn't appear:**
- Make sure Watch app is installed (run Watch scheme)
- Check that Watch Extension target includes the Swift file
- Verify Info.plist has correct extension point identifier
- Try restarting Watch simulator

**If build fails:**
- Make sure Watch Extension deployment target is watchOS 9.0+
- Check that all files are added to correct targets
- Clean build folder: Product → Clean Build Folder

## Current Status

✅ **Code Ready:** `TimeProgressWatch.swift` is created with curved progress style
✅ **Settings Ready:** iOS app has "Apple Watch" section in Settings
✅ **Data Sharing Ready:** App Groups configured for data sync
❌ **Missing:** WatchKit app target needs to be added in Xcode (manual step)

Once you complete steps 2-9 above, the complication will appear on your Apple Watch!


