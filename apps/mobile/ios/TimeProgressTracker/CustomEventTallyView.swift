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
        if event.mode == .habit {
            HabitTallyView(event: event)
        } else {
            let progress = event.calculateProgress()

            let (label, value, unit, total, completed): (String, String, String, Int, Int) = {
                if event.mode == .countup {
                    if progress.isToday {
                        return (event.name, "Today!", "", 1, 1)
                    }

                    if progress.useWeeks {
                        return (event.name, "\(progress.weeksLeft)", "wk  since", max(progress.weeksLeft, 1), max(progress.weeksLeft, 1))
                    }

                    return (event.name, "\(progress.daysLeft)", "d  since", max(progress.totalDays, 1), max(progress.daysCompleted, 1))
                }

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

            let isCritical = event.mode == .countdown && !progress.isPast && progress.daysLeft <= 5
            
            TallyCounterView(
                label: label,
                value: value,
                unit: unit,
                total: max(total, 1),
                completed: completed,
                textColor: isCritical ? .red : .primary
            )
        }
    }
}

struct HabitTallyView: View {
    let event: CustomEvent
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Name and Streak
            HStack {
                Text(event.name)
                    .font(.sabdeviRegular(size: 15))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Text("\(event.currentStreak)")
                        .font(.sabdeviBold(size: 15))
                        .foregroundColor(.primary)
                    Text("  streak")
                        .font(.sabdeviBold(size: 15))
                        .foregroundColor(.primary)
                }
            }
            
            // Stats Row: Longest & Success & Milestone
            HStack {
                Text("Longest: \(event.longestStreak)")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Success: \(event.successRate)%")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)

                Spacer()
                
                Text("Goal: \(event.nextMilestone)")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Check-in Button
            Button(action: {
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                withAnimation(.spring()) {
                    appState.toggleCheckIn(for: event)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: event.isCheckedInToday ? "checkmark.circle.fill" : "circle")
                    Text(event.isCheckedInToday ? "Done  for  today" : "Check  In")
                }
                .font(.sabdeviBold(size: 14))
                .foregroundColor(event.isCheckedInToday ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(event.isCheckedInToday ? Color.green : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(event.isCheckedInToday ? Color.clear : Color.primary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

