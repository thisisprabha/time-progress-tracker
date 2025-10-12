# Android Development Setup Guide

## Prerequisites

1. **Download Android Command Line Tools**
   - Go to: https://developer.android.com/studio#command-tools
   - Download "Command line tools only" for macOS
   - Extract to: `~/Library/Android/sdk/cmdline-tools/latest/`

2. **Environment Variables** (Already set up)
   ```bash
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
   ```

## Install Required SDK Components

After downloading the command line tools, run:

```bash
# Install platform tools and build tools
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "build-tools;34.0.0" "platforms;android-34"
```

## Test Android Widget

### Method 1: Physical Android Device (Recommended)

1. **Enable Developer Options on your Android phone:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → Developer Options
   - Enable "USB Debugging"

2. **Connect and test:**
   ```bash
   cd apps/mobile
   npx expo run:android
   ```

### Method 2: Android Emulator

1. **Install Android Studio** (if you want a full IDE)
2. **Create Virtual Device** through AVD Manager
3. **Run the app** on the emulator

## Android Widget Features

✅ **Native Android Widget**
- Uses `AppWidgetProvider` for native functionality
- Tally marks visual style (X for completed, | for remaining)
- Three sizes: Small, Medium, Large
- Handwritten style font (`cursive`)
- Left/right text alignment
- Duller crossed lines (60% opacity)

✅ **Widget Files**
- `TimeProgressWidget.kt` - Main widget logic
- `time_progress_widget.xml` - Widget layout
- `widget_background.xml` - Background styling
- `time_progress_widget_info.xml` - Widget configuration
- `AndroidManifest.xml` - Widget registration

## Testing Checklist

- [ ] Android SDK properly installed
- [ ] Physical device connected via USB
- [ ] USB debugging enabled
- [ ] App builds and runs on device
- [ ] Widget appears in widget picker
- [ ] Widget displays correct time data
- [ ] Widget updates automatically
- [ ] Tally marks display correctly
- [ ] Font styling matches iOS version

## Troubleshooting

### "Failed to resolve Android SDK path"
- Ensure `ANDROID_HOME` is set correctly
- Check that command line tools are in the right location

### "spawn adb ENOENT"
- Install platform-tools: `sdkmanager "platform-tools"`
- Add platform-tools to PATH

### Widget not appearing
- Check AndroidManifest.xml has widget receiver
- Ensure widget info XML is properly configured
- Rebuild the app after widget changes

## Next Steps

1. Test widget on physical Android device
2. Fine-tune styling to match iOS version
3. Test widget updates and data persistence
4. Prepare for Play Store submission
