//
//  TimeProgressApp.swift
//  TimeProgressTracker
//
//  Native iOS App - Main Entry Point
//

import SwiftUI
import WidgetKit

// Note: Using AppDelegate approach instead of @main for compatibility with existing project structure
// The AppDelegate.swift file handles the app lifecycle and creates the SwiftUI view

// MARK: - App State
class AppState: ObservableObject {
    @Published var perspective: Perspective = .halfFull
    @Published var timeMode: TimeMode = .twentyFourHour
    @Published var selectedDisplayItems: [DisplayItem] = [.today, .month, .year]
    @Published var hasCompletedOnboarding: Bool = false
    @Published var showSettings: Bool = false
    @Published var showAddEvent: Bool = false
    @Published var customEvents: [CustomEvent] = []
    @Published var watchComplicationItem: DisplayItem = .today
    @Published var isDarkMode: Bool = false
    @Published var userAge: Int = 30 // Default age
    @Published var lifeExpectancy: Int = 80 // Default life expectancy
    
    init() {
        print("✅ [AppState] AppState initialized")
        loadSettings()
        print("✅ [AppState] hasCompletedOnboarding: \(hasCompletedOnboarding)")
        print("✅ [AppState] selectedDisplayItems count: \(selectedDisplayItems.count)")
    }
    
    func loadSettings() {
        // Load custom events first (needed for validating selectedDisplayItems)
        if let eventsData = UserDefaults.standard.data(forKey: "customEvents"),
           let events = try? JSONDecoder().decode([CustomEvent].self, from: eventsData) {
            self.customEvents = events
        }
        
        if let savedPerspective = UserDefaults.standard.string(forKey: "userPerspective"),
           let perspective = Perspective(rawValue: savedPerspective) {
            self.perspective = perspective
            self.hasCompletedOnboarding = true
        }
        
        if let savedTimeMode = UserDefaults.standard.string(forKey: "timeMode"),
           let timeMode = TimeMode(rawValue: savedTimeMode) {
            self.timeMode = timeMode
        }
        
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        } else {
            // Default to system setting
            self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        if let savedItems = UserDefaults.standard.array(forKey: "selectedDisplayItems") as? [String] {
            let items = savedItems.compactMap { DisplayItem(rawValue: $0) }
            // Filter out custom events that no longer exist
            let validItems = items.filter { item in
                if case .customEvent(let id) = item {
                    return customEvents.contains { $0.id == id }
                }
                return true
            }
            // Ensure at least 3 items, default to today, month, year
            if validItems.count >= 3 {
                self.selectedDisplayItems = validItems
            } else {
                self.selectedDisplayItems = [.today, .month, .year]
            }
        }
        
        // Load watch complication item
        if let savedWatchItem = UserDefaults.standard.string(forKey: "watchComplicationItem"),
           let watchItem = DisplayItem(rawValue: savedWatchItem) {
            self.watchComplicationItem = watchItem
        }
        
        // Load age and life expectancy
        if UserDefaults.standard.object(forKey: "userAge") != nil {
            self.userAge = UserDefaults.standard.integer(forKey: "userAge")
        }
        
        if UserDefaults.standard.object(forKey: "lifeExpectancy") != nil {
            self.lifeExpectancy = UserDefaults.standard.integer(forKey: "lifeExpectancy")
        }
    }
    
    func saveSettings() {
        // Save to standard UserDefaults
        UserDefaults.standard.set(perspective.rawValue, forKey: "userPerspective")
        UserDefaults.standard.set(timeMode.rawValue, forKey: "timeMode")
        UserDefaults.standard.set(selectedDisplayItems.map { $0.rawValue }, forKey: "selectedDisplayItems")
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(userAge, forKey: "userAge")
        UserDefaults.standard.set(lifeExpectancy, forKey: "lifeExpectancy")
        
        // Save custom events
        if let eventsData = try? JSONEncoder().encode(customEvents) {
            UserDefaults.standard.set(eventsData, forKey: "customEvents")
        }
        
        // Save watch complication item
        UserDefaults.standard.set(watchComplicationItem.rawValue, forKey: "watchComplicationItem")
        
        // Also save to App Group for widget/watch access
        if let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker") {
            sharedDefaults.set(perspective.rawValue, forKey: "userPerspective")
            sharedDefaults.set(timeMode.rawValue, forKey: "timeMode")
            sharedDefaults.set(selectedDisplayItems.map { $0.rawValue }, forKey: "selectedDisplayItems")
            sharedDefaults.set(isDarkMode, forKey: "isDarkMode")
            sharedDefaults.set(userAge, forKey: "userAge")
            sharedDefaults.set(lifeExpectancy, forKey: "lifeExpectancy")
            sharedDefaults.set(watchComplicationItem.rawValue, forKey: "watchComplicationItem")
            if let eventsData = try? JSONEncoder().encode(customEvents) {
                sharedDefaults.set(eventsData, forKey: "customEvents")
            }
        }
        
        // Update widgets and watch complications
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum Perspective: String, CaseIterable {
    case halfFull = "half-full"
    case halfEmpty = "half-empty"
}

enum TimeMode: String, CaseIterable {
    case twentyFourHour = "24h"
    case nineToFive = "9-5"
}

enum DisplayItem: Hashable {
    case today
    case month
    case year
    case week
    case quarter
    case customEvent(id: String)
    
    var rawValue: String {
        switch self {
        case .today: return "today"
        case .month: return "month"
        case .year: return "year"
        case .week: return "week"
        case .quarter: return "quarter"
        case .customEvent(let id): return "custom_\(id)"
        }
    }
    
    init?(rawValue: String) {
        if rawValue.hasPrefix("custom_") {
            let id = String(rawValue.dropFirst(7))
            self = .customEvent(id: id)
        } else {
            switch rawValue {
            case "today": self = .today
            case "month": self = .month
            case "year": self = .year
            case "week": self = .week
            case "quarter": self = .quarter
            default: return nil
            }
        }
    }
    
    func displayName(in appState: AppState) -> String {
        switch self {
        case .today: return "Today"
        case .month: return "This Month"
        case .year: return "This Year"
        case .week: return "This Week"
        case .quarter: return "Q4"
        case .customEvent(let id):
            if let event = appState.customEvents.first(where: { $0.id == id }) {
                return event.name
            }
            return "Custom Event"
        }
    }
    
    static var allPredefinedCases: [DisplayItem] {
        [.today, .week, .month, .quarter, .year]
    }
}

