//
//  AppIntent.swift
//  TimeProgressWidget
//
//  Created by prabha karan on 12/10/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Time Progress Configuration" }
    static var description: IntentDescription { "Configure your time progress widget settings." }

    // Perspective setting
    @Parameter(title: "Perspective", default: "optimistic")
    var perspective: String
    
    // Time mode setting
    @Parameter(title: "Time Mode", default: "24h")
    var timeMode: String
}