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
    @Published var selectedDisplayItems: Set<DisplayItem> = [.today, .month, .year]
    @Published var hasCompletedOnboarding: Bool = false
    @Published var showSettings: Bool = false
    @Published var customEvents: [CustomEvent] = []
    @Published var watchComplicationItem: DisplayItem = .today
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        if let savedPerspective = UserDefaults.standard.string(forKey: "userPerspective"),
           let perspective = Perspective(rawValue: savedPerspective) {
            self.perspective = perspective
            self.hasCompletedOnboarding = true
        }
        
        if let savedTimeMode = UserDefaults.standard.string(forKey: "timeMode"),
           let timeMode = TimeMode(rawValue: savedTimeMode) {
            self.timeMode = timeMode
        }
        
        if let savedItems = UserDefaults.standard.array(forKey: "selectedDisplayItems") as? [String] {
            let items = Set(savedItems.compactMap { DisplayItem(rawValue: $0) })
            // Ensure at least 3 items, default to today, month, year
            if items.count >= 3 {
                self.selectedDisplayItems = items
            } else {
                self.selectedDisplayItems = [.today, .month, .year]
            }
        }
        
        // Load custom events
        if let eventsData = UserDefaults.standard.data(forKey: "customEvents"),
           let events = try? JSONDecoder().decode([CustomEvent].self, from: eventsData) {
            self.customEvents = events
        }
        
        // Load watch complication item
        if let savedWatchItem = UserDefaults.standard.string(forKey: "watchComplicationItem"),
           let watchItem = DisplayItem(rawValue: savedWatchItem) {
            self.watchComplicationItem = watchItem
        }
    }
    
    func saveSettings() {
        // Save to standard UserDefaults
        UserDefaults.standard.set(perspective.rawValue, forKey: "userPerspective")
        UserDefaults.standard.set(timeMode.rawValue, forKey: "timeMode")
        UserDefaults.standard.set(Array(selectedDisplayItems.map { $0.rawValue }), forKey: "selectedDisplayItems")
        
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
            sharedDefaults.set(Array(selectedDisplayItems.map { $0.rawValue }), forKey: "selectedDisplayItems")
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

enum DisplayItem: String, CaseIterable {
    case today = "today"
    case month = "month"
    case year = "year"
    case week = "week"
    case quarter = "quarter"
    case custom = "custom"
}

