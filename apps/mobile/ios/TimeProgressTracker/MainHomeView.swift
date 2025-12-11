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
    @State private var showContent: Bool = false
    @State private var sunStarted: Bool = false
    @State private var cloudsStarted: Bool = false
    @State private var birdsStarted: Bool = false
    var onSVGsLoaded: (() -> Void)? = nil
    var startAnimations: Bool = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Animated Header - moved to very top
                Group {
                    if appState.isDarkMode {
                        AnimatedHeaderView(
                            onSVGsLoaded: {
                                onSVGsLoaded?()
                            },
                            startAnimations: startAnimations,
                            onSunStarted: {
                                sunStarted = true
                                startSectionReveal()
                            },
                            onCloudsStarted: {
                                cloudsStarted = true
                            },
                            onBirdsStarted: {
                                birdsStarted = true
                            }
                        )
                        .colorInvert()
                    } else {
                        AnimatedHeaderView(
                            onSVGsLoaded: {
                                onSVGsLoaded?()
                            },
                            startAnimations: startAnimations,
                            onSunStarted: {
                                sunStarted = true
                                startSectionReveal()
                            },
                            onCloudsStarted: {
                                cloudsStarted = true
                            },
                            onBirdsStarted: {
                                birdsStarted = true
                            }
                        )
                    }
                }
                .frame(height: 200)
                .padding(.top, 0)
                
                // Main content - centered on screen
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Top spacer to push content to center
                        Spacer()
                        
                        // Main 3 sections - centered
                        VStack(spacing: 20) {
                            // Show items in order from selectedDisplayItems (preserves order from settings)
                            ForEach(Array(appState.selectedDisplayItems.enumerated()), id: \.element) { index, item in
                                Group {
                                    if item == .today {
                                        let isCritical = timeData.hoursLeft < 4
                                        TallyCounterView(
                                            label: "Today",
                                            value: appState.perspective == .halfFull
                                                ? "\(timeData.hoursCompleted)"
                                                : "\(timeData.hoursLeft)",
                                            unit: appState.perspective == .halfFull
                                                ? "hrs  done"
                                                : "hrs  left",
                                            total: appState.timeMode == .nineToFive ? 8 : 24,
                                            completed: timeData.hoursCompleted,
                                            textColor: isCritical ? .primary : .primary
                                        )
                                    } else if item == .week {
                                        TallyCounterView(
                                            label: "This  Week",
                                            value: appState.perspective == .halfFull
                                                ? "\(timeData.daysCompleted)"
                                                : "\(timeData.daysLeft)",
                                            unit: appState.perspective == .halfFull
                                                ? "d  done"
                                                : "d  left",
                                            total: 7,
                                            completed: timeData.daysCompleted
                                        )
                                    } else if item == .month {
                                        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
                                        TallyCounterView(
                                            label: "This  Month",
                                            value: appState.perspective == .halfFull
                                                ? "\(timeData.daysCompleted)"
                                                : "\(timeData.daysLeft)",
                                            unit: appState.perspective == .halfFull
                                                ? "d  done"
                                                : "d  left",
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
                                                ? "wk  done"
                                                : "wk  left",
                                            total: 13,
                                            completed: timeData.weeksCompleted
                                        )
                                    } else if item == .year {
                                        let isCritical = timeData.yearProgress >= 0.9
                                        TallyCounterView(
                                            label: "This  Year",
                                            value: appState.perspective == .halfFull
                                                ? "\(Int(timeData.yearProgress * 100))"
                                                : "\(Int(timeData.yearPercentLeft))",
                                            unit: appState.perspective == .halfFull
                                                ? "%  done"
                                                : "%  left",
                                            total: 12,
                                            completed: Int(timeData.yearProgress * 12),
                                            textColor: isCritical ? .primary : .primary
                                        )
                                    } else if case .customEvent(let eventId) = item {
                                        // Show specific custom event
                                        if let event = appState.customEvents.first(where: { $0.id == eventId }) {
                                            CustomEventTallyView(event: event)
                                                .environmentObject(appState)
                                        }
                                    }
                                }
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.6).delay(Double(index) * 0.2),
                                    value: showContent
                                )
                            }
                            
                            // Show empty slots with lock icon if less than 3 items
                            let displayedCount = appState.selectedDisplayItems.count
                            let emptySlotsNeeded = 3 - displayedCount
                            
                            if emptySlotsNeeded > 0 {
                                ForEach(0..<emptySlotsNeeded, id: \.self) { index in
                                    EmptyEventSlotView()
                                        .environmentObject(appState)
                                        .opacity(showContent ? 1 : 0)
                                        .offset(y: showContent ? 0 : 20)
                                        .animation(
                                            .easeOut(duration: 0.6).delay(Double(displayedCount + index) * 0.2),
                                            value: showContent
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Bottom spacer to push content to center
                        Spacer()
                        
                        // Customize button at bottom
                        Button(action: {
                            appState.showSettings = true
                        }) {
                            Text("Customize")
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.secondary)
                                .underline()
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .onAppear {
            updateTimeData()
            timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                updateTimeData()
            }
        }
        .onChange(of: sunStarted) { started in
            if started {
                startSectionReveal()
            }
        }
        .onChange(of: appState.timeMode) { _ in
            updateTimeData()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showAddEvent) {
            AddCustomEventView()
                .environmentObject(appState)
        }
    }
    
    private func startSectionReveal() {
        // Step 4: Reveal sections one by one after sun starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
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
                    .foregroundColor(.secondary.opacity(0.5))
                
                VStack(spacing: 4) {
                    Text("Add  your  custom  event")
                        .font(.sabdeviRegular(size: 13))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("date  here")
                        .font(.sabdeviRegular(size: 13))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
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
    var textColor: Color = .primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label on left (regular), Value on right (bold)
            HStack {
                Text(TimeCalculator.addDoubleSpaces(label))
                    .font(.sabdeviRegular(size: 15))
                    .foregroundColor(textColor)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Text(value)
                        .font(.sabdeviBold(size: 15))
                        .foregroundColor(textColor)
                    Text(TimeCalculator.addDoubleSpaces(unit))
                        .font(.sabdeviBold(size: 15))
                        .foregroundColor(textColor)
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
                .fill(Color.secondary.opacity(0.4)) // increased contrast
                .frame(width: 2, height: 20)
            
            // Diagonal cross line (only when completed) - from top-left to bottom-right
            if isCompleted {
                Rectangle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 14, height: 2)
                    .rotationEffect(.degrees(45))
            }
        }
        .frame(width: 16, height: 20)
    }
}
