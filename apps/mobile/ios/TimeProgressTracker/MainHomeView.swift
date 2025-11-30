//
//  MainHomeView.swift
//  TimeProgressTracker
//
//  Main Home Screen
//

import SwiftUI
import WebKit

struct MainHomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var timeData = TimeCalculator.calculateTimeData(timeMode: .twentyFourHour)
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Animated Header - moved to very top
                AnimatedHeaderView()
                    .frame(height: 200)
                    .padding(.top, 0)
                
                Spacer()
                    .frame(height: 5)
                
                // Main content - show items in order from selectedDisplayItems
                ScrollView {
                    VStack(spacing: 20) {
                        // Show items in order from selectedDisplayItems (preserves order from settings)
                        ForEach(Array(appState.selectedDisplayItems.enumerated()), id: \.element) { index, item in
                            if item == .today {
                                TallyCounterView(
                                    label: "Today",
                                    value: appState.perspective == .halfFull
                                        ? "\(timeData.hoursCompleted)"
                                        : "\(timeData.hoursLeft)",
                                    unit: appState.perspective == .halfFull
                                        ? "hrs done"
                                        : "hrs left",
                                    total: 24,
                                    completed: timeData.hoursCompleted
                                )
                            } else if item == .week {
                                TallyCounterView(
                                    label: "This Week",
                                    value: appState.perspective == .halfFull
                                        ? "\(timeData.daysCompleted)"
                                        : "\(timeData.daysLeft)",
                                    unit: appState.perspective == .halfFull
                                        ? "d done"
                                        : "d left",
                                    total: 7,
                                    completed: timeData.daysCompleted
                                )
                            } else if item == .month {
                                let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
                                TallyCounterView(
                                    label: "This Month",
                                    value: appState.perspective == .halfFull
                                        ? "\(timeData.daysCompleted)"
                                        : "\(timeData.daysLeft)",
                                    unit: appState.perspective == .halfFull
                                        ? "d done"
                                        : "d left",
                                    total: daysInMonth,
                                    completed: timeData.daysCompleted
                                )
                            } else if item == .quarter {
                                TallyCounterView(
                                    label: "Q\(timeData.quarterNumber)",
                                    value: appState.perspective == .halfFull
                                        ? "\(timeData.weeksCompleted)"
                                        : "\(timeData.weeksLeft)",
                                    unit: appState.perspective == .halfFull
                                        ? "wk done"
                                        : "wk left",
                                    total: 13,
                                    completed: timeData.weeksCompleted
                                )
                            } else if item == .year {
                                TallyCounterView(
                                    label: "This Year",
                                    value: appState.perspective == .halfFull
                                        ? "\(Int(timeData.yearProgress * 100))"
                                        : "\(Int(timeData.yearPercentLeft))",
                                    unit: appState.perspective == .halfFull
                                        ? "% done"
                                        : "% left",
                                    total: 12,
                                    completed: Int(timeData.yearProgress * 12)
                                )
                            } else if case .customEvent(let eventId) = item {
                                // Show specific custom event
                                if let event = appState.customEvents.first(where: { $0.id == eventId }) {
                                    CustomEventTallyView(event: event)
                                        .environmentObject(appState)
                                }
                            }
                        }
                        
                        // Show empty slots with lock icon if less than 3 items
                        let displayedCount = appState.selectedDisplayItems.count
                        let emptySlotsNeeded = 3 - displayedCount
                        
                        if emptySlotsNeeded > 0 {
                            ForEach(0..<emptySlotsNeeded, id: \.self) { _ in
                                EmptyEventSlotView()
                                    .environmentObject(appState)
                            }
                        }
                        
                        // Customize button at bottom
                        Button(action: {
                            appState.showSettings = true
                        }) {
                            Text("Customize")
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.gray)
                                .underline()
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showAddEvent) {
            AddCustomEventView()
                .environmentObject(appState)
        }
        .onAppear {
            updateTimeData()
            timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                updateTimeData()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateTimeData() {
        timeData = TimeCalculator.calculateTimeData(timeMode: appState.timeMode)
    }
}

struct EmptyEventSlotView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: {
            appState.showAddEvent = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray.opacity(0.5))
                
                VStack(spacing: 4) {
                    Text("Add your custom event")
                        .font(.sabdeviRegular(size: 13))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("date here")
                        .font(.sabdeviRegular(size: 13))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TallyCounterView: View {
    let label: String
    let value: String
    let unit: String
    let total: Int
    let completed: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label on left (regular), Value on right (bold)
            HStack {
                Text(TimeCalculator.addDoubleSpaces(label))
                    .font(.sabdeviRegular(size: 15))
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Text(value)
                        .font(.sabdeviBold(size: 15))
                        .foregroundColor(.black)
                    Text(TimeCalculator.addDoubleSpaces(unit))
                        .font(.sabdeviBold(size: 15))
                        .foregroundColor(.black)
                }
            }
            
            // Tally marks below
            TallyMarksView(total: total, completed: completed)
        }
        .padding()
    }
}

struct TallyMarksView: View {
    let total: Int
    let completed: Int
    
    var body: some View {
        // Render tally marks in rows (like Android)
        let itemsPerRow = 15 // Approximate items per row
        let rows = (total + itemsPerRow - 1) / itemsPerRow
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    let startIndex = row * itemsPerRow
                    let endIndex = min(startIndex + itemsPerRow, total)
                    
                    ForEach(startIndex..<endIndex, id: \.self) { index in
                        TallyMarkView(isCompleted: index < completed)
                    }
                }
            }
        }
    }
}

struct TallyMarkView: View {
    let isCompleted: Bool
    
    var body: some View {
        // Ancient tally mark style: vertical line with diagonal cross when completed
        ZStack {
            // Vertical line (always shown)
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 2, height: 20)
            
            // Diagonal cross line (only when completed) - from top-left to bottom-right
            if isCompleted {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 14, height: 2)
                    .rotationEffect(.degrees(45))
            }
        }
        .frame(width: 16, height: 20)
    }
}
