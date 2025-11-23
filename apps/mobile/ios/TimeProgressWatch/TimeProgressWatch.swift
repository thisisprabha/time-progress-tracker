//
//  TimeProgressWatch.swift
//  TimeProgressWatch
//
//  Apple Watch Complication with Curved Progress Style
//

import WidgetKit
import SwiftUI
import ClockKit

struct TimeProgressComplication: Widget {
    let kind: String = "TimeProgressComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("Time Progress")
        .description("Track your daily progress with a curved progress indicator.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: Date(), progress: 0.89, value: "89%", item: "today", perspective: "half-full", timeMode: "24h")
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> ()) {
        let entry = ComplicationEntry(date: Date(), progress: 0.89, value: "89%", item: "today", perspective: "half-full", timeMode: "24h")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> ()) {
        var entries: [ComplicationEntry] = []
        let currentDate = Date()
        
        // Load settings from App Group
        let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
        let perspective = sharedDefaults?.string(forKey: "userPerspective") ?? "half-full"
        let timeMode = sharedDefaults?.string(forKey: "timeMode") ?? "24h"
        let watchComplicationItem = sharedDefaults?.string(forKey: "watchComplicationItem") ?? "today"
        
        // Calculate progress based on selected item
        let calendar = Calendar.current
        let now = Date()
        let (progress, value): (Double, String)
        
        switch watchComplicationItem {
        case "today":
            let hour = calendar.component(.hour, from: now)
            if timeMode == "9-5" {
                let officeHour = max(0, min(8, hour - 9))
                let hoursLeft = 8 - officeHour
                if perspective == "half-full" {
                    progress = Double(officeHour) / 8.0
                    value = "\(officeHour)hrs"
                } else {
                    progress = Double(hoursLeft) / 8.0
                    value = "\(hoursLeft)hrs"
                }
            } else {
                if perspective == "half-full" {
                    progress = Double(hour) / 24.0
                    value = "\(hour)hrs"
                } else {
                    let hoursLeft = 24 - hour
                    progress = Double(hoursLeft) / 24.0
                    value = "\(hoursLeft)hrs"
                }
            }
            
        case "month":
            let dayOfMonth = calendar.component(.day, from: now)
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            let daysLeft = daysInMonth - dayOfMonth
            if perspective == "half-full" {
                progress = Double(dayOfMonth) / Double(daysInMonth)
                value = "\(dayOfMonth)d"
            } else {
                progress = Double(daysLeft) / Double(daysInMonth)
                value = "\(daysLeft)d"
            }
            
        case "year":
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
            let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
            let yearPercent = Int((Double(dayOfYear) / Double(daysInYear)) * 100)
            let yearPercentLeft = 100 - yearPercent
            if perspective == "half-full" {
                progress = Double(dayOfYear) / Double(daysInYear)
                value = "\(yearPercent)%"
            } else {
                progress = Double(daysInYear - dayOfYear) / Double(daysInYear)
                value = "\(yearPercentLeft)%"
            }
            
        case "week":
            let weekday = calendar.component(.weekday, from: now)
            let daysCrossed = weekday - 1
            let daysLeft = 7 - weekday
            if perspective == "half-full" {
                progress = Double(daysCrossed) / 7.0
                value = "\(daysCrossed)d"
            } else {
                progress = Double(daysLeft) / 7.0
                value = "\(daysLeft)d"
            }
            
        case "quarter":
            let month = calendar.component(.month, from: now)
            let quarterNumber = (month - 1) / 3 + 1
            let quarterStartMonth = (quarterNumber - 1) * 3 + 1
            let quarterStartDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarterStartMonth, day: 1)) ?? now
            let daysSinceQuarterStart = calendar.dateComponents([.day], from: quarterStartDate, to: now).day ?? 0
            let daysInQuarter = 91 // Approximate
            if perspective == "half-full" {
                progress = Double(daysSinceQuarterStart) / Double(daysInQuarter)
                value = "Q\(quarterNumber)"
            } else {
                progress = Double(daysInQuarter - daysSinceQuarterStart) / Double(daysInQuarter)
                value = "Q\(quarterNumber)"
            }
            
        case "custom":
            // Show first custom event
            var customEvents: [CustomEventData] = []
            if let eventsData = sharedDefaults?.data(forKey: "customEvents"),
               let events = try? JSONDecoder().decode([CustomEventData].self, from: eventsData) {
                customEvents = events
            }
            
            if let firstEvent = customEvents.first {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let eventDate = dateFormatter.date(from: firstEvent.date) {
                    let components = calendar.dateComponents([.day], from: now, to: eventDate)
                    let days = components.day ?? 0
                    if days > 0 {
                        let totalDays = days + 1
                        progress = 1.0 - (Double(days) / Double(totalDays))
                        value = "\(days)d"
                    } else {
                        progress = 1.0
                        value = "Today"
                    }
                } else {
                    progress = 0.5
                    value = "0%"
                }
            } else {
                progress = 0.0
                value = "0%"
            }
            
        default:
            progress = 0.5
            value = "50%"
        }
        
        let entry = ComplicationEntry(
            date: currentDate,
            progress: progress,
            value: value,
            item: watchComplicationItem,
            perspective: perspective,
            timeMode: timeMode
        )
        entries.append(entry)
        
        // Update every hour
        let nextUpdate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let progress: Double // 0.0 to 1.0
    let value: String
    let item: String
    let perspective: String
    let timeMode: String
}

struct CustomEventData: Codable {
    let id: String
    let name: String
    let date: String
}

struct ComplicationView: View {
    var entry: ComplicationProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularProgressView(entry: entry)
        case .accessoryRectangular:
            RectangularProgressView(entry: entry)
        case .accessoryInline:
            InlineProgressView(entry: entry)
        case .accessoryCorner:
            CornerProgressView(entry: entry)
        default:
            CircularProgressView(entry: entry)
        }
    }
}

// Circular Progress View (like the image - curved arc)
struct CircularProgressView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        ZStack {
            // Background circle (grey dashed)
            Circle()
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [2, 4]))
                .frame(width: 50, height: 50)
            
            // Progress arc (blue glowing)
            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.blue.opacity(0.5), radius: 4)
            
            // Percentage text
            Text(entry.value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// Rectangular Progress View
struct RectangularProgressView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(itemLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack {
                Text(entry.value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var itemLabel: String {
        switch entry.item {
        case "today": return "Today"
        case "week": return "This Week"
        case "month": return "This Month"
        case "quarter": return "Q4"
        case "year": return "This Year"
        case "custom": return "Custom"
        default: return "Progress"
        }
    }
}

// Inline Progress View
struct InlineProgressView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        Text("\(itemLabel): \(entry.value) (\(Int(entry.progress * 100))%)")
            .font(.system(size: 12, weight: .medium))
    }
    
    private var itemLabel: String {
        switch entry.item {
        case "today": return "Today"
        case "week": return "Week"
        case "month": return "Month"
        case "quarter": return "Q4"
        case "year": return "Year"
        case "custom": return "Custom"
        default: return "Progress"
        }
    }
}

// Corner Progress View
struct CornerProgressView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        ZStack {
            // Progress arc
            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(-90))
            
            Text(entry.value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview(as: .accessoryCircular) {
    TimeProgressComplication()
} timeline: {
    ComplicationEntry(date: Date(), progress: 0.89, value: "89%", item: "today", perspective: "half-full", timeMode: "24h")
}

#Preview(as: .accessoryRectangular) {
    TimeProgressComplication()
} timeline: {
    ComplicationEntry(date: Date(), progress: 0.65, value: "15d", item: "month", perspective: "half-full", timeMode: "24h")
}

