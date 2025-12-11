# 🎯 Life Progress Feature - Implementation Plan

## Overview
Add "Life Progress" tracking showing percentage of life lived, days until retirement, and next birthday milestone.

---

## 📋 Data Model Changes

### 1. Add User Profile Data

**File: `apps/mobile/ios/TimeProgressTracker/AppState.swift`**

```swift
class AppState: ObservableObject {
    // ... existing properties ...
    
    // Life Progress Data
    @Published var birthDate: Date? = nil
    @Published var retirementAge: Int? = nil
    @Published var lifeExpectancy: Int? = nil // Optional, default to country average
    
    // Load from UserDefaults
    func loadLifeProgressSettings() {
        if let birthDateString = UserDefaults.standard.string(forKey: "birthDate") {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthDate = formatter.date(from: birthDateString)
        }
        retirementAge = UserDefaults.standard.integer(forKey: "retirementAge")
        if retirementAge == 0 { retirementAge = nil }
        
        lifeExpectancy = UserDefaults.standard.integer(forKey: "lifeExpectancy")
        if lifeExpectancy == 0 { 
            // Default to country average (US: 77, adjust based on user location)
            lifeExpectancy = 77 
        }
    }
    
    func saveLifeProgressSettings() {
        if let birthDate = birthDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            UserDefaults.standard.set(formatter.string(from: birthDate), forKey: "birthDate")
        }
        if let retirementAge = retirementAge {
            UserDefaults.standard.set(retirementAge, forKey: "retirementAge")
        }
        if let lifeExpectancy = lifeExpectancy {
            UserDefaults.standard.set(lifeExpectancy, forKey: "lifeExpectancy")
        }
    }
}
```

### 2. Add Life Progress Display Item

**File: `apps/mobile/ios/TimeLeftTrackerWidget/SharedTypes.swift`**

```swift
enum DisplayItem: Hashable, Codable {
    case today
    case month
    case year
    case week
    case quarter
    case customEvent(id: String)
    case lifeProgress(type: LifeProgressType) // NEW
    
    enum LifeProgressType: String, Codable {
        case lifeLived = "life-lived"        // % of life lived
        case retirement = "retirement"        // Days until retirement
        case nextMilestone = "next-milestone" // Days until next birthday milestone (30, 40, 50, etc.)
    }
    
    var rawValue: String {
        switch self {
        // ... existing cases ...
        case .lifeProgress(let type): return "life_\(type.rawValue)"
        }
    }
    
    init?(rawValue: String) {
        if rawValue.hasPrefix("life_") {
            let typeString = String(rawValue.dropFirst(5))
            if let type = LifeProgressType(rawValue: typeString) {
                self = .lifeProgress(type: type)
                return
            }
        }
        // ... existing init logic ...
    }
}

extension DisplayItem {
    func displayName(in customEvents: [CustomEvent], quarterNumber: Int) -> String {
        switch self {
        // ... existing cases ...
        case .lifeProgress(let type):
            switch type {
            case .lifeLived: return "Life Progress"
            case .retirement: return "Retirement"
            case .nextMilestone: return "Next Milestone"
            }
        }
    }
}
```

### 3. Add Life Progress Calculator

**File: `apps/mobile/ios/TimeLeftTrackerWidget/SharedTypes.swift`**

```swift
struct LifeProgressData {
    let lifeProgressPercent: Double  // 0.0 to 1.0
    let daysUntilRetirement: Int
    let daysUntilNextMilestone: Int
    let nextMilestoneAge: Int
    let currentAge: Int
    let yearsUntilRetirement: Int
}

class LifeProgressCalculator {
    static func calculate(birthDate: Date?, retirementAge: Int?, lifeExpectancy: Int?) -> LifeProgressData? {
        guard let birthDate = birthDate else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate current age
        let ageComponents = calendar.dateComponents([.year, .month, .day], from: birthDate, to: now)
        let currentAge = ageComponents.year ?? 0
        let currentAgeDays = calendar.dateComponents([.day], from: birthDate, to: now).day ?? 0
        
        // Calculate life progress (if life expectancy provided)
        let lifeExpectancyValue = lifeExpectancy ?? 77 // Default
        let lifeProgressPercent = Double(currentAge) / Double(lifeExpectancyValue)
        
        // Calculate retirement
        let retirementAgeValue = retirementAge ?? 65 // Default
        let retirementDate = calendar.date(byAdding: .year, value: retirementAgeValue, to: birthDate) ?? now
        let daysUntilRetirement = max(0, calendar.dateComponents([.day], from: now, to: retirementDate).day ?? 0)
        let yearsUntilRetirement = max(0, retirementAgeValue - currentAge)
        
        // Calculate next milestone (30, 40, 50, 60, 70, 80, etc.)
        let milestones = [30, 40, 50, 60, 70, 80, 90, 100]
        let nextMilestone = milestones.first { $0 > currentAge } ?? (currentAge + 10)
        let nextMilestoneDate = calendar.date(byAdding: .year, value: nextMilestone, to: birthDate) ?? now
        let daysUntilNextMilestone = max(0, calendar.dateComponents([.day], from: now, to: nextMilestoneDate).day ?? 0)
        
        return LifeProgressData(
            lifeProgressPercent: lifeProgressPercent,
            daysUntilRetirement: daysUntilRetirement,
            daysUntilNextMilestone: daysUntilNextMilestone,
            nextMilestoneAge: nextMilestone,
            currentAge: currentAge,
            yearsUntilRetirement: yearsUntilRetirement
        )
    }
}
```

### 4. Update TimeData to Include Life Progress

**File: `apps/mobile/ios/TimeLeftTrackerWidget/SharedTypes.swift`**

```swift
struct TimeData {
    // ... existing properties ...
    let lifeProgress: LifeProgressData? // NEW
}

class TimeCalculator {
    static func calculateTimeData(timeMode: TimeMode, birthDate: Date? = nil, retirementAge: Int? = nil, lifeExpectancy: Int? = nil) -> TimeData {
        // ... existing calculations ...
        
        let lifeProgress = LifeProgressCalculator.calculate(
            birthDate: birthDate,
            retirementAge: retirementAge,
            lifeExpectancy: lifeExpectancy
        )
        
        return TimeData(
            // ... existing properties ...
            lifeProgress: lifeProgress
        )
    }
}
```

---

## 🎨 UI Changes

### 1. Add Life Progress Settings View

**File: `apps/mobile/ios/TimeProgressTracker/LifeProgressSettingsView.swift`** (NEW)

```swift
import SwiftUI

struct LifeProgressSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var birthDate: Date = Date()
    @State private var retirementAge: Int = 65
    @State private var lifeExpectancy: Int = 77
    
    var body: some View {
        Form {
            Section {
                DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            } header: {
                Text("Your Information")
            } footer: {
                Text("Used to calculate your life progress")
            }
            
            Section {
                Stepper("Retirement Age: \(retirementAge)", value: $retirementAge, in: 50...80)
                Stepper("Life Expectancy: \(lifeExpectancy)", value: $lifeExpectancy, in: 60...100)
            } header: {
                Text("Goals & Expectations")
            } footer: {
                Text("Defaults: Retirement 65, Life Expectancy 77")
            }
            
            Section {
                if let lifeData = LifeProgressCalculator.calculate(
                    birthDate: birthDate,
                    retirementAge: retirementAge,
                    lifeExpectancy: lifeExpectancy
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Age: \(lifeData.currentAge)")
                        Text("Life Progress: \(Int(lifeData.lifeProgressPercent * 100))%")
                        Text("Days until Retirement: \(lifeData.daysUntilRetirement)")
                        Text("Days until \(lifeData.nextMilestoneAge)th Birthday: \(lifeData.daysUntilNextMilestone)")
                    }
                    .font(.sabdeviRegular(size: 14))
                }
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Life Progress")
        .onAppear {
            if let birthDate = appState.birthDate {
                self.birthDate = birthDate
            }
            if let retirementAge = appState.retirementAge {
                self.retirementAge = retirementAge
            }
            if let lifeExpectancy = appState.lifeExpectancy {
                self.lifeExpectancy = lifeExpectancy
            }
        }
        .onChange(of: birthDate) { newValue in
            appState.birthDate = newValue
            appState.saveLifeProgressSettings()
        }
        .onChange(of: retirementAge) { newValue in
            appState.retirementAge = newValue
            appState.saveLifeProgressSettings()
        }
        .onChange(of: lifeExpectancy) { newValue in
            appState.lifeExpectancy = newValue
            appState.saveLifeProgressSettings()
        }
    }
}
```

### 2. Update Settings View

**File: `apps/mobile/ios/TimeProgressTracker/SettingsView.swift`**

Add new section:

```swift
// Life Progress Section
Section {
    if appState.birthDate == nil {
        Button(action: {
            // Show life progress setup
            appState.showLifeProgressSetup = true
        }) {
            HStack {
                Text("Set up Life Progress")
                    .font(.sabdeviRegular(size: 14))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    } else {
        NavigationLink(destination: LifeProgressSettingsView()) {
            Text("Life Progress")
                .font(.sabdeviRegular(size: 14))
        }
    }
} header: {
    Text("Life Progress")
} footer: {
    Text("Track your life journey and milestones")
}
```

### 3. Add Life Progress to Display Items

**File: `apps/mobile/ios/TimeProgressTracker/SettingsView.swift`**

In "Customize Display" section, add:

```swift
// Life Progress items (only show if birth date is set)
if appState.birthDate != nil {
    let lifeProgressItems: [DisplayItem] = [
        .lifeProgress(type: .lifeLived),
        .lifeProgress(type: .retirement),
        .lifeProgress(type: .nextMilestone)
    ]
    
    ForEach(lifeProgressItems, id: \.self) { item in
        // ... same SettingsRow logic as other items ...
    }
}
```

### 4. Update Main Display View

**File: `apps/mobile/ios/TimeProgressTracker/MainHomeView.swift`**

Add handling for life progress items in the display logic.

---

## 📱 Widget Updates

### Update Widget Entry Loading

**File: `apps/mobile/ios/TimeLeftTrackerWidget/TimeLeftTrackerWidget.swift`**

```swift
private func loadEntry() -> SimpleEntry {
    let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
    
    // ... existing loading ...
    
    // Load life progress data
    var birthDate: Date? = nil
    var retirementAge: Int? = nil
    var lifeExpectancy: Int? = nil
    
    if let birthDateString = sharedDefaults?.string(forKey: "birthDate") {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        birthDate = formatter.date(from: birthDateString)
    }
    
    let retirementAgeValue = sharedDefaults?.integer(forKey: "retirementAge") ?? 0
    if retirementAgeValue > 0 {
        retirementAge = retirementAgeValue
    }
    
    let lifeExpectancyValue = sharedDefaults?.integer(forKey: "lifeExpectancy") ?? 0
    if lifeExpectancyValue > 0 {
        lifeExpectancy = lifeExpectancyValue
    }
    
    let timeData = TimeCalculator.calculateTimeData(
        timeMode: timeMode,
        birthDate: birthDate,
        retirementAge: retirementAge,
        lifeExpectancy: lifeExpectancy
    )
    
    // ... rest of entry creation ...
}
```

### Update Value Calculation

**File: `apps/mobile/ios/TimeLeftTrackerWidget/TimeLeftTrackerWidget.swift`**

```swift
func getValueAndTotal(item: DisplayItem, entry: SimpleEntry) -> (Int, Int) {
    switch item {
    // ... existing cases ...
    
    case .lifeProgress(let type):
        guard let lifeData = entry.timeData.lifeProgress else {
            return (0, 100)
        }
        
        switch type {
        case .lifeLived:
            // Return percentage (0-100)
            return (Int(lifeData.lifeProgressPercent * 100), 100)
            
        case .retirement:
            // Return days until retirement
            return (lifeData.daysUntilRetirement, lifeData.daysUntilRetirement + 365) // Approximate
            
        case .nextMilestone:
            // Return days until next milestone
            return (lifeData.daysUntilNextMilestone, 365 * (lifeData.nextMilestoneAge - lifeData.currentAge))
        }
    }
}
```

---

## 🔄 Data Sync (App Group)

**File: `apps/mobile/ios/TimeProgressTracker/AppState.swift`**

```swift
func saveSettings() {
    // ... existing save logic ...
    
    // Save to App Group for widget
    let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
    
    if let birthDate = birthDate {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        sharedDefaults?.set(formatter.string(from: birthDate), forKey: "birthDate")
    }
    
    if let retirementAge = retirementAge {
        sharedDefaults?.set(retirementAge, forKey: "retirementAge")
    }
    
    if let lifeExpectancy = lifeExpectancy {
        sharedDefaults?.set(lifeExpectancy, forKey: "lifeExpectancy")
    }
    
    // Reload widgets
    WidgetCenter.shared.reloadAllTimelines()
}
```

---

## 🎯 Display Format Examples

### Life Progress (Life Lived)
- **Label**: "Life Progress"
- **Value**: "35%" (of life lived)
- **Unit**: "% lived" or "% done"

### Retirement
- **Label**: "Retirement"
- **Value**: "12,345" (days)
- **Unit**: "days left" or "days until"

### Next Milestone
- **Label**: "Next Milestone"
- **Value**: "234" (days)
- **Unit**: "days until 40" (shows next milestone age)

---

## ✅ Implementation Checklist

- [ ] Add `birthDate`, `retirementAge`, `lifeExpectancy` to AppState
- [ ] Create `LifeProgressData` struct
- [ ] Create `LifeProgressCalculator` class
- [ ] Add `LifeProgressType` enum to `DisplayItem`
- [ ] Update `TimeData` to include `lifeProgress`
- [ ] Create `LifeProgressSettingsView`
- [ ] Add Life Progress section to Settings
- [ ] Add Life Progress items to Display selection
- [ ] Update widget entry loading
- [ ] Update `getValueAndTotal` for life progress
- [ ] Update display name logic
- [ ] Test with various ages
- [ ] Add to onboarding (optional)
- [ ] Update widget previews

---

## 🚀 Quick Start Implementation

**Priority Order:**
1. **Life Progress (Life Lived)** - Simplest, most impactful
2. **Retirement** - High value for working users
3. **Next Milestone** - Nice addition, less critical

**Start with Life Progress (Life Lived)** - it's the easiest and most emotional!


