//
//  TimeProgressApp.swift
//  TimeProgressTracker
//
//  Native iOS App - Main Entry Point
//

import Foundation
import SwiftUI
import WidgetKit

enum HomeSection: String, CaseIterable, Codable {
    case countdown
    case countup
    case habits

    var title: String {
        switch self {
        case .countdown: return "Countdowns"
        case .countup: return "Count up"
        case .habits: return "Habits"
        }
    }

    var customizeLabel: String {
        switch self {
        case .countdown: return "Customize Countdowns"
        case .countup: return "Customize Count Ups"
        case .habits: return "Customize Habits"
        }
    }
}

// Note: Using AppDelegate approach instead of @main for compatibility with existing project structure
// The AppDelegate.swift file handles the app lifecycle and creates the SwiftUI view

// MARK: - App State
class AppState: ObservableObject {
    @Published var perspective: Perspective = .halfFull
    @Published var timeMode: TimeMode = .twentyFourHour
    @Published var selectedDisplayItems: [DisplayItem] = [.today, .month, .year]
    @Published var hasCompletedOnboarding: Bool = true
    @Published var showSettings: Bool = false
    @Published var settingsFocus: HomeSection = .countdown
    @Published var showAddEvent: Bool = false
    @Published var pendingAddEventMode: EventMode? = nil
    @Published var customEvents: [CustomEvent] = []
    @Published var watchComplicationItem: DisplayItem = .today
    @Published var isDarkMode: Bool = false
    @Published var userAge: Int = 30 // Default age
    @Published var lifeExpectancy: Int = 80 // Default life expectancy
    @Published var widgetStyle: WidgetStyle = .classic
    @Published var pendingDeepLinkEventID: String? = nil
    @Published var remindersEnabled: Bool = false
    @Published var theme: AppTheme = .classic
    @Published var customBackgroundImageData: Data? = nil
    @Published var showLifeProgress: Bool = true
    @Published var habits: [Habit] = []
    @Published var leaveBalance: LeaveBalance = LeaveBalance(total: 20, used: 0)
    @Published var leaveInsights: LeaveInsights = LeaveInsights(nextLongWeekend: "—", bestSuggestion: "—")
    @Published var holidays: [Holiday] = []
    @Published var selectedHolidayTemplateID: String? = nil
    
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

        if let habitsData = UserDefaults.standard.data(forKey: "habits"),
           let decoded = try? JSONDecoder().decode([Habit].self, from: habitsData) {
            self.habits = decoded
        }

        if let balanceData = UserDefaults.standard.data(forKey: "leaveBalance"),
           let decoded = try? JSONDecoder().decode(LeaveBalance.self, from: balanceData) {
            self.leaveBalance = decoded
        }

        if let insightsData = UserDefaults.standard.data(forKey: "leaveInsights"),
           let decoded = try? JSONDecoder().decode(LeaveInsights.self, from: insightsData) {
            self.leaveInsights = decoded
        }

        if let holidayData = UserDefaults.standard.data(forKey: "holidays"),
           let decoded = try? JSONDecoder().decode([Holiday].self, from: holidayData) {
            self.holidays = decoded
        }
        if let templateID = UserDefaults.standard.string(forKey: "selectedHolidayTemplateID") {
            self.selectedHolidayTemplateID = templateID
            applyHolidayTemplate(id: templateID, save: false)
        }
        
        // Keep all events for unlimited history and count-up tracking.
        
        if let savedPerspective = UserDefaults.standard.string(forKey: "userPerspective"),
           let perspective = Perspective(rawValue: savedPerspective) {
            self.perspective = perspective
        }
        if UserDefaults.standard.object(forKey: "hasCompletedOnboarding") != nil {
            self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
        
        if let savedTimeMode = UserDefaults.standard.string(forKey: "timeMode"),
           let timeMode = TimeMode(rawValue: savedTimeMode) {
            self.timeMode = timeMode
        }

        if let savedWidgetStyle = UserDefaults.standard.string(forKey: "widgetStyle"),
           let style = WidgetStyle(rawValue: savedWidgetStyle) {
            self.widgetStyle = style
        }

        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.theme = theme
        }
        
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        } else {
            // Default to system setting
            self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        if let savedItems = UserDefaults.standard.array(forKey: "selectedDisplayItems") as? [String] {
            let items = savedItems.compactMap { DisplayItem(rawValue: $0) }
            // Filter out custom events that no longer exist (deleted or expired)
            let validItems = items.filter { item in
                if case .customEvent(let id) = item {
                    return customEvents.contains { $0.id == id }
                }
                return true
            }
            
            // Enforce limits: Max 3 predefined, Max 5 custom
            var predefined: [DisplayItem] = []
            var custom: [DisplayItem] = []
            
            for item in validItems {
                if case .customEvent = item {
                    if custom.count < 5 { custom.append(item) }
                } else {
                    if predefined.count < 3 { predefined.append(item) }
                }
            }
            
            var finalItems = predefined + custom
            
            // Ensure at least 3 items default if empty (or very low), using predefined defaults
            if finalItems.isEmpty {
                 finalItems = [.today, .month, .year]
            } else if finalItems.count < 3 && custom.isEmpty {
                 // If user only selected 1 or 2 predefined and no custom, maybe add more predefined?
                 // But sticking to user choice is better if they explicitly chose less.
                 // However, original logic enforced at least 3. Let's keep "defaults if totally invalid" or "preserve valid".
                 // Actually, if we have valid items, trust them, unless everything was invalid.
                 if finalItems.isEmpty {
                      finalItems = [.today, .month, .year]
                 }
            }
            
            self.selectedDisplayItems = finalItems
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

        if let backgroundData = UserDefaults.standard.data(forKey: "customBackgroundImageData") {
            self.customBackgroundImageData = backgroundData
        }

        if UserDefaults.standard.object(forKey: "remindersEnabled") != nil {
            self.remindersEnabled = UserDefaults.standard.bool(forKey: "remindersEnabled")
        }

        if remindersEnabled {
            Task {
                await NotificationManager.shared.applySettings(events: customEvents, enabled: true)
            }
        }
        
        if UserDefaults.standard.object(forKey: "showLifeProgress") != nil {
            self.showLifeProgress = UserDefaults.standard.bool(forKey: "showLifeProgress")
        }

        recomputeLeaveInsights()
    }
    
    func saveSettings() {
        // Save to standard UserDefaults
        UserDefaults.standard.set(perspective.rawValue, forKey: "userPerspective")
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(timeMode.rawValue, forKey: "timeMode")
        UserDefaults.standard.set(selectedDisplayItems.map { $0.rawValue }, forKey: "selectedDisplayItems")
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(userAge, forKey: "userAge")
        UserDefaults.standard.set(lifeExpectancy, forKey: "lifeExpectancy")
        UserDefaults.standard.set(widgetStyle.rawValue, forKey: "widgetStyle")
        UserDefaults.standard.set(remindersEnabled, forKey: "remindersEnabled")
        UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        UserDefaults.standard.set(showLifeProgress, forKey: "showLifeProgress")
        if let customBackgroundImageData {
            UserDefaults.standard.set(customBackgroundImageData, forKey: "customBackgroundImageData")
        } else {
            UserDefaults.standard.removeObject(forKey: "customBackgroundImageData")
        }
        
        // Save custom events
        if let eventsData = try? JSONEncoder().encode(customEvents) {
            UserDefaults.standard.set(eventsData, forKey: "customEvents")
        }

        if let habitsData = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(habitsData, forKey: "habits")
        }

        if let balanceData = try? JSONEncoder().encode(leaveBalance) {
            UserDefaults.standard.set(balanceData, forKey: "leaveBalance")
        }

        recomputeLeaveInsights()
        if let insightsData = try? JSONEncoder().encode(leaveInsights) {
            UserDefaults.standard.set(insightsData, forKey: "leaveInsights")
        }

        if let templateID = selectedHolidayTemplateID {
            UserDefaults.standard.set(templateID, forKey: "selectedHolidayTemplateID")
        } else {
            UserDefaults.standard.removeObject(forKey: "selectedHolidayTemplateID")
        }

        if let holidaysData = try? JSONEncoder().encode(holidays) {
            UserDefaults.standard.set(holidaysData, forKey: "holidays")
        }
        
        // Save watch complication item
        UserDefaults.standard.set(watchComplicationItem.rawValue, forKey: "watchComplicationItem")
        
        // Also save to App Group for widget/watch access
        if let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker") {
            sharedDefaults.set(perspective.rawValue, forKey: "userPerspective")
            sharedDefaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
            sharedDefaults.set(timeMode.rawValue, forKey: "timeMode")
            sharedDefaults.set(selectedDisplayItems.map { $0.rawValue }, forKey: "selectedDisplayItems")
            sharedDefaults.set(isDarkMode, forKey: "isDarkMode")
            sharedDefaults.set(userAge, forKey: "userAge")
            sharedDefaults.set(lifeExpectancy, forKey: "lifeExpectancy")
            sharedDefaults.set(watchComplicationItem.rawValue, forKey: "watchComplicationItem")
            sharedDefaults.set(widgetStyle.rawValue, forKey: "widgetStyle")
            sharedDefaults.set(remindersEnabled, forKey: "remindersEnabled")
            sharedDefaults.set(theme.rawValue, forKey: "appTheme")
            if let eventsData = try? JSONEncoder().encode(customEvents) {
                sharedDefaults.set(eventsData, forKey: "customEvents")
            }
            if let habitsData = try? JSONEncoder().encode(habits) {
                sharedDefaults.set(habitsData, forKey: "habits")
            }
        if let insightsData = try? JSONEncoder().encode(leaveInsights) {
            sharedDefaults.set(insightsData, forKey: "leaveInsights")
        }
        sharedDefaults.set(leaveInsights.nextLongWeekend, forKey: "leave_next_long_weekend")
        sharedDefaults.set(leaveInsights.bestSuggestion, forKey: "leave_best_suggestion")
            if let holidaysData = try? JSONEncoder().encode(holidays) {
                sharedDefaults.set(holidaysData, forKey: "holidays")
            }
            if let templateID = selectedHolidayTemplateID {
                sharedDefaults.set(templateID, forKey: "selectedHolidayTemplateID")
            }
        }

        Task {
            await NotificationManager.shared.applySettings(events: customEvents, enabled: remindersEnabled)
        }
        
        // Update widgets and watch complications
        WidgetCenter.shared.reloadAllTimelines()
    }

    func toggleCheckIn(for event: CustomEvent) {
        if let index = customEvents.firstIndex(where: { $0.id == event.id }) {
            customEvents[index].toggleCheckIn()
            // Mirror to habit with same name if exists
            if event.mode == .habit, let habitIndex = habits.firstIndex(where: { $0.name == event.name }) {
                habits[habitIndex] = habits[habitIndex].checkingInToday()
            }
            saveSettings()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func handleDeepLink(_ url: URL) {
        guard let scheme = url.scheme,
              scheme == "com.prabhakaran.timeprogresstracker" || scheme == "com.timeprogresstracker.app" else {
            return
        }

        let host = url.host ?? ""

        if host == "home" {
            pendingDeepLinkEventID = nil
            return
        }

        if host == "event" {
            let pathComponents = url.pathComponents.dropFirst()
            guard let rawID = pathComponents.first,
                  let decodedID = rawID.removingPercentEncoding else {
                return
            }

            if customEvents.contains(where: { $0.id == decodedID }) {
                pendingDeepLinkEventID = decodedID
            }
        }
    }

    // MARK: - Habits
    func checkInHabit(id: String) {
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[index] = habits[index].checkingInToday()
        saveSettings()
    }

    func addHabit(name: String, startDate: Date = Date()) {
        let habit = Habit(name: name, startDate: startDate)
        habits.append(habit)
        saveSettings()
    }

    func removeHabit(id: String) {
        if let habit = habits.first(where: { $0.id == id }) {
            // Also remove mirrored custom event with same name/mode if present
            customEvents.removeAll { $0.mode == .habit && $0.name == habit.name }
        }
        habits.removeAll { $0.id == id }
        saveSettings()
    }

    // MARK: - Leave Insights
    func recomputeLeaveInsights(now: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        let sortedHolidays = holidays.compactMap { holiday -> (Holiday, Date)? in
            guard let date = holiday.date else { return nil }
            return (holiday, calendar.startOfDay(for: date))
        }
        .filter { $0.1 >= today }
        .sorted { $0.1 < $1.1 }

        // Next long weekend: upcoming holiday that falls on Fri or Mon
        let nextLongWeekend = sortedHolidays.first(where: { (_, date) in
            let weekday = calendar.component(.weekday, from: date)
            return weekday == 6 || weekday == 2 // Friday or Monday
        })

        let nextLongWeekendText: String
        if let (holiday, date) = nextLongWeekend {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let formatted = formatter.string(from: date)
            nextLongWeekendText = "\(holiday.name) • \(formatted)"
        } else {
            nextLongWeekendText = "No long weekend found"
        }

        // Best leave suggestion: nearest upcoming holiday, suggest one adjacent day to make 3-4 day stretch
        var bestSuggestion: String = "Add 1 day to create a long weekend"
        if let (holiday, date) = sortedHolidays.first {
            let weekday = calendar.component(.weekday, from: date)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"

            if weekday == 6 { // Friday holiday: take Monday
                let monday = calendar.date(byAdding: .day, value: 3, to: date) ?? date
                bestSuggestion = "Take Monday off around \(holiday.name) (\(formatter.string(from: monday)))"
            } else if weekday == 2 { // Monday holiday: take Friday
                let friday = calendar.date(byAdding: .day, value: -3, to: date) ?? date
                bestSuggestion = "Take Friday off around \(holiday.name) (\(formatter.string(from: friday)))"
            } else if weekday == 3 { // Tuesday -> take Monday
                let monday = calendar.date(byAdding: .day, value: -1, to: date) ?? date
                bestSuggestion = "Take Monday off around \(holiday.name) (\(formatter.string(from: monday)))"
            } else if weekday == 5 { // Thursday -> take Friday
                let friday = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                bestSuggestion = "Take Friday off around \(holiday.name) (\(formatter.string(from: friday)))"
            } else {
                let adjacent = calendar.date(byAdding: .day, value: -1, to: date) ?? date
                bestSuggestion = "Plan 1 day off near \(holiday.name) (\(formatter.string(from: adjacent)))"
            }
        }

        leaveInsights = LeaveInsights(nextLongWeekend: nextLongWeekendText, bestSuggestion: bestSuggestion)
    }

    func applyHolidayTemplate(id: String, save: Bool = true) {
        guard let template = HolidayTemplateLibrary.shared.templates.first(where: { $0.id == id }) else { return }
        holidays = template.holidays
        selectedHolidayTemplateID = id
        recomputeLeaveInsights()
        if save { saveSettings() }
        // Mirror to UserDefaults immediately so home refresh sees latest country
        UserDefaults.standard.set(id, forKey: "selectedHolidayTemplateID")
        if let holidaysData = try? JSONEncoder().encode(holidays) {
            UserDefaults.standard.set(holidaysData, forKey: "holidays")
        }
        if let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker") {
            sharedDefaults.set(id, forKey: "selectedHolidayTemplateID")
            if let holidaysData = try? JSONEncoder().encode(holidays) {
                sharedDefaults.set(holidaysData, forKey: "holidays")
            }
        }
    }

    static let defaultHolidays: [Holiday] = [
        Holiday(name: "Republic Day", dateString: "2026-01-26"),
        Holiday(name: "Ambedkar Jayanti", dateString: "2026-04-14"),
        Holiday(name: "May Day", dateString: "2026-05-01"),
        Holiday(name: "Independence Day", dateString: "2026-08-15"),
        Holiday(name: "Gandhi Jayanti", dateString: "2026-10-02"),
        Holiday(name: "Dussehra", dateString: "2026-10-24"),
        Holiday(name: "Diwali", dateString: "2026-11-12"),
        Holiday(name: "Christmas", dateString: "2026-12-25")
    ]
}

enum Perspective: String, CaseIterable {
    case halfFull = "half-full"
    case halfEmpty = "half-empty"
}

enum TimeMode: String, CaseIterable {
    case twentyFourHour = "24h"
    case nineToFive = "9-5"
}

enum WidgetStyle: String, CaseIterable {
    case classic = "classic"
    case minimal = "minimal"
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
