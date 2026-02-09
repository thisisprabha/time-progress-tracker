//
//  MainHomeView.swift
//  TimeProgressTracker
//
//  Main Home Screen
//

import SwiftUI
import WebKit
import UIKit

struct MainHomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var timeData = TimeCalculator.calculateTimeData(timeMode: .twentyFourHour)
    @State private var timer: Timer?
    @State private var showContent: Bool = false
    @State private var sunStarted: Bool = false
    @State private var cloudsStarted: Bool = false
    @State private var birdsStarted: Bool = false
    @State private var animationRestartTrigger: Int = 0
    @State private var selectedSection: HomeSection = .countdown
    @State private var showWidgetHelp: Bool = false
    @State private var showPaywall: Bool = false
    var onSVGsLoaded: (() -> Void)? = nil
    var startAnimations: Bool = false

    private var displayItems: [DisplayItem] {
        var items = appState.selectedDisplayItems

        if let deepLinkID = appState.pendingDeepLinkEventID,
           appState.customEvents.contains(where: { $0.id == deepLinkID }) {
            let deepItem = DisplayItem.customEvent(id: deepLinkID)
            items.removeAll { $0 == deepItem }
            items.insert(deepItem, at: 0)
        }

        return items
    }

    // Split items into sections
    private var countdownItems: [DisplayItem] {
        displayItems.filter { item in
            switch item {
            case .today, .week, .month, .quarter, .year:
                return true
            case .customEvent(let id):
                return appState.customEvents.first(where: { $0.id == id })?.mode == .countdown
            }
        }
    }

    private var countUpItems: [DisplayItem] {
        displayItems.filter { item in
            if case .customEvent(let id) = item {
                return appState.customEvents.first(where: { $0.id == id })?.mode == .countup
            }
            return false
        }
    }

    private var habitItems: [DisplayItem] {
        displayItems.filter { item in
            if case .customEvent(let id) = item {
                return appState.customEvents.first(where: { $0.id == id })?.mode == .habit
            }
            return false
        }
    }

    private func items(for section: HomeSection) -> [DisplayItem] {
        switch section {
        case .countdown: return countdownItems
        case .countup: return countUpItems
        case .habits: return habitItems
        }
    }
    
    var body: some View {
        ZStack {
            if let data = appState.customBackgroundImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(
                        Color.black.opacity(appState.isDarkMode ? 0.35 : 0.15)
                            .ignoresSafeArea()
                    )
            }

            appState.theme.backgroundColor(isDark: appState.isDarkMode)
                .opacity(appState.customBackgroundImageData == nil ? 1 : 0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content - scrollable
                ScrollView {
                    VStack(spacing: 0) {
                        // Animated Header - moved inside ScrollView to hide on scroll
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
                        .frame(height: 140)
                        .padding(.top, 0)

                        // Main sections with mini tab
                        SectionPicker(selected: $selectedSection)
                            .padding(.horizontal, 20)

                        VStack(spacing: 16) {
            SectionContent(
                title: selectedSection.title,
                items: items(for: selectedSection),
                timeData: timeData,
                showContent: showContent
            )
            .environmentObject(appState)

                            LeavePlannerCardView()
                                .environmentObject(appState)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.6).delay(0.6),
                                    value: showContent
                                )

                            WidgetInviteCard {
                                showWidgetHelp = true
                            }
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(
                                .easeOut(duration: 0.6).delay(0.65),
                                value: showContent
                            )

                            Button(action: {
                                appState.settingsFocus = selectedSection
                                appState.saveSettings()
                                appState.showSettings = true
                            }) {
                                Text(selectedSection.customizeLabel)
                                    .font(.sabdeviRegular(size: 12))
                                    .foregroundColor(.secondary)
                                    .underline()
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
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
            AddCustomEventView(initialMode: appState.pendingAddEventMode ?? .countdown)
                .environmentObject(appState)
                .environmentObject(purchaseManager)
        }
        .sheet(isPresented: $showWidgetHelp) {
            WidgetHelpSheet(section: selectedSection)
                .presentationDetents([.medium])
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

private struct SectionPicker: View {
    @Binding var selected: HomeSection

    var body: some View {
        HStack(spacing: 10) {
            ForEach(HomeSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selected = section
                    }
                }) {
                    Text(section.title)
                        .font(.sabdeviBold(size: 13))
                        .foregroundColor(selected == section ? .primary : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected == section ? Color.primary.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
        )
    }
}

private struct SectionContent: View {
    let title: String
    let items: [DisplayItem]
    let timeData: TimeData
    let showContent: Bool
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var purchaseManager: PurchaseManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.sabdeviBold(size: 16))
                .foregroundColor(.primary)

            if items.isEmpty {
                EmptySectionView(section: title, onCreate: {
                    switch title.lowercased() {
                    case "countdowns":
                        appState.pendingAddEventMode = .countdown
                    case "count up", "countup":
                        appState.pendingAddEventMode = .countup
                    case "habits":
                        appState.pendingAddEventMode = .habit
                    default:
                        appState.pendingAddEventMode = .countdown
                    }
                    appState.showAddEvent = true
                }, onWidgetHelp: {
                    // handled by parent via binding
                })
                .environmentObject(appState)
            } else {
                ForEach(Array(items.enumerated()), id: \.element) { index, item in
                    Group {
                        switch item {
                        case .today:
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
                        case .week:
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
                        case .month:
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
                        case .quarter:
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
                        case .year:
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
                        case .customEvent(let eventId):
                            if let event = appState.customEvents.first(where: { $0.id == eventId }) {
                                CustomEventTallyView(event: event)
                                    .environmentObject(appState)
                            }
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.6).delay(Double(index) * 0.15),
                        value: showContent
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
        )
    }
}

private struct EmptySectionView: View {
    let section: String
    let onCreate: () -> Void
    let onWidgetHelp: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(emptyTitle)
                .font(.sabdeviBold(size: 16))
            Button(action: onCreate) {
                Text(primaryCTA)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: onWidgetHelp) {
                Text("Widgets available · Where to find?")
                    .font(.sabdeviRegular(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
        )
    }

    private var emptyTitle: String {
        switch section.lowercased() {
        case "countdowns": return "No countdowns yet"
        case "count up", "countup": return "Nothing to count up yet"
        case "habits": return "No habits yet"
        default: return "Nothing here yet"
        }
    }

    private var primaryCTA: String {
        switch section.lowercased() {
        case "countdowns": return "Create countdown"
        case "count up", "countup": return "Create count up"
        case "habits": return "Create habit"
        default: return "Create item"
        }
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

// Helper function to calculate tally marks height
private func calculateTallyHeight(total: Int) -> CGFloat {
    let screenWidth = UIScreen.main.bounds.width
    let cardPadding: CGFloat = 32 // Left + right padding
    let availableWidth = screenWidth - cardPadding
    let itemWidth: CGFloat = 16
    let spacing: CGFloat = 2
    let itemsPerRow = max(1, Int(availableWidth / (itemWidth + spacing)))
    let rows = (total + itemsPerRow - 1) / max(1, itemsPerRow)
    let rowHeight: CGFloat = 24 // 20pt mark + 4pt spacing
    return CGFloat(rows) * rowHeight
}

struct TallyMarksView: View {
    let total: Int
    let completed: Int
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let itemWidth: CGFloat = 16
            let spacing: CGFloat = 2
            let itemsPerRow = max(1, Int(availableWidth / (itemWidth + spacing)))
            let rows = (total + itemsPerRow - 1) / max(1, itemsPerRow)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        let startIndex = row * itemsPerRow
                        let endIndex = min(startIndex + itemsPerRow, total)
                        
                        ForEach(startIndex..<endIndex, id: \.self) { index in
                            TallyMarkView(isCompleted: index < completed)
                        }
                    }
                }
            }
        }
        .frame(height: calculateTallyHeight(total: total))
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

private extension MainHomeView {}

struct HabitStreakCard: View {
    let habit: Habit

    var body: some View {
        let streak = habit.currentStreak()
        let longest = habit.longestStreak()
        let success = habit.successRate()
        VStack(alignment: .leading, spacing: 8) {
            Text("Streak")
                .font(.sabdeviBold(size: 14))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(streak)")
                    .font(.sabdeviBold(size: 42))
                Text("days")
                    .font(.sabdeviRegular(size: 14))
            }
            Text("Longest \(longest) • \(success)% success")
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct LeaveSuggestionCard: View {
    let insights: LeaveInsights

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leave Optimizer")
                .font(.sabdeviBold(size: 14))
            Text("Next long weekend")
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary)
            Text(insights.nextLongWeekend)
                .font(.sabdeviBold(size: 16))
            Divider()
            Text("Best suggestion")
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary)
            Text(insights.bestSuggestion)
                .font(.sabdeviBold(size: 16))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
