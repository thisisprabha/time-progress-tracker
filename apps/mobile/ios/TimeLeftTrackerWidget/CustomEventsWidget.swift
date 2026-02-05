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
        CustomEventsEntry(
            date: Date(),
            customEvents: [
                CustomEvent(name: "Birthday", date: "2026-12-25"),
                CustomEvent(name: "Trip", date: "2026-05-01"),
                CustomEvent(name: "Exam", date: "2026-03-15")
            ],
            widgetStyle: .classic
        )
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

        let widgetStyle = WidgetStyle(rawValue: sharedDefaults?.string(forKey: "widgetStyle") ?? "classic") ?? .classic
        
        let now = Date()

        var upcomingEvents = customEvents

        // Sort by relevance (countdowns by next occurrence, countups by recent start)
        upcomingEvents.sort { event1, event2 in
            if event1.mode != event2.mode {
                return event1.mode == .countdown
            }
            if event1.mode == .countup && event2.mode == .countup {
                return event1.nextRelevantDate(from: now) > event2.nextRelevantDate(from: now)
            }
            return event1.nextRelevantDate(from: now) < event2.nextRelevantDate(from: now)
        }
        
        // Return entries
        return CustomEventsEntry(
            date: now,
            customEvents: upcomingEvents,
            widgetStyle: widgetStyle
        )
    }
}

struct CustomEventsEntry: TimelineEntry {
    let date: Date
    let customEvents: [CustomEvent]
    let widgetStyle: WidgetStyle
}

struct CustomEventsWidgetEntryView : View {
    var entry: CustomEventsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            CustomEventsSmallView(entry: entry)
        case .systemMedium:
            CustomEventsMediumView(entry: entry)
        case .systemLarge:
            CustomEventsLargeView(entry: entry)
        case .accessoryCircular:
            CustomEventsCircularView(entry: entry)
        case .accessoryRectangular:
            CustomEventsRectangularView(entry: entry)
        case .accessoryInline:
            CustomEventsInlineView(entry: entry)
        default:
            CustomEventsLargeView(entry: entry)
        }
    }
}

struct CustomEventsSmallView: View {
    let entry: CustomEventsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let event = entry.customEvents.first {
                let progress = event.calculateProgress()

                widgetLink(for: .customEvent(id: event.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        if entry.widgetStyle == .classic {
                            Text(event.mode == .countup ? "Since" : "Next")
                                .font(.sabdeviBold(size: 12))
                                .foregroundColor(.primary)
                        }

                        Text(event.name)
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(customEventStatusText(event: event, progress: progress))
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                }
            } else {
                EmptyCustomEventsState()
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
        VStack(alignment: .leading, spacing: 8) {
            if entry.widgetStyle == .classic {
                Text("Your Events")
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(.primary)
            }

            if entry.customEvents.isEmpty {
                EmptyCustomEventsState()
            } else {
                ForEach(Array(entry.customEvents.prefix(2).enumerated()), id: \.element.id) { index, event in
                    widgetLink(for: .customEvent(id: event.id)) {
                        CustomEventRow(event: event)
                    }

                    if entry.widgetStyle == .classic, index < min(entry.customEvents.count, 2) - 1 {
                        Divider()
                            .background(Color.secondary.opacity(0.2))
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
        VStack(alignment: .leading, spacing: 0) {
            if entry.widgetStyle == .classic {
                Text("Your Events")
                    .font(.sabdeviBold(size: 16))
                    .foregroundColor(.primary)
                    .padding(.bottom, 12)
            }

            if entry.customEvents.isEmpty {
                EmptyCustomEventsState()
                    .frame(maxHeight: .infinity, alignment: .topLeading)
            } else {
                ForEach(Array(entry.customEvents.prefix(5).enumerated()), id: \.element.id) { index, event in
                    widgetLink(for: .customEvent(id: event.id)) {
                        CustomEventRow(event: event)
                            .padding(.vertical, 8)
                    }

                    if entry.widgetStyle == .classic, index < min(entry.customEvents.count, 5) - 1 {
                        Divider()
                            .background(Color.secondary.opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct CustomEventsCircularView: View {
    let entry: CustomEventsEntry

    var body: some View {
        Group {
            if let event = entry.customEvents.first {
                let progress = event.calculateProgress()
                let metric = customEventMetric(event: event, progress: progress)
                let total = max(1, progress.totalDays)
                let completed = min(total, max(0, progress.daysCompleted))
                let ratio = Double(completed) / Double(total)

                Gauge(value: ratio) {
                    Text("Event")
                } currentValueLabel: {
                    Text(progress.isToday ? "0" : "\(metric.value)")
                        .font(.sabdeviBold(size: 10))
                }
                .gaugeStyle(.accessoryCircular)
                .containerBackground(.clear, for: .widget)
                .widgetURL(widgetEventURL(event.id))
            } else {
                Text("—")
                    .font(.sabdeviBold(size: 12))
                    .containerBackground(.clear, for: .widget)
            }
        }
    }
}

struct CustomEventsRectangularView: View {
    let entry: CustomEventsEntry

    var body: some View {
        Group {
            if let event = entry.customEvents.first {
                let progress = event.calculateProgress()
                let statusText = customEventStatusText(event: event, progress: progress)
                let total = max(1, progress.totalDays)
                let completed = min(total, max(0, progress.daysCompleted))
                let ratio = Double(completed) / Double(total)

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(event.name) • \(statusText)")
                        .font(.sabdeviRegular(size: 12))
                        .lineLimit(1)
                    ProgressView(value: ratio)
                        .progressViewStyle(.linear)
                        .frame(height: 10)
                        .tint(.primary)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .containerBackground(.clear, for: .widget)
                .widgetURL(widgetEventURL(event.id))
            } else {
                Text("No events")
                    .font(.sabdeviRegular(size: 12))
                    .containerBackground(.clear, for: .widget)
            }
        }
    }
}

struct CustomEventsInlineView: View {
    let entry: CustomEventsEntry

    var body: some View {
        if let event = entry.customEvents.first {
            let progress = event.calculateProgress()
            let statusText = customEventStatusText(event: event, progress: progress)
            Text("\(event.name): \(statusText)")
                .font(.sabdeviRegular(size: 12))
                .containerBackground(.clear, for: .widget)
                .widgetURL(widgetEventURL(event.id))
        } else {
            Text("No events")
                .font(.sabdeviRegular(size: 12))
                .containerBackground(.clear, for: .widget)
        }
    }
}

func customEventMetric(event: CustomEvent, progress: (daysLeft: Int, weeksLeft: Int, useWeeks: Bool, isPast: Bool, isToday: Bool, formattedDate: String, totalDays: Int, daysCompleted: Int)) -> (value: Int, unit: String, isCritical: Bool) {
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

func customEventStatusText(event: CustomEvent, progress: (daysLeft: Int, weeksLeft: Int, useWeeks: Bool, isPast: Bool, isToday: Bool, formattedDate: String, totalDays: Int, daysCompleted: Int)) -> String {
    if progress.isToday {
        return "Today"
    }
    let metric = customEventMetric(event: event, progress: progress)
    return "\(metric.value) \(metric.unit)"
}

struct CustomEventRow: View {
    let event: CustomEvent

    var body: some View {
        let progress = event.calculateProgress()
        let metric = customEventMetric(event: event, progress: progress)
        let formattedDate = progress.formattedDate

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(event.name)
                .font(.sabdeviRegular(size: 14))
                .foregroundColor(.primary)
                .lineLimit(1)

            if progress.isToday {
                Text("is Today!")
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

            Text("(\(formattedDate))")
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .layoutPriority(-1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyCustomEventsState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No events yet")
                .font(.sabdeviRegular(size: 14))
                .foregroundColor(.secondary)

            Text("Add events in the app")
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary.opacity(0.8))
        }
    }
}

struct CustomEventsWidget: Widget {
    let kind: String = "CustomEventsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomEventsProvider()) { entry in
            CustomEventsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Custom Events")
        .description("View your events.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
    
    init() {
        // Register fonts just in case
        registerFontsForWidget()
    }
}
