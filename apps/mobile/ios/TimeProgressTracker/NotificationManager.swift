//
//  NotificationManager.swift
//  TimeProgressTracker
//
//  Local notification scheduling for event reminders
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func applySettings(events: [CustomEvent], enabled: Bool) async {
        if !enabled {
            cancelAll()
            return
        }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else {
            cancelAll()
            return
        }

        scheduleNotifications(for: events)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    private func scheduleNotifications(for events: [CustomEvent]) {
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let calendar = Calendar.current

        for event in events where event.mode == .countdown {
            let reminders = event.reminders.sorted { $0.offsetMinutes > $1.offsetMinutes }
            guard !reminders.isEmpty else { continue }

            let occurrenceCount = event.recurrence == .none ? 1 : 3
            let occurrences = event.upcomingOccurrences(from: now, limit: occurrenceCount)

            for occurrence in occurrences {
                let notificationBase = notificationBaseDate(for: event, occurrence: occurrence)

                for reminder in reminders {
                    let triggerDate = calendar.date(byAdding: .minute, value: -reminder.offsetMinutes, to: notificationBase) ?? notificationBase
                    guard triggerDate > now else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = event.name
                    content.body = reminderBody(for: event, triggerDate: triggerDate, occurrence: occurrence)
                    content.sound = .default
                    content.userInfo = ["eventID": event.id]

                    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let identifier = "event-\(event.id)-\(Int(triggerDate.timeIntervalSince1970))-\(reminder.id)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    center.add(request)
                }
            }
        }
    }

    private func notificationBaseDate(for event: CustomEvent, occurrence: Date) -> Date {
        guard event.timeOfDay == nil else { return occurrence }
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: occurrence) ?? occurrence
    }

    private func reminderBody(for event: CustomEvent, triggerDate: Date, occurrence: Date) -> String {
        let diff = occurrence.timeIntervalSince(triggerDate)
        let minutes = max(0, Int(diff / 60))

        if minutes >= 60 * 24 {
            let days = max(1, Int(round(Double(minutes) / Double(60 * 24))))
            return "\(days) days left • \(formattedDate(occurrence))"
        }

        if minutes >= 60 {
            let hours = max(1, Int(round(Double(minutes) / 60.0)))
            return "\(hours) hours left • \(formattedDate(occurrence))"
        }

        return "Event is coming up • \(formattedDate(occurrence))"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy  HH:mm"
        return formatter.string(from: date)
    }
}
