//
//  EventCSVExporter.swift
//  TimeProgressTracker
//
//  CSV export for events
//

import Foundation

enum EventCSVExporter {
    static func export(events: [CustomEvent]) throws -> URL {
        let header = [
            "id",
            "name",
            "category",
            "mode",
            "recurrence",
            "date",
            "startDate",
            "timeOfDay",
            "reminders"
        ]

        var lines: [String] = [header.joined(separator: ",")]

        for event in events {
            let reminderText = event.reminders.map { "\($0.offsetMinutes)" }.joined(separator: "|")
            let row = [
                csv(event.id),
                csv(event.name),
                csv(event.category.rawValue),
                csv(event.mode.rawValue),
                csv(event.recurrence.rawValue),
                csv(event.date),
                csv(event.startDate),
                csv(event.timeOfDay ?? ""),
                csv(reminderText)
            ]
            lines.append(row.joined(separator: ","))
        }

        let csvText = lines.joined(separator: "\n")
        let fileName = "time-progress-events-\(formattedDateString()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvText.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    private static func csv(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private static func formattedDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
