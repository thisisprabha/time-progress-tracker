# Time Progress Tracker 📊

A beautiful React Native app that tracks your daily, monthly, and yearly progress with a unique perspective-based approach. Choose your glass perspective and see time differently!

## 🚀 Quick Start

### Prerequisites
- Node.js (v18+)
- Java 17+ (for Android builds)
- Android SDK (for Android development)
- Xcode (for iOS development on macOS)

### Installation & Run
```bash
# Install dependencies
cd apps/mobile
npm install --legacy-peer-deps

# For development (with Metro bundler)
npx expo start --dev-client --port 8081

# For Android build
npx expo run:android

# For iOS build  
npx expo run:ios
```

## ✨ Features

### 🎯 Core Functionality
- **Time Progress Tracking**: See how much of today, this month, and this year has passed
- **Perspective Toggle**: Switch between "Half Full" (optimistic) and "Half Empty" (pessimistic) views
- **Time Modes**: Choose between 24-hour format or 9-5 office hours
- **Haptic Feedback**: Feel vibrations when interacting (mobile)
- **Smooth Animations**: Beautiful transitions and micro-interactions

### 🎨 Design
- **Handwritten Font**: Consistent Kalam font throughout
- **Tally Mark Progress**: Visual progress indicators with X and | marks
- **Modern UI**: Clean, intuitive interface
- **Responsive**: Works on phones, tablets, and web
- **Native Widgets**: iOS and Android home screen widgets

### ⚙️ Settings
- **Settings Icon**: Gear icon in top-right corner
- **Perspective Control**: Toggle between optimistic/pessimistic views
- **Time Format**: Switch between 24h and 9-5 office hours
- **Persistent Storage**: Settings saved across app sessions

### 💰 Monetization (Android)
- **Google AdMob Integration**: Banner ads with test configuration
- **Dual Ad Placement**: Main screen bottom + Settings modal top
- **Fallback System**: "Ad (test)" placeholder with 12-second timeout
- **Non-Intrusive**: Ads positioned to maintain user experience

## 📱 How to Use

### Main App
1. **Open the app** - You'll see your time progress with current perspective
2. **Tap settings icon** (⚙️) in top-right corner
3. **Choose perspective**: Half Full (optimistic) or Half Empty (pessimistic)
4. **Select time mode**: 24 Hours or 9-5 Office Hours
5. **Settings auto-save** - Your preferences are remembered

### Native Widgets
1. **iOS**: Long press home screen → Widgets → Time Progress Tracker
2. **Android**: Long press home screen → Widgets → Time Progress Tracker
3. **Widget sizes**: Small (hours), Medium (today + month), Large (all data)
4. **Auto-updates**: Widgets refresh automatically every hour

## 🛠️ Technical Details

### Built With
- **React Native** with Expo SDK 54 (Bare Workflow)
- **Expo Router** for navigation
- **AsyncStorage** for data persistence
- **React Native SVG** for icons
- **React Native Reanimated** for animations
- **iOS WidgetKit** (Swift/SwiftUI) for iOS widgets
- **Android AppWidgetProvider** (Kotlin) for Android widgets
- **Google AdMob** (react-native-google-mobile-ads) for monetization

### Project Structure
```
apps/mobile/
├── src/app/
│   ├── index.jsx          # App entry point
│   └── time-progress.jsx  # Main component
├── ios/                   # iOS native code
│   └── TimeProgressWidget/  # iOS widget extension
├── android/               # Android native code
│   └── app/src/main/java/com/timeprogresstracker/app/
│       └── widget/        # Android widget code
├── app.json               # Expo configuration
└── package.json           # Dependencies
```

### Key Components
- **TimeProgress**: Main component with progress calculations
- **SettingsIcon**: Gear icon with press handler
- **SettingsModal**: Modal for changing preferences
- **TallyCounter**: Animated progress indicators with X/| marks
- **iOS Widget**: Native SwiftUI widget with multiple sizes
- **Android Widget**: Native Kotlin widget with simple layout

## 🎯 What It Does

### Time Calculations
- **Today**: Hours completed vs total hours (24h or 8h office)
- **This Month**: Days completed vs total days in month
- **This Year**: Days completed vs total days in year

### Perspective Logic
- **Half Full**: Shows completed time (what you've accomplished)
- **Half Empty**: Shows remaining time (what's left to do)

### Office Hours Mode
- **9 AM - 5 PM**: 8-hour workday calculation
- **Weekdays Only**: Excludes weekends from calculations
- **Real-time Updates**: Updates every minute

### Native Widgets
- **iOS Widget**: Advanced SwiftUI widget with tally marks and handwritten fonts
  - Small: Hours left today (e.g., "5h left")
  - Medium: Today + This Month progress with tally marks
  - Large: All three (Today, Month, Year) with tally marks
- **Android Widget**: Kotlin widget with custom Kalam font rendering
  - Small (2x2): Today + This Month progress
  - Large (3x2): Today + This Month + This Year progress
  - Custom font via bitmap rendering with TextBitmapUtils
  - White background with 12dp rounded corners
  - Auto-refreshes every hour and syncs with app settings

## 🔧 Development

### Available Scripts
```bash
npm start          # Start Expo development server
npm run web        # Run in web browser
npm run ios        # Run on iOS simulator
npm run android    # Run on Android emulator
```

### Environment Setup
- **Web**: `http://localhost:8081`
- **Mobile**: Scan QR code with Expo Go
- **Simulator**: Use iOS Simulator or Android Studio

## 📦 Deployment

### Build for Production

#### Android AAB (for Play Store):
```bash
cd apps/mobile/android
./gradlew bundleRelease
# Output: apps/mobile/android/app/build/outputs/bundle/release/app-release.aab
```

#### Android APK (for sharing):
```bash
cd apps/mobile/android
./gradlew assembleRelease
# Output: apps/mobile/android/app/build/outputs/apk/release/app-release.apk
```

#### iOS (via Xcode):
```bash
npx expo run:ios --configuration Release
# Then archive in Xcode for App Store
```

### App Store Submission
- **Android**: Google Play Store ready
- **iOS**: Apple App Store ready
- **Bundle ID**: `com.timeprogresstracker.app`

## 🎨 Customization

### Colors & Themes
- Modify colors in `time-progress.jsx` styles
- Add new themes in the StyleSheet
- Customize animations in Reanimated components

### Features
- Add new time calculations
- Implement new perspective modes
- Add notification reminders
- Create data export functionality

## 🐛 Troubleshooting

### Common Issues
- **Version Mismatch**: Use `npx expo install --fix`
- **Metro Cache**: Run `npx expo start --clear`
- **Dependencies**: Use `npm install --legacy-peer-deps`

### Mobile Testing
- **Expo Go**: Scan QR code or enter URL manually
- **Web Browser**: Works perfectly on mobile browsers
- **Development Build**: Use `expo-dev-client` for custom builds

---

**Made with ❤️ using React Native & Expo**
