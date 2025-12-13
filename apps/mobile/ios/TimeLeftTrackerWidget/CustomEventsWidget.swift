//
//  CustomEventsWidget.swift
//  TimeLeftTrackerWidget
//
//  Dedicated Widget for Custom Events
//

import WidgetKit
import SwiftUI

struct CustomEventsProvider: TimelineProvider {
    func placeholder(in context: Context) -> CustomEventsEntry {
        CustomEventsEntry(date: Date(), customEvents: [
            CustomEvent(name: "Birthday", date: "2024-12-25"),
            CustomEvent(name: "Trip", date: "2025-01-01")
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (CustomEventsEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CustomEventsEntry>) -> ()) {
        let entry = loadEntry()
        
        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadEntry() -> CustomEventsEntry {
        // Load from App Group
        let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
        
        // Load custom events
        var customEvents: [CustomEvent] = []
        if let eventsData = sharedDefaults?.data(forKey: "customEvents"),
           let events = try? JSONDecoder().decode([CustomEvent].self, from: eventsData) {
            customEvents = events
        }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Filter out past events
        var upcomingEvents = customEvents.filter { event in
            if let date = dateFormatter.date(from: event.date),
               calendar.startOfDay(for: date) >= startOfToday {
                return true
            }
            return false
        }
        
        // Sort by nearest date
        upcomingEvents.sort { event1, event2 in
            let date1 = dateFormatter.date(from: event1.date) ?? Date.distantFuture
            let date2 = dateFormatter.date(from: event2.date) ?? Date.distantFuture
            return date1 < date2
        }
        
        // Return entries
        return CustomEventsEntry(
            date: now,
            customEvents: upcomingEvents
        )
    }
}

struct CustomEventsEntry: TimelineEntry {
    let date: Date
    let customEvents: [CustomEvent]
}

struct CustomEventsWidgetEntryView : View {
    var entry: CustomEventsProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Upcoming Events")
                .font(.sabdeviBold(size: 16))
                .foregroundColor(.primary)
                .padding(.bottom, 12)
            
            if entry.customEvents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No upcoming events")
                        .font(.sabdeviRegular(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Add events in the app")
                        .font(.sabdeviRegular(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            } else {
                // Show up to 5 events
                ForEach(Array(entry.customEvents.prefix(5).enumerated()), id: \.element.id) { index, event in
                    CustomEventRow(event: event)
                        .padding(.vertical, 8)
                    
                    if index < min(entry.customEvents.count, 5) - 1 {
                        Divider()
                            .background(Color.secondary.opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CustomEventRow: View {
    let event: CustomEvent
    
    var body: some View {
        let (daysLeft, _, _, isPast, isToday, formattedDate, _, _) = event.calculateProgress()
        
        HStack(alignment: .firstTextBaseline, spacing: 4) {
             // Name
            Text(event.name)
                .font(.sabdeviRegular(size: 14))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if isToday {
               Text("is Today!")
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(.red)
            } else if isPast {
               Text("passed")
                    .font(.sabdeviRegular(size: 14))
                    .foregroundColor(.secondary)
            } else {
               // "in" regular, number bold, "days" regular
               Text("in ")
                    .font(.sabdeviRegular(size: 14))
                    .foregroundColor(.primary)
               + Text("\(daysLeft)")
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(daysLeft <= 5 ? .red : .primary)
               + Text(" days")
                    .font(.sabdeviRegular(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text("(\(formattedDate))")
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .layoutPriority(-1) // allow date to truncate if needed
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CustomEventsWidget: Widget {
    let kind: String = "CustomEventsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomEventsProvider()) { entry in
            CustomEventsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Custom Events")
        .description("View your upcoming events.")
        .supportedFamilies([.systemLarge])
    }
    
    init() {
        // Register fonts just in case
        registerFontsForWidget()
    }
}
