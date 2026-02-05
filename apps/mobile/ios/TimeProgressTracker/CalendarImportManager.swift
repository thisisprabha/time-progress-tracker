//
//  CalendarImportManager.swift
//  TimeProgressTracker
//
//  EventKit import for upcoming calendar events
//

import Foundation
import EventKit

@MainActor
final class CalendarImportManager {
    static let shared = CalendarImportManager()

    private let store = EKEventStore()

    private init() {}

    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            store.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func importUpcomingEvents(into appState: AppState, daysAhead: Int = 365, limit: Int = 200) async -> (imported: Int, skipped: Int) {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status != .authorized {
            let granted = await requestAccess()
            if !granted {
                return (0, 0)
            }
        }

        let calendars = store.calendars(for: .event)
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: now) ?? now
        let predicate = store.predicateForEvents(withStart: now, end: endDate, calendars: calendars)
        let events = store.events(matching: predicate).prefix(limit)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        var imported = 0
        var skipped = 0

        for event in events {
            guard !event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                skipped += 1
                continue
            }

            let isoDate = dateFormatter.string(from: event.startDate)
            let timeOfDay = event.isAllDay ? nil : timeFormatter.string(from: event.startDate)
            let recurrence = mapRecurrence(event.recurrenceRules?.first)

            let exists = appState.customEvents.contains { existing in
                existing.name == event.title && existing.date == isoDate && existing.timeOfDay == timeOfDay
            }

            if exists {
                skipped += 1
                continue
            }

            let newEvent = CustomEvent(
                name: event.title,
                date: isoDate,
                startDate: isoDate,
                category: .personal,
                mode: .countdown,
                recurrence: recurrence,
                timeOfDay: timeOfDay,
                reminders: []
            )
            appState.customEvents.append(newEvent)
            imported += 1
        }

        if imported > 0 {
            appState.saveSettings()
        }

        return (imported, skipped)
    }

    private func mapRecurrence(_ rule: EKRecurrenceRule?) -> EventRecurrence {
        guard let rule else { return .none }
        switch rule.frequency {
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        case .yearly:
            return .yearly
        default:
            return .none
        }
    }
}
