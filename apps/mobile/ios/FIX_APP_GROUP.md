# Fix App Group Red Color Issue

## Why App Group Shows Red

The App Group identifier `group.com.prabhakaran.timeprogresstracker` is correct in your code, but it needs to be **registered in your Apple Developer account**.

## Solution

### Option 1: Register in Apple Developer Portal (Recommended)

1. Go to: https://developer.apple.com/account/resources/identifiers/list/applicationGroup
2. Click **+** button (top left)
3. Select **App Groups**
4. Click **Continue**
5. **Description:** Time Progress Tracker App Group
6. **Identifier:** `group.com.prabhakaran.timeprogresstracker`
7. Click **Continue** → **Register**
8. Go back to Xcode
9. Select your **Team** in Signing & Capabilities
10. The red color should disappear

### Option 2: Use Different Identifier

If you can't access Apple Developer portal, you can use a different identifier:

1. In Xcode → Signing & Capabilities
2. Remove the current App Group
3. Add new: `group.com.prabhakaran.timeprogresstracker.dev` (or any unique name)
4. Update all code references to use the new identifier

## Verify App Group is Working

After fixing, check:
- ✅ App Group shows in Signing & Capabilities (not red)
- ✅ Same App Group added to Widget Extension target
- ✅ Code uses same identifier: `group.com.prabhakaran.timeprogresstracker`


