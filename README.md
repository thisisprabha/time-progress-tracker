# Time Progress Tracker

A unique time tracking app that helps you visualize your daily, monthly, and yearly progress with a perspective-based approach. Choose between optimistic (glass half-full) or pessimistic (glass half-empty) views to see time differently.

## 🚀 Features

### Core Functionality
- **Perspective-Based Tracking**: Switch between optimistic and pessimistic views
- **Multiple Time Modes**: 24-hour format or 9-5 office hours
- **Visual Progress**: Tally marks (✗ for completed, | for remaining) instead of boring progress bars
- **Handwritten Style**: Custom fonts for a personal, handwritten feel
- **Real-time Updates**: Live progress tracking throughout the day

### Time Tracking
- **Today**: Hours completed/remaining (24h or 9-5 mode)
- **This Month**: Days completed/remaining in current month
- **This Year**: Days completed/remaining in current year

### Cross-Platform Support
- **iOS App**: Native iOS app with WidgetKit widgets
- **Android App**: Native Android app with AppWidgetProvider widgets
- **Web App**: Progressive Web App (PWA) support

## 📱 Native Widgets

### iOS Widget
- **Small**: Shows hours left/completed for today
- **Medium**: Shows today and month progress with tally marks
- **Large**: Shows all three (today, month, year) with visual progress

### Android Widget
- **Dynamic Sizing**: Adapts to content height
- **Rounded Corners**: 12dp radius for modern look
- **Theme Support**: Automatically adapts to light/dark themes
- **Tally Marks**: Visual progress with ✗ and | characters

## 🛠 Technical Stack

- **Framework**: React Native with Expo
- **Platform**: iOS, Android, Web
- **State Management**: React hooks with AsyncStorage
- **Styling**: StyleSheet with custom fonts
- **Widgets**: 
  - iOS: WidgetKit (Swift/SwiftUI)
  - Android: AppWidgetProvider (Kotlin)
- **Build System**: EAS Build for deployment

## 📦 Installation & Setup

### Prerequisites
- Node.js (v18+)
- npm or yarn
- Expo CLI
- iOS Simulator (for iOS development)
- Android Studio (for Android development)

### Quick Start
```bash
# Clone the repository
git clone https://github.com/yourusername/time-progress-tracker.git
cd time-progress-tracker

# Install dependencies
cd apps/mobile
npm install

# Start development server
npx expo start
```

### Development Commands
```bash
# Start Expo development server
npx expo start

# Run on iOS simulator
npx expo run:ios

# Run on Android device/emulator
npx expo run:android

# Build for production
npx eas build --platform all
```

## 🎨 Customization

### Changing Perspectives
- Tap the settings icon (⚙️) in the top right
- Choose between "Optimistic" or "Pessimistic"
- Settings are automatically saved

### Time Mode Selection
- In settings, choose between:
  - **24h**: Full day tracking (24 hours)
  - **9-5**: Office hours tracking (9 AM to 5 PM)

### Widget Configuration
- **iOS**: Long press widget → Edit Widget → Configure
- **Android**: Widget automatically uses app settings

## 📱 Platform-Specific Setup

### iOS Development
```bash
# Install iOS dependencies
cd ios
pod install

# Run on iOS simulator
npx expo run:ios
```

### Android Development
```bash
# Set up Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Run on Android device
npx expo run:android
```

## 🚀 Deployment

### App Store (iOS)
1. Build with EAS: `npx eas build --platform ios`
2. Upload to App Store Connect
3. Submit for review

### Google Play Store (Android)
1. Build with EAS: `npx eas build --platform android`
2. Upload to Google Play Console
3. Submit for review

### Web Deployment
1. Build web version: `npx expo export --platform web`
2. Deploy to hosting service (Vercel, Netlify, etc.)

## 📊 Widget Implementation

### iOS Widget (WidgetKit)
- **Location**: `ios/TimeProgressWidget/`
- **Language**: Swift with SwiftUI
- **Features**: Multiple sizes, configuration, live updates

### Android Widget (AppWidgetProvider)
- **Location**: `android/app/src/main/java/com/timeprogresstracker/app/widget/`
- **Language**: Kotlin
- **Features**: Dynamic sizing, theme support, rounded corners

## 🔧 Configuration

### App Configuration (`app.json`)
```json
{
  "expo": {
    "name": "Time Progress Tracker",
    "slug": "time-progress-tracker",
    "version": "1.0.0",
    "platforms": ["ios", "android", "web"]
  }
}
```

### Widget Settings
- **Update Frequency**: Every 15 minutes
- **Resize Options**: All sizes supported
- **Configuration**: Built-in settings panel

## 📈 Progress Calculation

### Time Logic
- **Today**: Current hour vs total hours (24 or 8)
- **Month**: Current day vs total days in month
- **Year**: Current day vs total days in year

### Perspective Logic
- **Optimistic**: Shows completed progress ("5h completed")
- **Pessimistic**: Shows remaining progress ("19h left")

## 🎯 Future Enhancements

- [ ] Custom time ranges
- [ ] Multiple time zones
- [ ] Progress notifications
- [ ] Data export/import
- [ ] Widget themes
- [ ] Apple Watch support
- [ ] Wear OS support

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both platforms
5. Submit a pull request

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check the documentation
- Review the troubleshooting guide

---

**Built with ❤️ using React Native and Expo**