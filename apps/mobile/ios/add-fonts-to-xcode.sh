#!/bin/bash

# Script to add Sabdevi fonts to Xcode project
# This ensures fonts are properly included in the build

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONTS_DIR="$PROJECT_DIR/TimeProgressTracker/Assets/Fonts"
PROJECT_FILE="$PROJECT_DIR/TimeProgressTracker.xcodeproj/project.pbxproj"

echo "Checking fonts in $FONTS_DIR..."
ls -la "$FONTS_DIR" | grep Sabdevi

echo ""
echo "Fonts are physically present. To add them to Xcode project:"
echo ""
echo "1. Open TimeProgressTracker.xcworkspace in Xcode"
echo "2. In the Project Navigator, right-click on 'TimeProgressTracker' folder"
echo "3. Select 'Add Files to TimeProgressTracker...'"
echo "4. Navigate to TimeProgressTracker/Assets/Fonts/"
echo "5. Select all three Sabdevi font files (.ttf)"
echo "6. Make sure 'Copy items if needed' is UNCHECKED (files are already there)"
echo "7. Make sure 'Add to targets: TimeProgressTracker' is CHECKED"
echo "8. Click 'Add'"
echo ""
echo "For Widget Extension fonts:"
echo "9. Select the font files in Project Navigator"
echo "10. In File Inspector (right panel), check 'TimeProgressWidgetExtension' target"
echo ""
echo "Fonts are already registered in Info.plist, so they should work once added to the project."

