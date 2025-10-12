# Time Progress Tracker 📊

A beautiful React Native app that tracks your daily, monthly, and yearly progress with a unique perspective-based approach. Choose your glass perspective and see time differently!

## 🚀 Quick Start

### Prerequisites
- Node.js (v18+)
- Expo CLI: `npm install -g @expo/cli`
- Expo Go app on your phone (iOS/Android)

### Installation & Run
```bash
# Install dependencies
cd apps/mobile
npm install

# Start development server
npx expo start

# Scan QR code with Expo Go app
# OR open in browser: http://localhost:8081
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
- **Modern UI**: Clean, intuitive interface
- **Responsive**: Works on phones, tablets, and web
- **Dark/Light Mode**: Automatic theme switching

### ⚙️ Settings
- **Settings Icon**: Gear icon in top-right corner
- **Perspective Control**: Toggle between optimistic/pessimistic views
- **Time Format**: Switch between 24h and 9-5 office hours
- **Persistent Storage**: Settings saved across app sessions

## 📱 How to Use

1. **Open the app** - You'll see your time progress with current perspective
2. **Tap settings icon** (⚙️) in top-right corner
3. **Choose perspective**: Half Full (optimistic) or Half Empty (pessimistic)
4. **Select time mode**: 24 Hours or 9-5 Office Hours
5. **Settings auto-save** - Your preferences are remembered

## 🛠️ Technical Details

### Built With
- **React Native** with Expo SDK 54
- **Expo Router** for navigation
- **AsyncStorage** for data persistence
- **React Native SVG** for icons
- **React Native Reanimated** for animations

### Project Structure
```
apps/mobile/
├── src/app/
│   ├── index.jsx          # App entry point
│   └── time-progress.jsx  # Main component
├── app.json               # Expo configuration
└── package.json           # Dependencies
```

### Key Components
- **TimeProgress**: Main component with progress calculations
- **SettingsIcon**: Gear icon with press handler
- **SettingsModal**: Modal for changing preferences
- **TallyCounter**: Animated progress indicators

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
```bash
# Install EAS CLI
npm install -g @expo/eas-cli

# Login to Expo
eas login

# Build for app stores
eas build --platform all
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
