#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get absolute paths
ROOT_DIR="$(pwd)"
MOBILE_DIR="$ROOT_DIR/apps/mobile"
ANDROID_DIR="$MOBILE_DIR/android"
BUILDS_DIR="$ROOT_DIR/builds"

echo -e "\n${YELLOW}📍 Working directories:${NC}"
echo -e "Root dir: $ROOT_DIR"
echo -e "Mobile dir: $MOBILE_DIR"
echo -e "Android dir: $ANDROID_DIR"
echo -e "Builds output dir: $BUILDS_DIR\n"

# Navigate to mobile app directory
cd "$MOBILE_DIR" || exit

echo -e "${BLUE}📱 Starting Android Build Process...${NC}"

# Read current version from app.json
CURRENT_VERSION=$(grep -o '"versionCode": [0-9]*' app.json | grep -o '[0-9]*')
NEW_VERSION=$((CURRENT_VERSION + 1))
echo -e "${GREEN}ℹ️  Current version: $CURRENT_VERSION${NC}"
echo -e "${GREEN}ℹ️  New version: $NEW_VERSION${NC}"

# Update version in app.json
sed -i '' "s/\"versionCode\": $CURRENT_VERSION/\"versionCode\": $NEW_VERSION/" app.json
NEW_VERSION_NAME="1.0.$NEW_VERSION"
sed -i '' "s/\"version\": \"[0-9.]*\"/\"version\": \"$NEW_VERSION_NAME\"/" app.json

# Update version in build.gradle
cd android/app || exit
sed -i '' "s/versionCode $CURRENT_VERSION/versionCode $NEW_VERSION/" build.gradle
sed -i '' "s/versionName \"[0-9.]*\"/versionName \"$NEW_VERSION_NAME\"/" build.gradle
cd ../.. || exit

echo -e "${BLUE}🧹 Cleaning build directory...${NC}"
cd android || exit
./gradlew clean

echo -e "${BLUE}📦 Building AAB (Android App Bundle)...${NC}"
./gradlew bundleRelease

echo -e "${BLUE}📱 Building APK...${NC}"
./gradlew assembleRelease

# Create builds directory if it doesn't exist
mkdir -p "$BUILDS_DIR"

# Copy files with version numbers
AAB_SOURCE="$ANDROID_DIR/app/build/outputs/bundle/release/app-release.aab"
APK_SOURCE="$ANDROID_DIR/app/build/outputs/apk/release/app-release.apk"
AAB_DEST="$BUILDS_DIR/app-release-v$NEW_VERSION.aab"
APK_DEST="$BUILDS_DIR/app-release-v$NEW_VERSION.apk"

cp "$AAB_SOURCE" "$AAB_DEST"
cp "$APK_SOURCE" "$APK_DEST"

echo -e "\n${YELLOW}📱 Quick Reference Guide:${NC}"
echo -e "${GREEN}1. Original Build Files:${NC}"
echo -e "   AAB: $AAB_SOURCE"
echo -e "   APK: $APK_SOURCE"
echo -e "\n${GREEN}2. Versioned Copies:${NC}"
echo -e "   AAB: $AAB_DEST"
echo -e "   APK: $APK_DEST"
echo -e "\n${GREEN}3. File Sizes:${NC}"
echo -e "   AAB: $(ls -lh "$AAB_DEST" | awk '{print $5}')"
echo -e "   APK: $(ls -lh "$APK_DEST" | awk '{print $5}')"
echo -e "\n${GREEN}4. Version Info:${NC}"
echo -e "   Version Code: $NEW_VERSION"
echo -e "   Version Name: $NEW_VERSION_NAME"
echo -e "\n${GREEN}5. Commands to Install APK:${NC}"
echo -e "   adb install -r \"$APK_DEST\""
echo -e "\n${YELLOW}✨ Build Complete! ✨${NC}\n"