# UI Fixes Branch Guide

## 🔄 Branch Information
- Branch name: `fix/ui-improvements`
- Purpose: Fix UI issues and improve visual consistency

## 🛠 Build Process Quick Reference

### 1. Development Build & Test
```bash
# Install dependencies
cd apps/mobile
npm install --legacy-peer-deps

# Start Metro server
npx expo start --dev-client --clear

# Install on device
npx expo run:android

# If signature mismatch occurs
adb uninstall com.timeprogresstracker.app
npx expo run:android
```

### 2. Release Build (AAB & APK)
```bash
# Option 1: Use build script (recommended)
./build-android.sh   # This will auto-increment version

# Option 2: Manual build
cd apps/mobile/android
./gradlew clean
./gradlew bundleRelease  # Creates AAB
./gradlew assembleRelease  # Creates APK
```

### 3. File Locations
- AAB: `apps/mobile/android/app/build/outputs/bundle/release/app-release.aab`
- APK: `apps/mobile/android/app/build/outputs/apk/release/app-release.apk`
- Versioned copies in: `builds/app-release-v*.{aab,apk}`

### 4. Testing Release Build
```bash
# Install release APK
adb install -r builds/app-release-v*.apk

# Launch app
adb shell am start -n com.timeprogresstracker.app/.MainActivity
```

### 5. Commit Changes
```bash
git add .
git commit -m "fix: ui improvements"
git push origin fix/ui-improvements
```

## 📱 Current App Info
- Package: `com.timeprogresstracker.app`
- Latest version: 1.0.6 (code: 6)
- AdMob App ID: `ca-app-pub-9087069694782013~1860663616`
- Banner Ad Unit ID: `ca-app-pub-9087069694782013/2019418042`

## 🔍 Minimal Permissions
- `INTERNET` - For AdMob
- `VIBRATE` - For haptic feedback
- `SYSTEM_ALERT_WINDOW` - For notifications

## 📝 Notes
- Always test both light and dark widgets after UI changes
- Verify custom events display correctly
- Check notification text formatting
- Test on different screen sizes if possible
