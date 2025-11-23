#!/bin/bash

# Script to verify and install widget on iOS Simulator

echo "Building app and widget extension..."

# Build both app and widget
xcodebuild -workspace TimeProgressTracker.xcworkspace \
  -scheme TimeProgressTracker \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "(BUILD|succeeded|failed|error:)" | tail -3

# Get the build products path
BUILD_DIR=$(xcodebuild -workspace TimeProgressTracker.xcworkspace \
  -scheme TimeProgressTracker \
  -configuration Debug \
  -sdk iphonesimulator \
  -showBuildSettings 2>/dev/null | grep -m 1 "BUILT_PRODUCTS_DIR" | sed 's/.*= *//')

APP_PATH="${BUILD_DIR}/TimeProgressTracker.app"
WIDGET_PATH="${APP_PATH}/PlugIns/TimeProgressWidgetExtension.appex"

echo ""
echo "Checking build products..."
if [ -d "$APP_PATH" ]; then
    echo "✓ Main app found: $APP_PATH"
else
    echo "✗ Main app not found"
    exit 1
fi

if [ -d "$WIDGET_PATH" ]; then
    echo "✓ Widget extension found (embedded in app): $WIDGET_PATH"
else
    echo "✗ Widget extension not found in app bundle"
    echo "Looking for widget..."
    find "${BUILD_DIR}" -name "*.appex" -type d 2>/dev/null | head -3
    exit 1
fi

# Get simulator UDID
SIM_UDID=$(xcrun simctl list devices available | grep "iPhone 16" | head -1 | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -z "$SIM_UDID" ]; then
    echo "✗ No iPhone 16 simulator found"
    exit 1
fi

echo ""
echo "Installing to simulator: $SIM_UDID"

# Boot simulator if not running
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true

# Install app (which includes widget extension)
xcrun simctl install "$SIM_UDID" "$APP_PATH"

echo ""
echo "✓ Installation complete!"
echo ""
echo "To add widget:"
echo "1. Long press on home screen"
echo "2. Tap + button"
echo "3. Search for 'Time Progress'"
echo "4. Select widget size and add"

# Check if widget is registered
echo ""
echo "Checking widget registration..."
xcrun simctl get_app_container "$SIM_UDID" com.prabhakaran.timeprogresstracker.TimeProgressWidget 2>/dev/null && echo "✓ Widget extension is installed" || echo "⚠ Widget extension may need to be added manually"

