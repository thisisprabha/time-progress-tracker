# Expo Cleanup Plan

## Current Status
- **iOS**: Fully native Swift (no React Native/Expo needed)
- **Android**: Still using React Native/Expo

## Files/Dependencies That Can Be Removed (iOS-specific)

### 1. Expo Config Files (iOS doesn't need these)
- `apps/mobile/eas.json` - Expo Application Services config (not needed for native iOS)
- `apps/mobile/app.json` - Can be simplified or removed if iOS doesn't use it

### 2. Expo Dependencies (Can be removed from package.json if not used)
Since iOS is native Swift, these Expo packages are not needed:
- `expo` - Main Expo SDK
- `expo-router` - Not used in native iOS
- `expo-dev-client` - Development client
- `expo-updates` - OTA updates
- `expo-splash-screen` - Native iOS handles this
- `expo-status-bar` - Native iOS handles this
- `expo-system-ui` - Not needed
- `expo-symbols` - Not needed
- `expo-web-browser` - Not needed
- `expo-clipboard` - Not needed
- `expo-constants` - Not needed
- `expo-device` - Not needed
- `expo-linking` - Not needed
- `expo-secure-store` - Native iOS Keychain used instead
- `expo-notifications` - Native iOS notifications used instead
- `expo-haptics` - Native iOS haptics used instead
- `expo-image` - Native iOS images used instead
- `expo-linear-gradient` - Native iOS gradients used instead
- `expo-blur` - Native iOS blur used instead
- `expo-font` - Native iOS fonts used instead
- `expo-build-properties` - Build config

### 3. React Native Source Files (Not used by iOS)
- `apps/mobile/src/` - Entire React Native source directory
- `apps/mobile/App.tsx` - React Native entry point
- `apps/mobile/index.tsx` - React Native entry point
- `apps/mobile/index.web.tsx` - Web entry point
- `apps/mobile/__create/` - React Native polyfills

### 4. Expo Patches (Not needed for iOS)
- `apps/mobile/patches/@expo+cli+0.24.14.patch`
- `apps/mobile/patches/@expo+metro-runtime+5.0.4.patch`

### 5. Metro Config (Not needed for iOS)
- `apps/mobile/metro.config.js`

### 6. Expo Environment Types
- `apps/mobile/expo-env.d.ts`

### 7. Node Modules (Can be cleaned)
- `apps/mobile/node_modules/` - Can remove Expo packages after npm uninstall

## Files to KEEP (Android still needs them)
- Android build files
- React Native core dependencies (Android uses them)
- Shared utilities if Android uses them

## Recommendation
Since Android still uses React Native/Expo, we have two options:

**Option 1: Conservative (Recommended)**
- Keep all dependencies but document which are iOS-only
- Remove only clearly unused files like `eas.json`, `expo-env.d.ts`
- Clean up `src/` directory if it's truly not used

**Option 2: Aggressive**
- Remove all Expo dependencies
- Remove React Native source files
- Keep only Android-specific React Native setup
- This requires ensuring Android can still build

## Action Items
1. Verify Android build still works after cleanup
2. Remove iOS-specific Expo files
3. Update package.json to remove unused Expo packages
4. Clean node_modules and reinstall
5. Test iOS build
6. Test Android build




