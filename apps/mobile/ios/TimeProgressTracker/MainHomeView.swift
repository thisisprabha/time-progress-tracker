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
    @State private var animationRestartTrigger: Int = 0
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
                            animationRestartTrigger: animationRestartTrigger,
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
                            animationRestartTrigger: animationRestartTrigger,
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
                
                // Main content - scrollable
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacer to push content to center
                        Spacer()
                            .frame(height: 20)
                        
                        // Main sections
                        VStack(spacing: 16) {
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
                            
                            // Life Progress card - always shown as 4th section (last)
                            LifeProgressCardView()
                                .environmentObject(appState)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.6).delay(Double(displayedCount + emptySlotsNeeded) * 0.2),
                                    value: showContent
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Bottom spacer
                        Spacer()
                            .frame(height: 20)
                        
                        // Customize button at bottom
                        Button(action: {
                            appState.showSettings = true
                        }) {
                            Text("Customize")
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.secondary)
                                .underline()
                        }
                        .padding(.bottom, 20)
                    }
                    .frame(minHeight: UIScreen.main.bounds.height - 200) // Min height to allow centering
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
        .onChange(of: appState.showSettings) { isShowing in
            // When settings closes (goes from true to false), restart animations
            if !isShowing {
                print("🔄 [MainHomeView] Settings closed - restarting animations")
                // Reset content visibility
                showContent = false
                sunStarted = false
                // Trigger animation restart
                animationRestartTrigger += 1
            }
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
        VStack(alignment: .leading, spacing: 8) {
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
        let itemsPerRow = 18 // Approximate items per row
        let rows = (total + itemsPerRow - 1) / itemsPerRow
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 2) {
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

struct LifeProgressCardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLifeDataSelection = false
    
    // Check if life data is set (not default values or not saved)
    private var isLifeDataSet: Bool {
        // Check if values are saved in UserDefaults
        return UserDefaults.standard.object(forKey: "userAge") != nil &&
               UserDefaults.standard.object(forKey: "lifeExpectancy") != nil
    }
    
    // Calculate percentage left and done based on user's age and life expectancy
    private var percentageLeft: Int {
        let yearsLeft = appState.lifeExpectancy - appState.userAge
        guard appState.lifeExpectancy > 0 else { return 0 }
        return max(0, min(100, Int((Double(yearsLeft) / Double(appState.lifeExpectancy)) * 100)))
    }
    
    private var percentageDone: Int {
        return 100 - percentageLeft
    }
    
    var body: some View {
        Button(action: {
            showLifeDataSelection = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Label on left (regular), Value on right (bold)
                HStack {
                    HStack(spacing: 8) {
                        if !isLifeDataSet {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        Text("Your  life")
                            .font(.sabdeviRegular(size: 15))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if isLifeDataSet {
                        HStack(spacing: 0) {
                            Text(appState.perspective == .halfFull ? "\(percentageDone)" : "\(percentageLeft)")
                                .font(.sabdeviBold(size: 15))
                                .foregroundColor(.primary)
                            Text(appState.perspective == .halfFull ? "%  done" : "%  left")
                                .font(.sabdeviBold(size: 15))
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("Tap  to  add")
                            .font(.sabdeviRegular(size: 13))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                
                // Progress bar with tally marks style (always show what's completed/lived)
                if isLifeDataSet {
                    TallyMarksView(total: 100, completed: percentageDone)
                } else {
                    // Show empty state
                    HStack {
                        Text("Add  your  age  and  life  expectancy")
                            .font(.sabdeviRegular(size: 13))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showLifeDataSelection) {
            LifeDataSelectionView(age: appState.userAge, lifeExpectancy: appState.lifeExpectancy)
                .environmentObject(appState)
        }
    }
}
