# Android Development Setup Guide

Complete guide for setting up Android development environment for the Time Progress Tracker app.

## 📋 Prerequisites

- macOS (for this guide)
- Android device with USB debugging enabled
- USB cable for device connection

## 🛠 Installation Steps

### 1. Install Java Development Kit (JDK)

```bash
# Install OpenJDK 17 using Homebrew
brew install openjdk@17

# Add to PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
```

### 2. Install Android Command Line Tools

1. **Download**: Go to [Android Studio Downloads](https://developer.android.com/studio#command-tools)
2. **Download**: "Command line tools only" for macOS
3. **Extract**: Extract to `~/Library/Android/sdk/`
4. **Rename**: Rename folder from `cmdline-tools` to `cmdline-tools/latest`

### 3. Set Environment Variables

Add to your shell profile (`~/.zshrc` or `~/.bash_profile`):

```bash
# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/tools/bin

# Java
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
```

Reload your shell:
```bash
source ~/.zshrc
```

### 4. Install Required SDK Components

```bash
# Accept licenses
yes | sdkmanager --licenses

# Install required components
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

## 📱 Device Setup

### Enable USB Debugging

1. **Open Settings** on your Android device
2. **Go to**: About Phone
3. **Tap**: Build Number (7 times) to enable Developer Options
4. **Go back**: Settings → Developer Options
5. **Enable**: USB Debugging
6. **Connect**: Device via USB cable

### Verify Connection

```bash
# Check if device is connected
adb devices

# Should show your device:
# List of devices attached
# ABC123DEF456    device
```

## 🚀 Running the App

### Start Development Server

```bash
# Navigate to project
cd /path/to/time-progress-tracker/apps/mobile

# Start Metro bundler
npx expo start --dev-client --host tunnel
```

### Build and Install

```bash
# Build and install on connected device
npx expo run:android
```

### Connect to Development Server

1. **Open app** on your Android device
2. **Enter URL**: `http://YOUR_MAC_IP:8081` (get IP with `ifconfig`)
3. **OR**: Use tunnel URL from terminal output

## 📱 Widget Testing

### Add Widget to Home Screen

1. **Long press** on home screen
2. **Tap**: "Widgets" or "Add Widgets"
3. **Find**: "Time Progress Tracker"
4. **Add**: Widget to home screen
5. **Verify**: Shows time progress with tally marks

### Widget Features

- **Dynamic Height**: Adapts to content
- **Rounded Corners**: 12dp radius
- **Theme Support**: Light/dark mode
- **Tally Marks**: Visual progress indicators
- **Handwritten Fonts**: Custom styling

## 🔧 Troubleshooting

### Common Issues

#### "adb: command not found"
```bash
# Add platform-tools to PATH
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

#### "Failed to resolve Android SDK path"
```bash
# Set ANDROID_HOME
export ANDROID_HOME=$HOME/Library/Android/sdk
```

#### "No devices/emulators found"
```bash
# Check device connection
adb devices

# Restart adb server
adb kill-server
adb start-server
```

#### "Java Runtime Error"
```bash
# Install Java
brew install openjdk@17
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
```

#### Widget Not Appearing
1. **Check**: App is installed and running
2. **Verify**: Widget is registered in AndroidManifest.xml
3. **Restart**: Device or launcher
4. **Check**: Widget picker for "Time Progress Tracker"

### Build Issues

#### Gradle Build Failed
```bash
# Clean build
cd android
./gradlew clean
cd ..
npx expo run:android
```

#### Metro Bundler Issues
```bash
# Clear cache
npx expo start --clear

# Reset Metro
npx expo start --reset-cache
```

## 📊 Development Workflow

### 1. Code Changes
- Edit files in `apps/mobile/src/`
- Changes auto-reload in app

### 2. Widget Changes
- Edit `android/app/src/main/java/com/timeprogresstracker/app/widget/TimeProgressWidget.kt`
- Edit `android/app/src/main/res/layout/time_progress_widget_simple.xml`
- Rebuild: `npx expo run:android`

### 3. Testing
- **App**: Test all features and settings
- **Widget**: Add/remove widget, check updates
- **Both Platforms**: Test on iOS and Android

## 🎯 Production Build

### Build APK
```bash
# Build release APK
npx eas build --platform android --profile production
```

### Upload to Play Store
1. **Download**: APK from EAS Build
2. **Upload**: To Google Play Console
3. **Configure**: App details and screenshots
4. **Submit**: For review

## 📚 Additional Resources

- [Android Developer Guide](https://developer.android.com/guide)
- [Expo Android Development](https://docs.expo.dev/workflow/android/)
- [React Native Android](https://reactnative.dev/docs/environment-setup)
- [Android Widget Development](https://developer.android.com/guide/topics/appwidgets)

## 🆘 Support

If you encounter issues:
1. Check this troubleshooting guide
2. Verify all environment variables
3. Ensure device is properly connected
4. Check Expo and Android documentation
5. Create an issue on GitHub

---

**Happy Android Development! 🚀**