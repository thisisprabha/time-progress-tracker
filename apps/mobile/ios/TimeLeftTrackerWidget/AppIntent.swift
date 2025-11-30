//
//  AppIntent.swift
//  TimeLeftTrackerWidget
//
//  Widget Configuration (not used - widget reads from App Group)
//

import WidgetKit
import AppIntents

// Empty intent - widget uses App Group data instead
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Time left Tracker" }
    static var description: IntentDescription { "Track your time progress" }
}
