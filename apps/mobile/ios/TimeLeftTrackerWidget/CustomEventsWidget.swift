//
//  CustomEventsWidget.swift
//  TimeLeftTrackerWidget
//
//  Split Widgets for Countdown, Count Up, and Habits
//

import WidgetKit
import SwiftUI

// MARK: - Providers

struct CustomEventsProvider: TimelineProvider {
    let modeFilter: EventMode?
    let title: String

    init(modeFilter: EventMode? = nil, title: String = "My Events") {
        self.modeFilter = modeFilter
        self.title = title
    }

    func placeholder(in context: Context) -> CustomEventsEntry {
        CustomEventsEntry(
            date: Date(),
            customEvents: [
                CustomEvent(name: "Sample", date: "2026-12-25")
            ],
            widgetStyle: .classic,
            title: title
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CustomEventsEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CustomEventsEntry>) -> ()) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadEntry() -> CustomEventsEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
        var customEvents: [CustomEvent] = []
        if let eventsData = sharedDefaults?.data(forKey: "customEvents"),
           let events = try? JSONDecoder().decode([CustomEvent].self, from: eventsData) {
            customEvents = events
        }

        let widgetStyle = WidgetStyle(rawValue: sharedDefaults?.string(forKey: "widgetStyle") ?? "classic") ?? .classic
        let now = Date()

        // Filter by mode if specified
        var filteredEvents = customEvents
        if let filter = modeFilter {
            filteredEvents = customEvents.filter { $0.mode == filter }
        }

        // Sort by relevance
        filteredEvents.sort { event1, event2 in
            if event1.mode != event2.mode {
                return event1.mode == .countdown
            }
            if event1.mode == .countup && event2.mode == .countup {
                return event1.nextRelevantDate(from: now) > event2.nextRelevantDate(from: now)
            }
            return event1.nextRelevantDate(from: now) < event2.nextRelevantDate(from: now)
        }
        
        return CustomEventsEntry(
            date: now,
            customEvents: filteredEvents,
            widgetStyle: widgetStyle,
            title: title
        )
    }
}

struct CustomEventsEntry: TimelineEntry {
    let date: Date
    let customEvents: [CustomEvent]
    let widgetStyle: WidgetStyle
    let title: String
}

// MARK: - Main Entry View

struct CustomEventsWidgetEntryView : View {
    var entry: CustomEventsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            CustomEventsSmallView(entry: entry)
        case .systemMedium:
            CustomEventsMediumView(entry: entry)
        case .systemLarge:
            CustomEventsLargeView(entry: entry)
        default:
            CustomEventsMediumView(entry: entry)
        }
    }
}

// MARK: - Subviews

struct CustomEventsSmallView: View {
    let entry: CustomEventsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let event = entry.customEvents.first {
                let progress = event.calculateProgress()
                let metric = customEventMetric(event: event, progress: progress)

                widgetLink(for: .customEvent(id: event.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        if entry.widgetStyle == .classic {
                            Text(entry.title)
                                .font(.sabdeviBold(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Text(event.name)
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("\(metric.value)\(metric.unit)")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                }
            } else {
                EmptyCustomEventsState(title: entry.title)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct CustomEventsMediumView: View {
    let entry: CustomEventsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if entry.widgetStyle == .classic {
                Text(entry.title)
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(.primary)
            }

            if entry.customEvents.isEmpty {
                EmptyCustomEventsState(title: entry.title)
            } else {
                ForEach(Array(entry.customEvents.prefix(3).enumerated()), id: \.element.id) { index, event in
                    widgetLink(for: .customEvent(id: event.id)) {
                        CustomEventRow(event: event)
                    }

                    if index < min(entry.customEvents.count, 3) - 1 {
                        Divider()
                            .background(Color.secondary.opacity(0.1))
                    }
                }
            }
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct CustomEventsLargeView: View {
    let entry: CustomEventsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if entry.widgetStyle == .classic {
                Text(entry.title)
                    .font(.sabdeviBold(size: 16))
                    .foregroundColor(.primary)
            }

            if entry.customEvents.isEmpty {
                EmptyCustomEventsState(title: entry.title)
            } else {
                ForEach(Array(entry.customEvents.prefix(6).enumerated()), id: \.element.id) { index, event in
                    widgetLink(for: .customEvent(id: event.id)) {
                        CustomEventRow(event: event)
                    }

                    if index < min(entry.customEvents.count, 6) - 1 {
                        Divider()
                            .background(Color.secondary.opacity(0.1))
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

// MARK: - Row and Helpers

struct CustomEventRow: View {
    let event: CustomEvent

    var body: some View {
        let progress = event.calculateProgress()
        let metric = customEventMetric(event: event, progress: progress)

        HStack(alignment: .center, spacing: 4) {
            Text(event.name)
                .font(.sabdeviRegular(size: 14))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer(minLength: 8)

            if event.mode == .habit {
                 Text("\(metric.value)")
                     .font(.sabdeviBold(size: 14))
                     .foregroundColor(.primary)
                 + Text(" streak")
                     .font(.sabdeviRegular(size: 14))
                     .foregroundColor(.secondary)
            } else if progress.isToday {
                Text("Today")
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(.red)
            } else {
                Text("\(metric.value)")
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(metric.isCritical ? .red : .primary)
                + Text(" \(metric.unit)")
                    .font(.sabdeviRegular(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

func customEventMetric(event: CustomEvent, progress: (daysLeft: Int, weeksLeft: Int, useWeeks: Bool, isPast: Bool, isToday: Bool, formattedDate: String, totalDays: Int, daysCompleted: Int)) -> (value: Int, unit: String, isCritical: Bool) {
    if event.mode == .habit {
        return (event.currentStreak, " streak", false)
    }
    
    if event.mode == .countup {
        if progress.useWeeks {
            return (max(0, progress.weeksLeft), "wk  since", false)
        }
        return (max(0, progress.daysLeft), "d  since", false)
    }

    if progress.useWeeks {
        let unit = progress.isPast ? "wk  ago" : "wk  left"
        return (max(0, progress.weeksLeft), unit, false)
    }

    let value = progress.isPast ? abs(progress.daysLeft) : max(0, progress.daysLeft)
    let unit = progress.isPast ? "d  ago" : "d  left"
    let isCritical = !progress.isPast && progress.daysLeft <= 5
    return (value, unit, isCritical)
}

struct EmptyCustomEventsState: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No \(title.lowercased())")
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary)
            Text("Add in app")
                .font(.sabdeviRegular(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
}

// MARK: - Widget Definitions

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomEventsProvider(modeFilter: .countdown, title: "My Counts")) { entry in
            CustomEventsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Countdowns")
        .description("Track your upcoming events.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CountUpWidget: Widget {
    let kind: String = "CountUpWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomEventsProvider(modeFilter: .countup, title: "Since...")) { entry in
            CustomEventsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Count Ups")
        .description("Track time since an event.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HabitWidget: Widget {
    let kind: String = "HabitWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomEventsProvider(modeFilter: .habit, title: "My Habits")) { entry in
            CustomEventsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habits")
        .description("Track your daily streaks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
