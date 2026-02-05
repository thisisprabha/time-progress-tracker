//
//  SharedTypes.swift
//  TimeLeftTrackerWidget
//
//  Shared types for widget and main app
//

import Foundation
import SwiftUI
import UIKit

// Copy of types needed by widget
enum Perspective: String, Codable {
    case halfFull = "half-full"
    case halfEmpty = "half-empty"
}

enum TimeMode: String, Codable {
    case twentyFourHour = "24h"
    case nineToFive = "9-5"
}

enum WidgetStyle: String, Codable {
    case classic = "classic"
    case minimal = "minimal"
}

enum DisplayItem: Hashable, Codable {
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
}

enum EventCategory: String, Codable, CaseIterable {
    case personal
    case work
    case family
    case custom
}

enum EventMode: String, Codable, CaseIterable {
    case countdown
    case countup
    case habit
}

enum EventRecurrence: String, Codable, CaseIterable {
    case none
    case weekly
    case monthly
    case yearly
}

struct CustomEvent: Identifiable, Codable {
    let id: String
    let name: String
    let date: String // ISO format: YYYY-MM-DD
    let startDate: String // ISO format: YYYY-MM-DD
    let category: EventCategory
    let mode: EventMode
    let recurrence: EventRecurrence
    let timeOfDay: String? // "HH:mm"
    var streakHistory: Set<String> // ISO dates "YYYY-MM-DD"

    init(
        id: String = UUID().uuidString,
        name: String,
        date: String,
        startDate: String? = nil,
        category: EventCategory = .personal,
        mode: EventMode = .countdown,
        recurrence: EventRecurrence = .none,
        timeOfDay: String? = nil,
        streakHistory: Set<String> = []
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.category = category
        self.mode = mode
        self.recurrence = recurrence
        self.timeOfDay = timeOfDay
        self.streakHistory = streakHistory
        
        if let start = startDate {
            self.startDate = start
        } else {
            // Default to today
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.startDate = dateFormatter.string(from: Date())
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case date
        case startDate
        case category
        case mode
        case recurrence
        case timeOfDay
        case streakHistory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(String.self, forKey: .date)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate) ?? date
        category = try container.decodeIfPresent(EventCategory.self, forKey: .category) ?? .personal
        mode = try container.decodeIfPresent(EventMode.self, forKey: .mode) ?? .countdown
        recurrence = try container.decodeIfPresent(EventRecurrence.self, forKey: .recurrence) ?? .none
        timeOfDay = try container.decodeIfPresent(String.self, forKey: .timeOfDay)
        streakHistory = try container.decodeIfPresent(Set<String>.self, forKey: .streakHistory) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(date, forKey: .date)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(category, forKey: .category)
        try container.encode(mode, forKey: .mode)
        try container.encode(recurrence, forKey: .recurrence)
        try container.encodeIfPresent(timeOfDay, forKey: .timeOfDay)
        try container.encode(streakHistory, forKey: .streakHistory)
    }
    
    func calculateProgress() -> (daysLeft: Int, weeksLeft: Int, useWeeks: Bool, isPast: Bool, isToday: Bool, formattedDate: String, totalDays: Int, daysCompleted: Int) {
        let now = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeComponents = timeOfDayComponents()

        guard let baseDate = dateFormatter.date(from: date) else {
            return (0, 0, false, false, false, "", 1, 0)
        }
        
        let start = dateFormatter.date(from: startDate) ?? Date()

        switch mode {
        case .countup:
            let startDateWithTime = applyTimeComponents(to: start, timeComponents: timeComponents)
            let startDay = calendar.startOfDay(for: startDateWithTime)
            let today = calendar.startOfDay(for: now)

            let diffDays = calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
            let isToday = diffDays == 0
            let weeksSince = Int(ceil(Double(max(0, diffDays)) / 7.0))
            let useWeeks = diffDays > 30

            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = timeOfDay == nil ? "dd/MM/yyyy" : "dd/MM/yyyy  HH:mm"
            let formattedDate = displayFormatter.string(from: startDateWithTime)

            return (
                daysLeft: max(0, diffDays),
                weeksLeft: weeksSince,
                useWeeks: useWeeks,
                isPast: false,
                isToday: isToday,
                formattedDate: formattedDate,
                totalDays: max(1, diffDays),
                daysCompleted: max(0, diffDays)
            )
        case .countdown:
            let resolvedEventDate = nextOccurrenceDate(from: baseDate, after: now, calendar: calendar, timeComponents: timeComponents)
            let eventDateWithTime = applyTimeComponents(to: resolvedEventDate, timeComponents: timeComponents)

            let today = calendar.startOfDay(for: now)
            let eventDay = calendar.startOfDay(for: eventDateWithTime)
            let startReferenceDate: Date = {
                if recurrence == .none {
                    return start
                }
                return previousOccurrenceDate(from: eventDateWithTime, calendar: calendar)
            }()
            let startDay = calendar.startOfDay(for: startReferenceDate)

            let diffDays = calendar.dateComponents([.day], from: today, to: eventDay).day ?? 0

            let totalDuration = eventDay.timeIntervalSince(startDay)
            let totalDays = max(1, Int(totalDuration / (24 * 60 * 60)))
            let completedDuration = today.timeIntervalSince(startDay)
            let daysCompleted = max(0, Int(completedDuration / (24 * 60 * 60)))

            let weeksLeft = Int(ceil(Double(abs(diffDays)) / 7.0))
            let useWeeks = abs(diffDays) > 30

            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = timeOfDay == nil ? "dd/MM/yyyy" : "dd/MM/yyyy  HH:mm"
            let formattedDate = displayFormatter.string(from: eventDateWithTime)

            return (
                daysLeft: diffDays,
                weeksLeft: weeksLeft,
                useWeeks: useWeeks,
                isPast: diffDays < 0,
                isToday: diffDays == 0,
                formattedDate: formattedDate,
                totalDays: totalDays,
                daysCompleted: daysCompleted
            )
        case .habit:
            return (
                daysLeft: currentStreak,
                weeksLeft: 0,
                useWeeks: false,
                isPast: false,
                isToday: isCheckedInToday,
                formattedDate: "Streak",
                totalDays: max(longestStreak, 1),
                daysCompleted: currentStreak
            )
        }
    }

    func nextRelevantDate(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeComponents = timeOfDayComponents()

        let baseDate = dateFormatter.date(from: date) ?? now

        switch mode {
        case .countup:
            return applyTimeComponents(to: dateFormatter.date(from: startDate) ?? baseDate, timeComponents: timeComponents)
        case .countdown:
            return applyTimeComponents(
                to: nextOccurrenceDate(from: baseDate, after: now, calendar: calendar, timeComponents: timeComponents),
                timeComponents: timeComponents
            )
        case .habit:
            return now
        }
    }

    private func timeOfDayComponents() -> DateComponents? {
        guard let timeOfDay else { return nil }
        let parts = timeOfDay.split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count >= 2 else { return nil }

        var comps = DateComponents()
        comps.hour = parts[0]
        comps.minute = parts[1]
        comps.second = 0
        return comps
    }

    private func applyTimeComponents(to date: Date, timeComponents: DateComponents?) -> Date {
        guard let timeComponents else { return date }
        return Calendar.current.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: date) ?? date
    }

    private func nextOccurrenceDate(from baseDate: Date, after now: Date, calendar: Calendar, timeComponents: DateComponents?) -> Date {
        guard recurrence != .none else { return baseDate }

        var candidate = applyTimeComponents(to: baseDate, timeComponents: timeComponents)
        let nowValue = now

        if candidate >= nowValue {
            return candidate
        }

        switch recurrence {
        case .weekly:
            while candidate < nowValue {
                candidate = calendar.date(byAdding: .day, value: 7, to: candidate) ?? candidate
            }
            return candidate
        case .monthly:
            while candidate < nowValue {
                candidate = addMonthsKeepingDay(candidate, by: 1, calendar: calendar)
            }
            return candidate
        case .yearly:
            while candidate < nowValue {
                candidate = addYearsKeepingDay(candidate, by: 1, calendar: calendar)
            }
            return candidate
        case .none:
            return candidate
        }
    }

    private func previousOccurrenceDate(from eventDate: Date, calendar: Calendar) -> Date {
        switch recurrence {
        case .weekly:
            return calendar.date(byAdding: .day, value: -7, to: eventDate) ?? eventDate
        case .monthly:
            return addMonthsKeepingDay(eventDate, by: -1, calendar: calendar)
        case .yearly:
            return addYearsKeepingDay(eventDate, by: -1, calendar: calendar)
        case .none:
            return eventDate
        }
    }

    private func addMonthsKeepingDay(_ date: Date, by value: Int, calendar: Calendar) -> Date {
        guard let shifted = calendar.date(byAdding: .month, value: value, to: date) else {
            return date
        }
        let originalComponents = calendar.dateComponents([.day, .hour, .minute], from: date)
        let targetYear = calendar.component(.year, from: shifted)
        let targetMonth = calendar.component(.month, from: shifted)
        let day = min(originalComponents.day ?? 1, daysInMonth(year: targetYear, month: targetMonth, calendar: calendar))
        return calendar.date(
            from: DateComponents(
                year: targetYear,
                month: targetMonth,
                day: day,
                hour: originalComponents.hour,
                minute: originalComponents.minute
            )
        ) ?? shifted
    }

    private func addYearsKeepingDay(_ date: Date, by value: Int, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let year = (comps.year ?? 1) + value
        let month = comps.month ?? 1
        let day = min(comps.day ?? 1, daysInMonth(year: year, month: month, calendar: calendar))
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: comps.hour, minute: comps.minute)) ?? date
    }

    private func daysInMonth(year: Int, month: Int, calendar: Calendar) -> Int {
        let comps = DateComponents(year: year, month: month)
        let date = calendar.date(from: comps) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }
    
    // MARK: - Streak Helpers
    
    private func dateFormatterString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func dateFormatterDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
    
    var currentStreak: Int {
        let sortedHistory = streakHistory.compactMap { dateFormatterDate($0) }.sorted(by: >)
        guard let _ = sortedHistory.first else { return 0 }
        
        var streak = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var checkDate = today
        
        // Check if checked in today
        if streakHistory.contains(dateFormatterString(today)) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        } else {
            // If not checked in today, check if yesterday was checked in
            // If yesterday wasn't checked in, streak is 0 (unless we allow skipped days, but for simple streak: break)
             let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
             if !streakHistory.contains(dateFormatterString(yesterday)) {
                 return 0
             }
             checkDate = yesterday
        }
        
        // Count backwards
        while streakHistory.contains(dateFormatterString(checkDate)) {
             // We already counted the first match above if it was today
             // This loop handles previous days
             // Wait, logic is flawed. Let's restart.
             // If today is checked in -> streak starts at 1, check yesterday.
             // If today NOT checked in -> streak starts at 0, check yesterday.
             break // Re-implementing correctly below
        }
        return calculateCurrentStreak()
    }
    
    // Correct implementation of currentStreak
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var checkDate = today
        
        // If checked in today, start counting from today
        if streakHistory.contains(dateFormatterString(today)) {
            streak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        } else {
             // If not today, check yesterday. If yesterday is checked in, streak continues from there.
             let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
             if streakHistory.contains(dateFormatterString(yesterday)) {
                  // Valid streak from yesterday
                  checkDate = yesterday
             } else {
                 return 0
             }
        }
        
        while streakHistory.contains(dateFormatterString(checkDate)) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return streak
    }
    
    var longestStreak: Int {
        let sortedDates = streakHistory.compactMap { dateFormatterDate($0) }.sorted()
        if sortedDates.isEmpty { return 0 }
        
        var maxStreak = 1
        var currentStreak = 1
        let calendar = Calendar.current
        
        for i in 1..<sortedDates.count {
            let prev = sortedDates[i-1]
            let curr = sortedDates[i]
            
            let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: prev), to: calendar.startOfDay(for: curr)).day ?? 0
            
            if diff == 1 {
                currentStreak += 1
            } else if diff > 1 {
                currentStreak = 1
            }
            maxStreak = max(maxStreak, currentStreak)
        }
        return maxStreak
    }
    
    var isCheckedInToday: Bool {
        streakHistory.contains(dateFormatterString(Date()))
    }
    
    var nextMilestone: Int {
        let current = currentStreak
        if current < 7 { return 7 }
        if current < 30 { return 30 }
        if current < 90 { return 90 }
        return ((current / 90) + 1) * 90
    }
    
    var successRate: Int {
        let calendar = Calendar.current
        guard let start = dateFormatterDate(startDate) else { return 0 }
        let now = Date()
        
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: now))
        let totalDays = max(1, (components.day ?? 0) + 1) // inclusive
        
        let checkedCount = streakHistory.count
        return min(100, Int((Double(checkedCount) / Double(totalDays)) * 100))
    }
}

struct TimeData {
    let dayProgress: Double
    let monthProgress: Double
    let yearProgress: Double
    let weekProgress: Double
    let quarterProgress: Double
    
    let hoursCompleted: Int
    let hoursLeft: Int
    let daysCompleted: Int
    let daysLeft: Int
    let weeksCompleted: Int
    let weeksLeft: Int
    let monthsCompleted: Int
    let monthsLeft: Int
    let quartersCompleted: Int
    let quartersLeft: Int
    
    let quarterNumber: Int
    let yearPercentLeft: Double
    
    let daysCrossedInWeek: Int
    let daysLeftInWeek: Int
}

class TimeCalculator {
    static func calculateTimeData(timeMode: TimeMode) -> TimeData {
        let calendar = Calendar.current
        let now = Date()
        
        // Day calculations
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        var hoursCompleted = 0
        var hoursLeft = 0
        var dayProgress = 0.0
        
        if timeMode == .nineToFive {
            // 9 AM to 5 PM (17:00)
            let startHour = 9
            let endHour = 17
            let totalHours = endHour - startHour // 8 hours
            
            if hour < startHour {
                hoursCompleted = 0
                hoursLeft = totalHours
                dayProgress = 0.0
            } else if hour >= endHour {
                hoursCompleted = totalHours
                hoursLeft = 0
                dayProgress = 1.0
            } else {
                hoursCompleted = hour - startHour
                hoursLeft = totalHours - hoursCompleted
                let minutesSinceStart = (hour - startHour) * 60 + minute
                dayProgress = Double(minutesSinceStart) / Double(totalHours * 60)
            }
        } else {
            // 24 Hour Mode
            hoursCompleted = hour
            hoursLeft = 24 - hour
            dayProgress = Double(hour * 60 + minute) / (24.0 * 60.0)
        }
        
        // Month calculations
        let dayOfMonth = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysCompleted = dayOfMonth - 1
        let daysLeft = daysInMonth - dayOfMonth
        let monthProgress = Double(dayOfMonth) / Double(daysInMonth)
        
        // Year calculations
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
        let yearProgress = Double(dayOfYear) / Double(daysInYear)
        let yearPercentLeft = (Double(daysInYear - dayOfYear) / Double(daysInYear)) * 100.0
        
        // Week calculations
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let weeksInYear = calendar.range(of: .weekOfYear, in: .year, for: now)?.count ?? 52
        let weeksCompleted = weekOfYear - 1
        let weeksLeft = weeksInYear - weekOfYear
        let weekProgress = Double(weekOfYear) / Double(weeksInYear)
        
        // Quarter calculations
        let month = calendar.component(.month, from: now)
        let quarterNumber = (month - 1) / 3 + 1
        let quarterStartMonth = (quarterNumber - 1) * 3 + 1
        let quarterEndMonth = quarterStartMonth + 2
        
        var daysInQuarter = 0
        for m in quarterStartMonth...quarterEndMonth {
            if let range = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: m)) ?? now) {
                daysInQuarter += range.count
            }
        }
        
        let quarterStartDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarterStartMonth, day: 1)) ?? now
        let daysSinceQuarterStart = calendar.dateComponents([.day], from: quarterStartDate, to: now).day ?? 0
        let quartersCompleted = quarterNumber - 1
        let quartersLeft = 4 - quarterNumber
        let quarterProgress = Double(daysSinceQuarterStart) / Double(daysInQuarter)
        
        // Months completed/left
        let monthsCompleted = month - 1
        let monthsLeft = 12 - month
        
        // Week calculations - days crossed and left in current week
        let weekday = calendar.component(.weekday, from: now)
        let daysCrossedInWeek = weekday - 1 // Sunday = 1, so subtract 1
        let daysLeftInWeek = 7 - weekday
        
        return TimeData(
            dayProgress: dayProgress,
            monthProgress: monthProgress,
            yearProgress: yearProgress,
            weekProgress: weekProgress,
            quarterProgress: quarterProgress,
            hoursCompleted: hoursCompleted,
            hoursLeft: hoursLeft,
            daysCompleted: daysCompleted,
            daysLeft: daysLeft,
            weeksCompleted: weeksCompleted,
            weeksLeft: weeksLeft,
            monthsCompleted: monthsCompleted,
            monthsLeft: monthsLeft,
            quartersCompleted: quartersCompleted,
            quartersLeft: quartersLeft,
            quarterNumber: quarterNumber,
            yearPercentLeft: yearPercentLeft,
            daysCrossedInWeek: daysCrossedInWeek,
            daysLeftInWeek: daysLeftInWeek
        )
    }
}

extension DisplayItem {
    func displayName(in customEvents: [CustomEvent], quarterNumber: Int) -> String {
        switch self {
        case .today: return "Today"
        case .month: return "This  Month"
        case .year: return "This  Year"
        case .week: return "This  Week"
        case .quarter: return "Q\(quarterNumber)"
        case .customEvent(let id):
            return customEvents.first(where: { $0.id == id })?.name ?? "Custom  Event"
        }
    }
}

func widgetHomeURL() -> URL? {
    URL(string: "com.prabhakaran.timeprogresstracker://home")
}

func widgetEventURL(_ id: String) -> URL? {
    let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
    return URL(string: "com.prabhakaran.timeprogresstracker://event/\(encodedID)")
}

func widgetURL(for item: DisplayItem) -> URL? {
    switch item {
    case .customEvent(let id):
        return widgetEventURL(id)
    default:
        return widgetHomeURL()
    }
}

// Font Helper for Widget
class WidgetFontHelper {
    static var registeredFonts: [String: String] = [:]
    
    static func getFontName(for customName: String) -> String {
        // First check if we registered it
        if let registeredName = registeredFonts[customName] {
            // Verify it's still valid (optional, but good for safety)
            if registeredName == "System" { return "System" }
            if UIFont(name: registeredName, size: 16) != nil {
                return registeredName
            }
        }
        
        // Try the custom name directly
        if UIFont(name: customName, size: 16) != nil {
            registeredFonts[customName] = customName
            return customName
        }
        
        // Try variations
        let variations = [
            customName.replacingOccurrences(of: "-", with: " "),
            customName.replacingOccurrences(of: "-Regular", with: ""),
            customName.replacingOccurrences(of: "-Bold", with: " Bold"),
            customName.replacingOccurrences(of: "-Light", with: " Light"),
        ]
        
        for variation in variations {
            if UIFont(name: variation, size: 16) != nil {
                registeredFonts[customName] = variation
                return variation
            }
        }
        
        // Check all fonts for partial match
        for family in UIFont.familyNames {
            if family.lowercased().contains("sabdevi") {
                let fonts = UIFont.fontNames(forFamilyName: family)
                // Try to match style
                if customName.contains("Bold") {
                    if let boldFont = fonts.first(where: { $0.lowercased().contains("bold") }) {
                        registeredFonts[customName] = boldFont
                        return boldFont
                    }
                } else if customName.contains("Light") {
                    if let lightFont = fonts.first(where: { $0.lowercased().contains("light") }) {
                        registeredFonts[customName] = lightFont
                        return lightFont
                    }
                } else if customName.contains("Regular") {
                    if let regularFont = fonts.first(where: { $0.lowercased().contains("regular") || !$0.lowercased().contains("bold") && !$0.lowercased().contains("light") }) {
                        registeredFonts[customName] = regularFont
                        return regularFont
                    }
                }
                
                // Fallback to first font in family
                if let firstFont = fonts.first {
                    registeredFonts[customName] = firstFont
                    return firstFont
                }
            }
        }
        
        // Final fallback
        registeredFonts[customName] = "System"
        return "System"
    }
}

extension Font {
    static func sabdeviRegular(size: CGFloat) -> Font {
        // Match main app's approach - simpler and more direct
        let fontName = WidgetFontHelper.getFontName(for: "Sabdevi-Regular")
        if fontName == "System" {
            return .system(size: size)
        }
        // Use the font name directly - SwiftUI will handle fallback if needed
        return .custom(fontName, size: size)
    }
    
    static func sabdeviBold(size: CGFloat) -> Font {
        let fontName = WidgetFontHelper.getFontName(for: "Sabdevi-Bold")
        if fontName == "System" {
            return .system(size: size, weight: .bold)
        }
        return .custom(fontName, size: size)
    }
    
    static func sabdeviLight(size: CGFloat) -> Font {
        let fontName = WidgetFontHelper.getFontName(for: "Sabdevi-Light")
        if fontName == "System" {
            return .system(size: size, weight: .light)
        }
        return .custom(fontName, size: size)
    }
}
