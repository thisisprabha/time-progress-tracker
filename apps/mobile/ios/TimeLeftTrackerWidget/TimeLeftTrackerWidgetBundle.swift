//
//  TimeLeftTrackerWidgetBundle.swift
//  TimeLeftTrackerWidget
//
//  Created by prabha karan on 30/11/25.
//

import WidgetKit
import SwiftUI

@main
struct TimeLeftTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeLeftTrackerWidget()
        CountdownWidget()
        CountUpWidget()
        HabitWidget()
        LeaveInsightsWidget()
    }
    // Removed Control and LiveActivity widgets - not needed for time progress tracking
}
