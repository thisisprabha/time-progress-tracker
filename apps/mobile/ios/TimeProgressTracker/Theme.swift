//
//  Theme.swift
//  TimeProgressTracker
//
//  App theme tokens
//

import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case classic
    case sunrise
    case ocean
    case forest
    case midnight

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .sunrise: return "Sunrise"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .midnight: return "Midnight"
        }
    }

    func accentColor(isDark: Bool) -> Color {
        switch self {
        case .classic:
            return isDark ? .blue : .black
        case .sunrise:
            return Color(red: 0.93, green: 0.47, blue: 0.32)
        case .ocean:
            return Color(red: 0.20, green: 0.48, blue: 0.70)
        case .forest:
            return Color(red: 0.18, green: 0.52, blue: 0.34)
        case .midnight:
            return Color(red: 0.45, green: 0.60, blue: 0.95)
        }
    }

    func backgroundColor(isDark: Bool) -> Color {
        switch self {
        case .classic:
            return Color(.systemBackground)
        case .sunrise:
            return isDark
                ? Color(red: 0.14, green: 0.10, blue: 0.12)
                : Color(red: 0.98, green: 0.95, blue: 0.90)
        case .ocean:
            return isDark
                ? Color(red: 0.08, green: 0.11, blue: 0.15)
                : Color(red: 0.93, green: 0.97, blue: 0.99)
        case .forest:
            return isDark
                ? Color(red: 0.09, green: 0.12, blue: 0.10)
                : Color(red: 0.94, green: 0.97, blue: 0.94)
        case .midnight:
            return isDark
                ? Color(red: 0.06, green: 0.07, blue: 0.10)
                : Color(red: 0.94, green: 0.95, blue: 0.99)
        }
    }

    func groupedBackgroundColor(isDark: Bool) -> Color {
        switch self {
        case .classic:
            return Color(.systemGroupedBackground)
        case .sunrise:
            return isDark
                ? Color(red: 0.12, green: 0.09, blue: 0.11)
                : Color(red: 0.97, green: 0.94, blue: 0.90)
        case .ocean:
            return isDark
                ? Color(red: 0.07, green: 0.10, blue: 0.14)
                : Color(red: 0.91, green: 0.96, blue: 0.99)
        case .forest:
            return isDark
                ? Color(red: 0.08, green: 0.10, blue: 0.09)
                : Color(red: 0.92, green: 0.96, blue: 0.92)
        case .midnight:
            return isDark
                ? Color(red: 0.05, green: 0.06, blue: 0.09)
                : Color(red: 0.92, green: 0.94, blue: 0.99)
        }
    }
}
