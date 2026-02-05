//
//  CustomEvent.swift
//  TimeProgressTracker
//
//  Custom Event Model
//

import Foundation

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

struct EventReminder: Identifiable, Codable, Hashable {
    let id: String
    let offsetMinutes: Int

    init(id: String = UUID().uuidString, offsetMinutes: Int) {
        self.id = id
        self.offsetMinutes = max(0, offsetMinutes)
    }

    var displayName: String {
        switch offsetMinutes {
        case 0:
            return "At time"
        case 60:
            return "1 hour before"
        case 24 * 60:
            return "1 day before"
        case 7 * 24 * 60:
            return "1 week before"
        default:
            if offsetMinutes >= 60 * 24 {
                let days = Int(round(Double(offsetMinutes) / Double(60 * 24)))
                return "\(days) days before"
            }
            let hours = Int(round(Double(offsetMinutes) / 60.0))
            return "\(hours) hours before"
        }
    }
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
    let reminders: [EventReminder]
    var streakHistory: Set<String> // ISO dates "YYYY-MM-DD"
    let goalCount: Int? // For Habits, default 90

    init(
        id: String = UUID().uuidString,
        name: String,
        date: String,
        startDate: String? = nil,
        category: EventCategory = .personal,
        mode: EventMode = .countdown,
        recurrence: EventRecurrence = .none,
        timeOfDay: String? = nil,
        reminders: [EventReminder] = [],
        streakHistory: Set<String> = [],
        goalCount: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.category = category
        self.mode = mode
        self.recurrence = recurrence
        self.timeOfDay = timeOfDay
        self.reminders = reminders
        self.streakHistory = streakHistory
        self.goalCount = goalCount

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
        case reminders
        case streakHistory
        case goalCount
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
        reminders = try container.decodeIfPresent([EventReminder].self, forKey: .reminders) ?? []
        streakHistory = try container.decodeIfPresent(Set<String>.self, forKey: .streakHistory) ?? []
        goalCount = try container.decodeIfPresent(Int.self, forKey: .goalCount)
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
        try container.encode(reminders, forKey: .reminders)
        try container.encode(streakHistory, forKey: .streakHistory)
        try container.encodeIfPresent(goalCount, forKey: .goalCount)
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
            // For habits:
            // daysLeft -> currentStreak
            // isToday -> isCheckedInToday
            // totalDays -> longestStreak (for progress bar if needed, or 100 for percentage)
            // daysCompleted -> currentStreak
            return (
                daysLeft: currentStreak,
                weeksLeft: 0,
                useWeeks: false,
                isPast: false,
                isToday: isCheckedInToday,
                formattedDate: "Streak",
                totalDays: goalCount ?? 90,
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
            return now // Habits are relevant "now"
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

    func upcomingOccurrences(from now: Date = Date(), limit: Int = 1) -> [Date] {
        guard mode == .countdown else { return [] }
        guard limit > 0 else { return [] }

        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeComponents = timeOfDayComponents()

        guard let baseDate = dateFormatter.date(from: date) else {
            return []
        }

        var dates: [Date] = []
        var nextDate = nextOccurrenceDate(from: baseDate, after: now, calendar: calendar, timeComponents: timeComponents)
        nextDate = applyTimeComponents(to: nextDate, timeComponents: timeComponents)

        for _ in 0..<limit {
            dates.append(nextDate)
            guard recurrence != .none else { break }

            switch recurrence {
            case .weekly:
                nextDate = calendar.date(byAdding: .day, value: 7, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = addMonthsKeepingDay(nextDate, by: 1, calendar: calendar)
            case .yearly:
                nextDate = addYearsKeepingDay(nextDate, by: 1, calendar: calendar)
            case .none:
                break
            }
        }

        return dates
    }
    
    // MARK: - Streak Logic
    
    var currentStreak: Int {

        var streak = 0
        let calendar = Calendar.current
        let today = Date()
        let todayString = dateFormatterString(today)
        
        // If empty, 0
        if streakHistory.isEmpty { return 0 }
        
        // Check if today is checked in
        var checkingDate = today
        if !streakHistory.contains(todayString) {
            // If not today, check yesterday. If yesterday missing, streak is 0.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  streakHistory.contains(dateFormatterString(yesterday)) else {
                return 0
            }
            // Start counting from yesterday
            checkingDate = yesterday
        }
        
        // Count backwards
        while streakHistory.contains(dateFormatterString(checkingDate)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkingDate) else { break }
            checkingDate = prev
        }
        
        return streak
    }
    
    var longestStreak: Int {
        if streakHistory.isEmpty { return 0 }
        
        let sortedDates = streakHistory.compactMap { dateFormatterDate($0) }.sorted()
        if sortedDates.isEmpty { return 0 }
        
        var maxStreak = 1
        var currentSequence = 1
        let calendar = Calendar.current
        
        for i in 1..<sortedDates.count {
            let prev = sortedDates[i-1]
            let curr = sortedDates[i]
            
            if let diff = calendar.dateComponents([.day], from: prev, to: curr).day, diff == 1 {
                currentSequence += 1
            } else {
                 if let diff = calendar.dateComponents([.day], from: prev, to: curr).day, diff == 0 {
                     // Same day (duplicate), ignore
                 } else {
                     maxStreak = max(maxStreak, currentSequence)
                     currentSequence = 1
                 }
            }
        }
        maxStreak = max(maxStreak, currentSequence)
        
        return maxStreak
    }
    
    var isCheckedInToday: Bool {
        streakHistory.contains(dateFormatterString(Date()))
    }
    

    
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
    
    mutating func checkIn() {
        let today = dateFormatterString(Date())
        streakHistory.insert(today)
    }
    
    mutating func toggleCheckIn() {
        let today = dateFormatterString(Date())
        if streakHistory.contains(today) {
            streakHistory.remove(today)
        } else {
            streakHistory.insert(today)
        }
    }
    
    var nextMilestone: Int {
        if let goal = goalCount { return goal }
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


extension EventCategory {
    var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .work: return "Work"
        case .family: return "Family"
        case .custom: return "Custom"
        }
    }
}

extension EventMode {
    var displayName: String {
        switch self {
        case .countdown: return "Countdown"
        case .countup: return "Count up"
        case .habit: return "Habit"
        }
    }
}

extension EventRecurrence {
    var displayName: String {
        switch self {
        case .none: return "One-time"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

extension CustomEvent {
    func summaryText(now: Date = Date()) -> String {
        let modeText = mode.displayName
        let categoryText = category.displayName
        let dateText: String

        if mode == .countup {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let start = dateFormatter.date(from: startDate) ?? now
            dateText = "Since \(formattedDisplayDate(start))"
        } else if mode == .habit {
             let goal = goalCount ?? 90
             dateText = "Streak: \(currentStreak)/\(goal)"
        } else {
            let nextDate = nextRelevantDate(from: now)
            if recurrence == .none {
                dateText = "On \(formattedDisplayDate(nextDate))"
            } else {
                dateText = "Repeats \(recurrence.displayName)"
            }
        }

        if mode == .countdown, recurrence != .none {
            let nextText = "Next \(formattedDisplayDate(nextRelevantDate(from: now)))"
            return [modeText, categoryText, dateText, nextText].joined(separator: " • ")
        }

        return [modeText, categoryText, dateText].joined(separator: " • ")
    }

    private func formattedDisplayDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = timeOfDay == nil ? "dd/MM/yyyy" : "dd/MM/yyyy  HH:mm"
        return displayFormatter.string(from: date)
    }
}
