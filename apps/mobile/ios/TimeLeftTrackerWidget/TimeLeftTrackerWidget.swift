//
//  TimeLeftTrackerWidget.swift
//  TimeLeftTrackerWidget
//
//  Time Progress Widget
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour), perspective: .halfFull, timeMode: .twentyFourHour, selectedItems: [.today, .month, .year], customEvents: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("✅ [Widget] getTimeline called")
        let entry = loadEntry()
        print("✅ [Widget] Loaded entry with \(entry.selectedItems.count) selected items")
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadEntry() -> SimpleEntry {
        // Load from App Group
        let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
        
        let perspective = Perspective(rawValue: sharedDefaults?.string(forKey: "userPerspective") ?? "half-full") ?? .halfFull
        let timeMode = TimeMode(rawValue: sharedDefaults?.string(forKey: "timeMode") ?? "24h") ?? .twentyFourHour
        
        // Load selected items
        var selectedItems: [DisplayItem] = [.today, .month, .year]
        if let itemsArray = sharedDefaults?.array(forKey: "selectedDisplayItems") as? [String] {
            selectedItems = itemsArray.compactMap { DisplayItem(rawValue: $0) }
            if selectedItems.count < 3 {
                selectedItems = [.today, .month, .year]
            }
        }
        
        // Load custom events
        var customEvents: [CustomEvent] = []
        if let eventsData = sharedDefaults?.data(forKey: "customEvents"),
           let events = try? JSONDecoder().decode([CustomEvent].self, from: eventsData) {
            customEvents = events
        }
        
        let timeData = TimeCalculator.calculateTimeData(timeMode: timeMode)
        
        return SimpleEntry(
            date: Date(),
            timeData: timeData,
            perspective: perspective,
            timeMode: timeMode,
            selectedItems: selectedItems,
            customEvents: customEvents
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let timeData: TimeData
    let perspective: Perspective
    let timeMode: TimeMode
    let selectedItems: [DisplayItem]
    let customEvents: [CustomEvent]
}

struct TimeLeftTrackerWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let firstItem = entry.selectedItems.first {
                ProgressRow(item: firstItem, entry: entry)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Show all 3 configured items in medium widget
            ForEach(Array(entry.selectedItems.prefix(3).enumerated()), id: \.element) { _, item in
                ProgressRow(item: item, entry: entry)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(entry.selectedItems.prefix(3).enumerated()), id: \.element) { _, item in
                ProgressRow(item: item, entry: entry)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ProgressRow: View {
    let item: DisplayItem
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.displayName(in: entry.customEvents, quarterNumber: entry.timeData.quarterNumber))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
            
            HStack {
                Text(valueText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(unitText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var valueText: String {
        let (value, total) = getValueAndTotal()
        return "\(value)"
    }
    
    private var unitText: String {
        let (value, total) = getValueAndTotal()
        return entry.perspective == .halfFull ? "/\(total) done" : "/\(total) left"
    }
    
    private var progress: Double {
        let (value, total) = getValueAndTotal()
        return Double(value) / Double(total)
    }
    
    private var progressColor: Color {
        let prog = progress
        if entry.perspective == .halfEmpty {
            return prog > 0.75 ? .red : prog > 0.5 ? .orange : .green
        } else {
            return prog > 0.75 ? .green : prog > 0.5 ? .orange : .red
        }
    }
    
    private func getValueAndTotal() -> (Int, Int) {
        switch item {
        case .today:
            if entry.perspective == .halfFull {
                return (entry.timeData.hoursCompleted, 24)
            } else {
                return (entry.timeData.hoursLeft, 24)
            }
        case .month:
            if entry.perspective == .halfFull {
                return (entry.timeData.daysCompleted, entry.timeData.daysCompleted + entry.timeData.daysLeft)
            } else {
                return (entry.timeData.daysLeft, entry.timeData.daysCompleted + entry.timeData.daysLeft)
            }
        case .year:
            if entry.perspective == .halfFull {
                return (entry.timeData.monthsCompleted, 12)
            } else {
                return (entry.timeData.monthsLeft, 12)
            }
        case .week:
            if entry.perspective == .halfFull {
                return (entry.timeData.daysCrossedInWeek, 7)
            } else {
                return (entry.timeData.daysLeftInWeek, 7)
            }
        case .quarter:
            if entry.perspective == .halfFull {
                return (entry.timeData.quartersCompleted, 4)
            } else {
                return (entry.timeData.quartersLeft, 4)
            }
        case .customEvent(let id):
            if let event = entry.customEvents.first(where: { $0.id == id }) {
                let calendar = Calendar.current
                let now = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                guard let eventDate = dateFormatter.date(from: event.date) else {
                    return (0, 1)
                }
                let today = calendar.startOfDay(for: now)
                let eventDay = calendar.startOfDay(for: eventDate)
                let daysDiff = calendar.dateComponents([.day], from: today, to: eventDay).day ?? 0
                
                if entry.perspective == .halfFull {
                    return (max(0, -daysDiff), 365)
                } else {
                    return (max(0, daysDiff), 365)
                }
            }
            return (0, 1)
        }
    }
    
    private func displayName(in entry: SimpleEntry) -> String {
        switch item {
        case .today: return "Today"
        case .month: return "This Month"
        case .year: return "This Year"
        case .week: return "This Week"
        case .quarter: return "Q\(entry.timeData.quarterNumber)"
        case .customEvent(let id):
            return entry.customEvents.first(where: { $0.id == id })?.name ?? "Custom Event"
        }
    }
}

struct TimeLeftTrackerWidget: Widget {
    let kind: String = "TimeLeftTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimeLeftTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Time left Tracker")
        .description("Track your time progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
    
    init() {
        print("✅ [Widget] TimeLeftTrackerWidget initialized")
        print("✅ [Widget] Widget kind: \(kind)")
        print("✅ [Widget] Widget display name: Time left Tracker")
    }
}

#Preview(as: .systemSmall) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(date: .now, timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour), perspective: .halfFull, timeMode: .twentyFourHour, selectedItems: [.today, .month, .year], customEvents: [])
}

#Preview(as: .systemMedium) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(date: .now, timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour), perspective: .halfFull, timeMode: .twentyFourHour, selectedItems: [.today, .month, .year], customEvents: [])
}

#Preview(as: .systemLarge) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(date: .now, timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour), perspective: .halfFull, timeMode: .twentyFourHour, selectedItems: [.today, .month, .year], customEvents: [])
}
