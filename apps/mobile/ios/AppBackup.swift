//
//  AppBackup.swift
//  TimeProgressTracker
//
//  Manual backup/import helpers
//

import Foundation

struct AppBackup: Codable {
    let version: Int
    let createdAt: Date
    let perspective: String
    let timeMode: String
    let selectedDisplayItems: [String]
    let customEvents: [CustomEvent]
    let isDarkMode: Bool
    let userAge: Int
    let lifeExpectancy: Int
    let widgetStyle: String
    let theme: String
    let remindersEnabled: Bool
    let customBackgroundImageData: Data?

    static func from(appState: AppState) -> AppBackup {
        AppBackup(
            version: 1,
            createdAt: Date(),
            perspective: appState.perspective.rawValue,
            timeMode: appState.timeMode.rawValue,
            selectedDisplayItems: appState.selectedDisplayItems.map { $0.rawValue },
            customEvents: appState.customEvents,
            isDarkMode: appState.isDarkMode,
            userAge: appState.userAge,
            lifeExpectancy: appState.lifeExpectancy,
            widgetStyle: appState.widgetStyle.rawValue,
            theme: appState.theme.rawValue,
            remindersEnabled: appState.remindersEnabled,
            customBackgroundImageData: appState.customBackgroundImageData
        )
    }

    func apply(to appState: AppState) {
        if let perspective = Perspective(rawValue: perspective) {
            appState.perspective = perspective
        }

        if let timeMode = TimeMode(rawValue: timeMode) {
            appState.timeMode = timeMode
        }

        appState.selectedDisplayItems = selectedDisplayItems.compactMap { DisplayItem(rawValue: $0) }
        appState.customEvents = customEvents
        appState.isDarkMode = isDarkMode
        appState.userAge = userAge
        appState.lifeExpectancy = lifeExpectancy

        if let widgetStyle = WidgetStyle(rawValue: widgetStyle) {
            appState.widgetStyle = widgetStyle
        }

        if let theme = AppTheme(rawValue: theme) {
            appState.theme = theme
        }

        appState.remindersEnabled = remindersEnabled
        appState.customBackgroundImageData = customBackgroundImageData
    }
}

enum AppBackupManager {
    static func exportBackup(appState: AppState) throws -> URL {
        let backup = AppBackup.from(appState: appState)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let fileName = "time-progress-backup-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func importBackup(from url: URL, appState: AppState) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(AppBackup.self, from: data)
        backup.apply(to: appState)
        appState.saveSettings()
    }
}
