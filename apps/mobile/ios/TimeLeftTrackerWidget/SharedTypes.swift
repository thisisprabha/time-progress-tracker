//
//  SharedTypes.swift
//  TimeLeftTrackerWidget
//
//  Shared types for widget and main app
//

import Foundation

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
        let hoursCompleted = hour
        let hoursLeft = 24 - hour
        let dayProgress = Double(hour * 60 + minute) / (24.0 * 60.0)
        
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
        case .month: return "This Month"
        case .year: return "This Year"
        case .week: return "This Week"
        case .quarter: return "Q\(quarterNumber)"
        case .customEvent(let id):
            return customEvents.first(where: { $0.id == id })?.name ?? "Custom Event"
        }
    }
}

