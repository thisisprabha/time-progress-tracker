//
//  TimeProgressWidget.swift
//  TimeProgressWidget
//
//  Created by prabha karan on 12/10/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dayProgress: 0.5, monthProgress: 0.5, yearProgress: 0.5, perspective: "half-full", timeMode: "24h", selectedItems: ["today", "month", "year"], customEvents: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), dayProgress: 0.6, monthProgress: 0.4, yearProgress: 0.8, perspective: "half-full", timeMode: "24h", selectedItems: ["today", "month", "year"], customEvents: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline entry for the current time
        let currentDate = Date()
        
        // Load settings from UserDefaults (shared with main app via App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
        let perspective = sharedDefaults?.string(forKey: "userPerspective") ?? UserDefaults.standard.string(forKey: "userPerspective") ?? "half-full"
        let timeMode = sharedDefaults?.string(forKey: "timeMode") ?? UserDefaults.standard.string(forKey: "timeMode") ?? "24h"
        let selectedItems = sharedDefaults?.array(forKey: "selectedDisplayItems") as? [String] ?? ["today", "month", "year"]
        
        // Load custom events
        var customEvents: [CustomEventData] = []
        if let eventsData = sharedDefaults?.data(forKey: "customEvents") ?? UserDefaults.standard.data(forKey: "customEvents"),
           let events = try? JSONDecoder().decode([CustomEventData].self, from: eventsData) {
            customEvents = events
        }
        
        // Calculate actual time progress
        let calendar = Calendar.current
        let now = Date()
        
        // Day progress (0-24 hours)
        let hour = calendar.component(.hour, from: now)
        let dayProgress = Double(hour) / 24.0
        
        // Month progress (current day / total days in month)
        let dayOfMonth = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let monthProgress = Double(dayOfMonth) / Double(daysInMonth)
        
        // Year progress (current day of year / total days in year)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
        let yearProgress = Double(dayOfYear) / Double(daysInYear)
        
        // Create entry with calculated progress
        let entry = SimpleEntry(
            date: currentDate,
            dayProgress: dayProgress,
            monthProgress: monthProgress,
            yearProgress: yearProgress,
            perspective: perspective,
            timeMode: timeMode,
            selectedItems: selectedItems,
            customEvents: customEvents
        )
        
        entries.append(entry)
        
        // Create timeline - update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dayProgress: Double
    let monthProgress: Double
    let yearProgress: Double
    let perspective: String
    let timeMode: String
    let selectedItems: [String]
    let customEvents: [CustomEventData]
    
    init(date: Date, dayProgress: Double = 0.5, monthProgress: Double = 0.5, yearProgress: Double = 0.5, perspective: String = "half-full", timeMode: String = "24h", selectedItems: [String] = ["today", "month", "year"], customEvents: [CustomEventData] = []) {
        self.date = date
        self.dayProgress = dayProgress
        self.monthProgress = monthProgress
        self.yearProgress = yearProgress
        self.perspective = perspective
        self.timeMode = timeMode
        self.selectedItems = selectedItems
        self.customEvents = customEvents
    }
}

struct CustomEventData: Codable {
    let id: String
    let name: String
    let date: String // ISO format: YYYY-MM-DD
}

struct TimeProgressWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    init(entry: Provider.Entry) {
        self.entry = entry
        // Register fonts when widget loads
        WidgetFontHelper.registerFonts()
    }

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    // Helper to get font - using Sabdevi fonts
    private func customFont(_ name: String, size: CGFloat) -> Font {
        if name.contains("Bold") {
            return .widgetSabdeviBold(size: size * 1.2)
        } else {
            return .widgetSabdeviRegular(size: size * 1.2)
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                Text(hoursText.value)
                    .font(customFont("Sabdevi-Bold", size: 12.8))
                    .foregroundColor(.white)
                Text(hoursText.suffix)
                    .font(customFont("Sabdevi-Regular", size: 12.8))
                    .foregroundColor(.white)
            }
            
            Text("For today")
                .font(customFont("Sabdevi-Regular", size: 9.6))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(Color.black, for: .widget)
    }
    
    private var hoursText: (value: String, suffix: String) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        
        if entry.timeMode == "9-5" {
            // 9-5 office hours (8 hours total)
            let officeHour = max(0, min(8, hour - 9))
            let hoursLeft = 8 - officeHour
            
            if entry.perspective == "half-full" {
                return ("\(officeHour)hrs", " gone")
            } else {
                return ("\(hoursLeft)hrs", " left")
            }
        } else {
            // 24-hour format
            let hoursLeft = 24 - hour
            
            if entry.perspective == "half-full" {
                return ("\(hour)hrs", " gone")
            } else {
                return ("\(hoursLeft)hrs", " left")
            }
        }
    }
}

// Widget Row View - shows label on left, value on right (for Medium widget - no tally marks)
struct WidgetRowView: View {
    let item: String
    let entry: SimpleEntry
    let font: (String, CGFloat) -> Font
    var showTallyMarks: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(itemLabel)
                    .font(font("Sabdevi-Regular", showTallyMarks ? 12.8 : 11.2))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Text(itemValue.value)
                        .font(font("Sabdevi-Bold", showTallyMarks ? 14.4 : 12.8))
                        .foregroundColor(.white)
                    Text(itemValue.suffix)
                        .font(font("Sabdevi-Regular", showTallyMarks ? 14.4 : 12.8))
                        .foregroundColor(.white)
                }
            }
            
            // Show tally marks only for large widget - aligned left
            if showTallyMarks {
                TallyMarksView(total: totalUnits, completed: completedUnits)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var itemLabel: String {
        switch item {
        case "today": return "Today"
        case "week": return "This Week"
        case "month": return "This Month"
        case "quarter": return "Q\(quarterNumber)"
        case "year": return "This Year"
        case "custom":
            // Show custom event name if available
            if let firstEvent = entry.customEvents.first {
                return firstEvent.name
            }
            return "Custom Events"
        default: return item
        }
    }
    
    private var itemValue: (value: String, suffix: String) {
        let calendar = Calendar.current
        let now = entry.date
        
        switch item {
        case "today":
            let hour = calendar.component(.hour, from: now)
            if entry.timeMode == "9-5" {
                let officeHour = max(0, min(8, hour - 9))
                let hoursLeft = 8 - officeHour
                if entry.perspective == "half-full" {
                    return ("\(officeHour)hrs", " gone")
                } else {
                    return ("\(hoursLeft)hrs", " left")
                }
            } else {
                let hoursLeft = 24 - hour
                if entry.perspective == "half-full" {
                    return ("\(hour)hrs", " gone")
                } else {
                    return ("\(hoursLeft)hrs", " left")
                }
            }
            
        case "week":
            let weekday = calendar.component(.weekday, from: now)
            let daysCrossed = weekday - 1
            let daysLeft = 7 - weekday
            if entry.perspective == "half-full" {
                return ("\(daysCrossed)d", " gone")
            } else {
                    return ("\(daysLeft)d", " left")
            }
            
        case "month":
            let dayOfMonth = calendar.component(.day, from: now)
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            let daysLeft = daysInMonth - dayOfMonth
            let daysCrossed = dayOfMonth - 1
            if entry.perspective == "half-full" {
                return ("\(daysCrossed)d", " gone")
            } else {
                    return ("\(daysLeft)d", " left")
            }
            
        case "quarter":
            // Simplified quarter calculation
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            let quarterStartDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarterStartMonth, day: 1)) ?? now
            let daysSinceQuarterStart = calendar.dateComponents([.day], from: quarterStartDate, to: now).day ?? 0
            let weeksCompleted = daysSinceQuarterStart / 7
            let weeksLeft = 13 - weeksCompleted
            if entry.perspective == "half-full" {
                return ("\(weeksCompleted)wk", " gone")
            } else {
                    return ("\(weeksLeft)wk", " left")
            }
            
        case "year":
            let yearPercent = Int(entry.yearProgress * 100)
            let yearPercentLeft = 100 - yearPercent
            if entry.perspective == "half-full" {
                return ("\(yearPercent)%", " done")
            } else {
                return ("\(yearPercentLeft)%", " left")
            }
            
        case "custom":
            // Show first custom event
            if let firstEvent = entry.customEvents.first {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let eventDate = dateFormatter.date(from: firstEvent.date) {
                    let components = calendar.dateComponents([.day], from: now, to: eventDate)
                    let days = components.day ?? 0
                    if days == 0 {
                        return ("Today!", "")
                    } else if days > 0 {
                        return ("\(days)d", " left")
                    } else {
                        return ("\(abs(days))d", " ago")
                    }
                }
            }
            return ("", "")
            
        default:
            return ("", "")
        }
    }
    
    private var totalUnits: Int {
        let calendar = Calendar.current
        let now = entry.date
        
        switch item {
        case "today":
            return 24
        case "week":
            return 7
        case "month":
            return calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        case "quarter":
            return 13
        case "year":
            return 12
        case "custom":
            if let firstEvent = entry.customEvents.first {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let eventDate = dateFormatter.date(from: firstEvent.date) {
                    let components = calendar.dateComponents([.day], from: now, to: eventDate)
                    let days = components.day ?? 0
                    if days > 0 {
                        return days + 1
                    } else if days < 0 {
                        return abs(days) + 1
                    } else {
                        return 1
                    }
                }
            }
            return 1
        default:
            return 1
        }
    }
    
    private var completedUnits: Int {
        let calendar = Calendar.current
        let now = entry.date
        
        switch item {
        case "today":
            return calendar.component(.hour, from: now)
        case "week":
            return calendar.component(.weekday, from: now) - 1
        case "month":
            return calendar.component(.day, from: now) - 1
        case "quarter":
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            let quarterStartDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarterStartMonth, day: 1)) ?? now
            let daysSinceQuarterStart = calendar.dateComponents([.day], from: quarterStartDate, to: now).day ?? 0
            return daysSinceQuarterStart / 7
        case "year":
            return Int(entry.yearProgress * 12)
        case "custom":
            if let firstEvent = entry.customEvents.first {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let eventDate = dateFormatter.date(from: firstEvent.date) {
                    let components = calendar.dateComponents([.day], from: now, to: eventDate)
                    let days = components.day ?? 0
                    if days > 0 {
                        return 0
                    } else if days < 0 {
                        return abs(days) + 1
                    } else {
                        return 1
                    }
                }
            }
            return 0
        default:
            return 0
        }
    }
    
    private var quarterNumber: Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: entry.date)
        return (month - 1) / 3 + 1
    }
}

// Tally Marks View
struct TallyMarksView: View {
    let total: Int
    let completed: Int
    
    var body: some View {
        // Render tally marks in rows (like app) - aligned left
        let itemsPerRow = 15 // Approximate items per row
        let rows = (total + itemsPerRow - 1) / itemsPerRow
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    let startIndex = row * itemsPerRow
                    let endIndex = min(startIndex + itemsPerRow, total)
                    
                    ForEach(startIndex..<endIndex, id: \.self) { index in
                        WidgetTallyMarkView(isCompleted: index < completed)
                    }
                }
            }
        }
    }
}

struct WidgetTallyMarkView: View {
    let isCompleted: Bool
    
    var body: some View {
        // Ancient tally mark style: vertical line with diagonal cross when completed - same size as app
        ZStack {
            // Vertical line (always shown) - white on black background
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 2, height: 20)
            
            // Diagonal cross line (only when completed) - white on black background
            if isCompleted {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 14, height: 2)
                    .rotationEffect(.degrees(45))
            }
        }
        .frame(width: 16, height: 20)
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    // Helper to get font - using Sabdevi fonts
    private func customFont(_ name: String, size: CGFloat) -> Font {
        if name.contains("Bold") {
            return .widgetSabdeviBold(size: size * 1.2)
        } else {
            return .widgetSabdeviRegular(size: size * 1.2)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Show all selected items (up to 3) - values and labels only, no tally marks
            ForEach(Array(entry.selectedItems.prefix(3)), id: \.self) { item in
                if item == "custom" && !entry.customEvents.isEmpty {
                    // Show custom events
                    ForEach(Array(entry.customEvents.prefix(3)), id: \.id) { event in
                        WidgetRowView(item: "custom", entry: entry, font: customFont, showTallyMarks: false)
                    }
                } else {
                    WidgetRowView(item: item, entry: entry, font: customFont, showTallyMarks: false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.black, for: .widget)
        .padding(.horizontal, 8)
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    // Helper to get font - using Sabdevi fonts
    private func customFont(_ name: String, size: CGFloat) -> Font {
        if name.contains("Bold") {
            return .widgetSabdeviBold(size: size * 1.2)
        } else {
            return .widgetSabdeviRegular(size: size * 1.2)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Show all selected items (up to 3) - with tally marks + label + values
            ForEach(Array(entry.selectedItems.prefix(3)), id: \.self) { item in
                if item == "custom" && !entry.customEvents.isEmpty {
                    // Show custom events
                    ForEach(Array(entry.customEvents.prefix(3)), id: \.id) { event in
                        WidgetRowView(item: "custom", entry: entry, font: customFont, showTallyMarks: true)
                    }
                } else {
                    WidgetRowView(item: item, entry: entry, font: customFont, showTallyMarks: true)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.black, for: .widget)
        .padding(.horizontal, 12)
    }
}

struct TimeProgressWidget: Widget {
    let kind: String = "TimeProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimeProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Time Progress")
        .description("Track your daily, monthly, and yearly progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    TimeProgressWidget()
} timeline: {
    SimpleEntry(date: Date(), perspective: "half-full", timeMode: "24h", selectedItems: ["today"], customEvents: [])
}

#Preview(as: .systemMedium) {
    TimeProgressWidget()
} timeline: {
    SimpleEntry(date: Date(), perspective: "half-full", timeMode: "24h", selectedItems: ["today", "month", "year"], customEvents: [])
}

#Preview(as: .systemLarge) {
    TimeProgressWidget()
} timeline: {
    SimpleEntry(date: Date(), perspective: "half-full", timeMode: "24h", selectedItems: ["today", "month", "year"], customEvents: [])
}
