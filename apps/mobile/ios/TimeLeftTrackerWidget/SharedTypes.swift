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

struct CustomEvent: Identifiable, Codable {
    let id: String
    let name: String
    let date: String // ISO format: YYYY-MM-DD
    let startDate: String // ISO format: YYYY-MM-DD (Changed to non-optional to match main app)
    
    init(id: String = UUID().uuidString, name: String, date: String, startDate: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        
        if let start = startDate {
            self.startDate = start
        } else {
            // Default to today
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.startDate = dateFormatter.string(from: Date())
        }
    }
    
    func calculateProgress() -> (daysLeft: Int, weeksLeft: Int, useWeeks: Bool, isPast: Bool, isToday: Bool, formattedDate: String, totalDays: Int, daysCompleted: Int) {
        let now = Date()
        let calendar = Calendar.current
        
        // Parse date string (YYYY-MM-DD format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let eventDate = dateFormatter.date(from: date) else {
            return (0, 0, false, false, false, "", 1, 0)
        }
        
        // Parse start date
        let start = dateFormatter.date(from: startDate) ?? Date()
        
        // Set dates to start of day
        let today = calendar.startOfDay(for: now)
        let eventDay = calendar.startOfDay(for: eventDate)
        let startDay = calendar.startOfDay(for: start)
        
        let diffTime = eventDay.timeIntervalSince(today)
        let diffDays = Int(diffTime / (24 * 60 * 60))
        
        // Calculate total duration and completed days
        let totalDuration = eventDay.timeIntervalSince(startDay)
        let totalDays = max(1, Int(totalDuration / (24 * 60 * 60)))
        
        let completedDuration = today.timeIntervalSince(startDay)
        let daysCompleted = max(0, Int(completedDuration / (24 * 60 * 60)))
        
        // Calculate weeks for events > 30 days
        let weeksLeft = Int(ceil(Double(abs(diffDays)) / 7.0))
        let useWeeks = abs(diffDays) > 30
        
        // Format date as DD/MM/YYYY
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd/MM/yyyy"
        let formattedDate = displayFormatter.string(from: eventDate)
        
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

