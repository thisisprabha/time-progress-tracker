# Native Widget Implementation Guide

Complete guide for implementing and testing native iOS and Android widgets for the Time Progress Tracker app.

## 📱 Overview

This guide covers the implementation of native widgets for both iOS and Android platforms, including:
- iOS WidgetKit widgets (Swift/SwiftUI)
- Android AppWidgetProvider widgets (Kotlin)
- Cross-platform data sharing
- Widget configuration and updates

## 🍎 iOS Widget Implementation

### Project Structure
```
ios/TimeProgressWidget/
├── TimeProgressWidget.swift          # Main widget implementation
├── TimeProgressWidgetBundle.swift    # Widget bundle entry point
├── AppIntent.swift                   # Widget configuration
├── Info.plist                       # Widget metadata
└── TimeProgressWidget.intentdefinition # Widget intents
```

### Key Features
- **Multiple Sizes**: Small, Medium, Large
- **Dynamic Content**: Real-time progress updates
- **Configuration**: Built-in settings panel
- **Visual Style**: Tally marks with handwritten fonts
- **Theme Support**: Light/dark mode adaptation

### Widget Sizes

#### Small Widget
- **Content**: Hours left/completed for today
- **Layout**: Vertical stack with hours on top, "For today" below
- **Font**: Handwritten style (Marker Felt)

#### Medium Widget
- **Content**: Today and This Month progress
- **Layout**: Two sections with tally marks
- **Visual**: ✗ for completed, | for remaining

#### Large Widget
- **Content**: Today, This Month, This Year
- **Layout**: Three sections with full progress
- **Features**: Complete time tracking overview

### Implementation Details

#### Data Sharing
```swift
// App Groups for data sharing
let sharedDefaults = UserDefaults(suiteName: "group.com.timeprogresstracker.app")
```

#### Tally Marks View
```swift
struct TallyMarksView: View {
    let completed: Int
    let total: Int
    
    var body: some View {
        HStack {
            // Completed marks (duller)
            ForEach(0..<completed, id: \.self) { _ in
                Text("✗")
                    .foregroundColor(.primary.opacity(0.6))
            }
            // Remaining marks
            ForEach(0..<(total - completed), id: \.self) { _ in
                Text("|")
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
}
```

## 🤖 Android Widget Implementation

### Project Structure
```
android/app/src/main/
├── java/com/timeprogresstracker/app/widget/
│   └── TimeProgressWidget.kt         # Widget provider
├── res/
│   ├── layout/
│   │   └── time_progress_widget_simple.xml  # Widget layout
│   ├── drawable/
│   │   └── widget_background_rounded.xml    # Background shape
│   └── xml/
│       └── time_progress_widget_info.xml    # Widget metadata
└── AndroidManifest.xml               # Widget registration
```

### Key Features
- **Dynamic Sizing**: Wrap content height
- **Rounded Corners**: 12dp radius background
- **Theme Support**: Automatic light/dark adaptation
- **Tally Marks**: Dynamic ✗ and | generation
- **Handwritten Fonts**: Cursive font family

### Widget Layout
```xml
<LinearLayout
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="8dp"
    android:background="@drawable/widget_background_rounded">
    
    <!-- Today Section -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal">
        
        <TextView
            android:id="@+id/today_label"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="Today"
            android:textSize="14sp"
            android:textColor="?android:attr/textColorPrimary"
            android:fontFamily="cursive"
            android:gravity="start" />
        
        <TextView
            android:id="@+id/today_text"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="6h left"
            android:textSize="16sp"
            android:textStyle="bold"
            android:textColor="?android:attr/textColorPrimary"
            android:fontFamily="cursive"
            android:gravity="end" />
    </LinearLayout>
    
    <!-- Tally Marks Container -->
    <LinearLayout
        android:id="@+id/today_tally_container"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal" />
</LinearLayout>
```

### Background Drawable
```xml
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#FFFFFF" />
    <corners android:radius="12dp" />
</shape>
```

## 🔄 Data Sharing

### iOS App Groups
```swift
// Save data
let sharedDefaults = UserDefaults(suiteName: "group.com.timeprogresstracker.app")
sharedDefaults?.set(perspective, forKey: "userPerspective")
sharedDefaults?.set(timeMode, forKey: "timeMode")

// Read data in widget
let perspective = sharedDefaults?.string(forKey: "userPerspective") ?? "optimistic"
```

### Android SharedPreferences
```kotlin
// Save data
val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
prefs.edit().putString("userPerspective", perspective).apply()

// Read data in widget
val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
val perspective = prefs.getString("userPerspective", "optimistic") ?: "optimistic"
```

## 🎨 Styling Guidelines

### Fonts
- **iOS**: `Marker Felt` (handwritten style)
- **Android**: `cursive` font family
- **Consistency**: Same handwritten feel across platforms

### Colors
- **Background**: White with rounded corners
- **Text**: Theme-adaptive (`textColorPrimary`)
- **Tally Marks**: 
  - Completed: Duller opacity (0.6)
  - Remaining: Full opacity (1.0)

### Layout
- **Alignment**: Left-aligned labels, right-aligned values
- **Spacing**: Consistent padding and margins
- **Height**: Dynamic (wrap_content) for Android

## 🧪 Testing

### iOS Testing
1. **Build**: `npx expo run:ios`
2. **Add Widget**: Long press home screen → Add Widget
3. **Configure**: Tap widget → Edit Widget
4. **Test**: Different sizes and configurations

### Android Testing
1. **Build**: `npx expo run:android`
2. **Add Widget**: Long press home screen → Widgets
3. **Find**: "Time Progress Tracker" in widget picker
4. **Test**: Add to home screen and verify updates

### Cross-Platform Testing
- **Data Sync**: Change settings in app, verify widget updates
- **Theme**: Test light/dark mode adaptation
- **Updates**: Verify real-time progress updates

## 🔧 Configuration

### Widget Metadata

#### iOS Info.plist
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>NSExtensionPointIdentifier</key>
<string>com.apple.widgetkit-extension</string>
```

#### Android Widget Info
```xml
<appwidget-provider
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="900000"
    android:initialLayout="@layout/time_progress_widget_simple"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
```

### Update Frequency
- **iOS**: Automatic (system-managed)
- **Android**: 15 minutes (`900000` milliseconds)

## 🚀 Deployment

### iOS Widget
- **Included**: Automatically included in iOS app build
- **Distribution**: Via App Store with main app
- **Requirements**: iOS 14+ for WidgetKit

### Android Widget
- **Included**: Automatically included in Android app build
- **Distribution**: Via Google Play Store with main app
- **Requirements**: Android API 24+ (Android 7.0)

## 🐛 Troubleshooting

### Common Issues

#### iOS Widget Not Appearing
1. **Check**: Info.plist version matches main app
2. **Verify**: Widget bundle includes correct widget
3. **Clean**: Delete derived data and rebuild

#### Android Widget Not Showing
1. **Check**: AndroidManifest.xml registration
2. **Verify**: Widget info XML configuration
3. **Test**: Widget picker for app name

#### Data Not Syncing
1. **iOS**: Verify App Groups configuration
2. **Android**: Check SharedPreferences keys
3. **Test**: Save/load data in both app and widget

#### Styling Issues
1. **Fonts**: Verify font availability
2. **Colors**: Check theme attribute usage
3. **Layout**: Test different screen sizes

## 📚 Resources

- [iOS WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Android App Widgets Guide](https://developer.android.com/guide/topics/appwidgets)
- [Expo Native Development](https://docs.expo.dev/workflow/customizing/)
- [React Native Widgets](https://reactnative.dev/docs/native-modules-intro)

## 🎯 Best Practices

### Performance
- **Minimize**: Widget update frequency
- **Cache**: Data for offline access
- **Optimize**: Layout complexity

### User Experience
- **Consistent**: Styling across platforms
- **Intuitive**: Widget configuration
- **Reliable**: Data synchronization

### Maintenance
- **Version**: Keep widget and app versions in sync
- **Test**: Regular testing on both platforms
- **Update**: Follow platform guidelines

---

**Native Widgets: Bringing Your App to the Home Screen! 📱**