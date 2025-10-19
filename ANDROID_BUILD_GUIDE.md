# Android Build & Run Guide - Time Progress Tracker

This guide documents the complete process for building, installing, and running the Time Progress Tracker Android app.

## Prerequisites

- **Android Device**: Physical Android device with USB debugging enabled
- **ADB**: Android Debug Bridge installed and configured
- **Node.js**: Version 18+ installed
- **Expo CLI**: Latest version installed
- **Java**: OpenJDK 17+ installed

## Quick Setup Commands

### 1. Install Dependencies
```bash
cd apps/mobile
npm install --legacy-peer-deps
```

### 2. Start Metro Development Server
```bash
cd apps/mobile
npx expo start --dev-client --clear
```

### 3. Build & Install App
```bash
cd apps/mobile
npx expo run:android
```

### 4. Launch App on Device
```bash
adb shell am start -n com.timeprogresstracker.app/.MainActivity
```

## Detailed Step-by-Step Process

### Step 1: Environment Setup

1. **Enable USB Debugging on Android Device**:
   - Go to Settings → About Phone → Tap "Build Number" 7 times
   - Go to Settings → Developer Options → Enable "USB Debugging"
   - Connect device via USB cable

2. **Verify ADB Connection**:
   ```bash
   adb devices
   # Should show your device listed
   ```

3. **Install Dependencies**:
   ```bash
   cd /path/to/create-anything/apps/mobile
   npm install --legacy-peer-deps
   ```

### Step 2: Start Development Server

1. **Kill any existing Metro processes**:
   ```bash
   pkill -f "expo start"
   ```

2. **Start fresh Metro server**:
   ```bash
   cd apps/mobile
   npx expo start --dev-client --clear
   ```

3. **Verify server is running**:
   ```bash
   curl -s http://localhost:8081/status
   # Should return: packager-status:running
   ```

### Step 3: Build & Install App

1. **Build and install the app**:
   ```bash
   cd apps/mobile
   npx expo run:android
   ```

2. **If installation fails due to signature mismatch**:
   ```bash
   adb uninstall com.timeprogresstracker.app
   npx expo run:android
   ```

### Step 4: Launch App

1. **Force restart the app**:
   ```bash
   adb shell am force-stop com.timeprogresstracker.app
   adb shell am start -n com.timeprogresstracker.app/.MainActivity
   ```

### Step 5: Monitor Logs

1. **Monitor app logs**:
   ```bash
   adb logcat | grep -E "(ReactNativeJS|TimeProgress|notification|schedule)"
   ```

2. **Monitor Metro bundler logs**:
   - Check the terminal where `npx expo start` is running
   - Look for bundling progress and any errors

## Troubleshooting

### Common Issues & Solutions

#### 1. Metro Server Connection Issues
```bash
# Kill all Expo processes
pkill -f "expo start"

# Start fresh server
cd apps/mobile
npx expo start --dev-client --clear

# Set up port forwarding
adb reverse tcp:8081 tcp:8081
```

#### 2. Installation Signature Mismatch
```bash
# Uninstall existing app
adb uninstall com.timeprogresstracker.app

# Reinstall
npx expo run:android
```

#### 3. Missing Dependencies
```bash
# Install with legacy peer deps
npm install @react-navigation/elements @react-navigation/native --legacy-peer-deps
```

#### 4. ScrollView Layout Errors
- Fixed by moving `justifyContent` from `style` to `contentContainerStyle` prop
- See commit history for specific changes

### App Features Status

✅ **Working Features**:
- Time progress tracking (year, month, week, quarter, day)
- Settings configuration
- Weekly notifications (Mondays at 9 AM)
- Real-time notification data (no more 0 values)
- Haptic feedback
- AdMob integration

✅ **Fixed Issues**:
- Multiple notification scheduling
- Stale notification data showing 0 values
- ScrollView layout errors
- Missing React Navigation dependencies

## Development Workflow

### Making Changes
1. Edit code in `apps/mobile/src/app/time-progress.jsx`
2. Metro will automatically reload the app
3. Check logs for any errors

### Testing Notifications
1. Open app settings (gear icon)
2. Change display items or time mode
3. Tap "Reschedule Notifications" button
4. Check logs for: "Weekly notification scheduled" and "Notifications rescheduled with new settings"

### Building Release Version
```bash
cd apps/mobile
npx expo build:android
```

## File Structure

```
apps/mobile/
├── src/app/
│   ├── time-progress.jsx    # Main app component
│   └── _layout.jsx          # App layout
├── android/                 # Android native code
├── package.json            # Dependencies
└── app.json               # Expo configuration
```

## Key Commands Reference

| Command | Purpose |
|---------|---------|
| `npx expo start --dev-client --clear` | Start Metro server |
| `npx expo run:android` | Build & install app |
| `adb devices` | List connected devices |
| `adb shell am start -n com.timeprogresstracker.app/.MainActivity` | Launch app |
| `adb logcat \| grep ReactNativeJS` | Monitor app logs |
| `pkill -f "expo start"` | Kill Metro processes |

## Notes

- App package name: `com.timeprogresstracker.app`
- Main activity: `.MainActivity`
- Metro server runs on port 8081
- Notifications scheduled for Mondays at 9 AM
- Uses Expo development client for hot reloading
