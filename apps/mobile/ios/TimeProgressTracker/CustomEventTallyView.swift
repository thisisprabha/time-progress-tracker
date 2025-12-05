//
//  CustomEventTallyView.swift
//  TimeProgressTracker
//
//  Custom Event Tally View
//

import SwiftUI

struct CustomEventTallyView: View {
    let event: CustomEvent
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        let progress = event.calculateProgress()
        
        let (label, value, unit, total, completed): (String, String, String, Int, Int) = {
            if progress.isToday {
                return (event.name, "Today!", "", 1, 1)
            } else if progress.isPast {
                if progress.useWeeks {
                    return (event.name, "\(progress.weeksLeft)", "wk  ago", progress.weeksLeft, progress.weeksLeft)
                } else {
                    return (event.name, "\(abs(progress.daysLeft))", "d  ago", abs(progress.daysLeft), abs(progress.daysLeft))
                }
            } else {
                if progress.useWeeks {
                    return (event.name, "\(progress.weeksLeft)", "wk  left", progress.weeksLeft, 0)
                } else {
                    // Use total duration and completed days for the progress bar
                    return (event.name, "\(progress.daysLeft)", "d  left", progress.totalDays, progress.daysCompleted)
                }
            }
        }()
        
        return TallyCounterView(
            label: label,
            value: value,
            unit: unit,
            total: max(total, 1),
            completed: completed
        )
    }
}


