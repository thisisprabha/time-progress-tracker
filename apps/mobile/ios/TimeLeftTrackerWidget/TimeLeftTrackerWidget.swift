//
//  TimeLeftTrackerWidget.swift
//  TimeLeftTrackerWidget
//
//  Time Progress Widget
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour),
            perspective: .halfFull,
            timeMode: .twentyFourHour,
            selectedItems: [.today, .month, .year],
            customEvents: [],
            widgetStyle: .classic
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("✅ [Widget] getTimeline called")
        let entry = loadEntry()
        print("✅ [Widget] Loaded entry with \(entry.selectedItems.count) selected items")
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadEntry() -> SimpleEntry {
        // Load from App Group
        let sharedDefaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
        
        let perspective = Perspective(rawValue: sharedDefaults?.string(forKey: "userPerspective") ?? "half-full") ?? .halfFull
        let timeMode = TimeMode(rawValue: sharedDefaults?.string(forKey: "timeMode") ?? "24h") ?? .twentyFourHour
        let widgetStyle = WidgetStyle(rawValue: sharedDefaults?.string(forKey: "widgetStyle") ?? "classic") ?? .classic
        
        // Load selected items
        var selectedItems: [DisplayItem] = [.today, .month, .year]
        if let itemsArray = sharedDefaults?.array(forKey: "selectedDisplayItems") as? [String] {
            selectedItems = itemsArray.compactMap { DisplayItem(rawValue: $0) }
            if selectedItems.count < 3 {
                selectedItems = [.today, .month, .year]
            }
        }
        
        // Load custom events
        var customEvents: [CustomEvent] = []
        if let eventsData = sharedDefaults?.data(forKey: "customEvents"),
           let events = try? JSONDecoder().decode([CustomEvent].self, from: eventsData) {
            // Hide habits/count-up events in the main progress widget per product decision.
            customEvents = events.filter { $0.mode == .countdown }
        }
        
        let timeData = TimeCalculator.calculateTimeData(timeMode: timeMode)
        
        // Sort selected items by "time remaining" (priority: lower time left = higher priority)
        // Today is usually most urgent.
        // Needs a way to compare "urgency".
        let sortedItems = selectedItems.sorted { item1, item2 in
            // Helper to estimate "days remaining" for sorting
            func getApproxDaysRemaining(item: DisplayItem) -> Double {
                switch item {
                case .today:
                    return 0.5 // Treat as < 1 day (urgency high)
                case .week:
                    return Double(timeData.daysLeftInWeek)
                case .month:
                    return Double(timeData.daysLeft)
                case .quarter:
                    // Use progress to estimate days left in current quarter
                    // Approx 91 days per quarter
                    return (1.0 - timeData.quarterProgress) * 91.0
                case .year:
                    // Use progress to estimate days left in year
                    // This prevents "0 months left" issue in December
                    return (1.0 - timeData.yearProgress) * 365.0
                case .customEvent(let id):
                    if let event = customEvents.first(where: { $0.id == id }) {
                        let (daysLeft, _, _, _, _, _, _, _) = event.calculateProgress()
                        return Double(max(0, daysLeft))
                    }
                    return 9999 // Fallback
                }
            }
            
            return getApproxDaysRemaining(item: item1) < getApproxDaysRemaining(item: item2)
        }
        
        return SimpleEntry(
            date: Date(),
            timeData: timeData,
            perspective: perspective,
            timeMode: timeMode,
            selectedItems: sortedItems,
            customEvents: customEvents,
            widgetStyle: widgetStyle
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let timeData: TimeData
    let perspective: Perspective
    let timeMode: TimeMode
    let selectedItems: [DisplayItem]
    let customEvents: [CustomEvent]
    let widgetStyle: WidgetStyle
}

struct TimeLeftTrackerWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            if entry.widgetStyle == .minimal {
                MinimalSmallWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        case .systemMedium:
            if entry.widgetStyle == .minimal {
                MinimalMediumWidgetView(entry: entry)
            } else {
                MediumWidgetView(entry: entry)
            }
        case .systemLarge:
            if entry.widgetStyle == .minimal {
                MinimalLargeWidgetView(entry: entry)
            } else {
                LargeWidgetView(entry: entry)
            }
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        default:
            if entry.widgetStyle == .minimal {
                MinimalMediumWidgetView(entry: entry)
            } else {
                MediumWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Widget Link Helpers

@ViewBuilder
func widgetLink(for item: DisplayItem, @ViewBuilder content: () -> some View) -> some View {
    if let url = widgetURL(for: item) {
        Link(destination: url) {
            content()
        }
    } else {
        content()
    }
}

func widgetUnitText(for item: DisplayItem, entry: SimpleEntry) -> String {
    switch item {
    case .today:
        return entry.perspective == .halfFull ? "hrs  done" : "hrs  left"
    case .week:
        return entry.perspective == .halfFull ? "d  done" : "d  left"
    case .month:
        return entry.perspective == .halfFull ? "d  done" : "d  left"
    case .quarter:
        return entry.perspective == .halfFull ? "wk  done" : "wk  left"
    case .year:
        return entry.perspective == .halfFull ? "%  done" : "%  left"
    case .customEvent(let id):
        guard let event = entry.customEvents.first(where: { $0.id == id }) else {
            return "d  left"
        }
        let progress = event.calculateProgress()
        if event.mode == .countup {
            return progress.useWeeks ? "wk  since" : "d  since"
        }
        if progress.useWeeks {
            return progress.isPast ? "wk  ago" : "wk  left"
        }
        
        if event.mode == .habit {
            return "  streak"
        }
        
        return progress.isPast ? "d  ago" : "d  left"
    }
}

// MARK: - Minimal Widget Views (No Dot Matrix)

struct MinimalSmallWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let item = entry.selectedItems.first {
                let label = item.displayName(in: entry.customEvents, quarterNumber: entry.timeData.quarterNumber)
                let (value, _) = getValueAndTotal(item: item, entry: entry)
                let unit = widgetUnitText(for: item, entry: entry)

                widgetLink(for: item) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(label)
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("\(value)\(unit)")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No items selected")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct MinimalMediumWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.selectedItems.isEmpty {
                Text("No items selected")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(entry.selectedItems.prefix(3).enumerated()), id: \.element) { index, item in
                    widgetLink(for: item) {
                        TextOnlyRow(item: item, entry: entry)
                    }

                    if index < min(entry.selectedItems.count, 3) - 1 {
                        Spacer()
                            .frame(height: 8)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct MinimalLargeWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if entry.selectedItems.isEmpty {
                Text("No items selected")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(entry.selectedItems.prefix(4).enumerated()), id: \.element) { index, item in
                    widgetLink(for: item) {
                        TextOnlyRow(item: item, entry: entry)
                    }

                    if index < min(entry.selectedItems.count, 4) - 1 {
                        Spacer()
                            .frame(height: 8)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let firstItem = entry.selectedItems.first {
                widgetLink(for: firstItem) {
                    ProgressRow(item: firstItem, entry: entry)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show all 3 configured items in medium widget - TEXT ONLY FORMAT
            if entry.selectedItems.isEmpty {
                // Fallback if no items - use explicit color
                VStack(alignment: .leading, spacing: 4) {
                    Text("No items selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Items: \(entry.selectedItems.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
            } else {
                ForEach(Array(entry.selectedItems.prefix(3).enumerated()), id: \.element) { index, item in
                    widgetLink(for: item) {
                        TextOnlyRow(item: item, entry: entry)
                    }
                    
                    // Add spacing between items (but not after the last one)
                    if index < min(entry.selectedItems.count, 3) - 1 {
                        Spacer()
                            .frame(height: 12)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

// Text-only row for Medium Widget
struct TextOnlyRow: View {
    let item: DisplayItem
    let entry: SimpleEntry
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            // Label - ensure it always displays with explicit color
            let labelText = item.displayName(in: entry.customEvents, quarterNumber: entry.timeData.quarterNumber)
            Text(labelText)
                .font(.sabdeviRegular(size: 14))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 8)
            
            // Value with unit - ensure it always displays with explicit color
            let (value, total) = getValueAndTotal(item: item, entry: entry)
            let unitText = getUnitText(for: item, value: value, total: total, entry: entry)
            let valueText = "\(value)\(unitText)"
            
            Text(valueText)
                .font(.sabdeviBold(size: 14))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getUnitText(for item: DisplayItem, value: Int, total: Int, entry: SimpleEntry) -> String {
        switch item {
        case .today:
            return entry.perspective == .halfFull ? "hrs  done" : "hrs  left"
        case .week:
            return entry.perspective == .halfFull ? "d  done" : "d  left"
        case .month:
            return entry.perspective == .halfFull ? "d  done" : "d  left"
        case .quarter:
            return entry.perspective == .halfFull ? "wk  done" : "wk  left"
        case .year:
            return entry.perspective == .halfFull ? "%  done" : "%  left"
        case .customEvent:
            return entry.perspective == .halfFull ? "d  done" : "d  left"
        }
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
        
            ForEach(Array(entry.selectedItems.prefix(3).enumerated()), id: \.element) { index, item in
              widgetLink(for: item) {
                  TallyProgressRow(item: item, entry: entry)
                      .padding(.vertical, 20.0)
              }
               
              
            }
            
          
        }
        .padding(.vertical, 10.0)
      
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct ProgressRow: View {
    let item: DisplayItem
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.displayName(in: entry.customEvents, quarterNumber: entry.timeData.quarterNumber))
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.primary)
            
            HStack {
                Text(valueText)
                    .font(.sabdeviBold(size: 18))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(unitText)
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var valueText: String {
        let (value, _) = getValueAndTotal(item: item, entry: entry)
        return "\(value)"
    }
    
    private var unitText: String {
        let (_, total) = getValueAndTotal(item: item, entry: entry)
        return entry.perspective == .halfFull ? "/\(total)  done" : "/\(total)  left"
    }
    
    private var progress: Double {
        let (value, total) = getValueAndTotal(item: item, entry: entry)
        return Double(value) / Double(total)
    }
    
    private var progressColor: Color {
        let prog = progress
        if entry.perspective == .halfEmpty {
            return prog > 0.75 ? .red : prog > 0.5 ? .orange : .green
        } else {
            return prog > 0.75 ? .green : prog > 0.5 ? .orange : .red
        }
    }
}

struct TallyProgressRow: View {
    let item: DisplayItem
    let entry: SimpleEntry
    
    var body: some View {
        let (value, total) = getValueAndTotal(item: item, entry: entry)
        
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.displayName(in: entry.customEvents, quarterNumber: entry.timeData.quarterNumber))
                    .font(.sabdeviRegular(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Value with unit (same as Medium widget)
                let unitText = getUnitTextForTally(for: item, value: value, total: total, entry: entry)
                Text("\(value)\(unitText)")
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(.primary)
            }
            
            // Tally Marks - ALWAYS show completed count, regardless of perspective
            let completedCount = getCompletedCount(item: item, entry: entry)
            let totalCount = getTotalCount(item: item, entry: entry)
            
            TallyMarksView(total: totalCount, completed: completedCount)
                .frame(height: 22)
        }
    }
    
    private func getUnitTextForTally(for item: DisplayItem, value: Int, total: Int, entry: SimpleEntry) -> String {
        switch item {
        case .today:
            return entry.perspective == .halfFull ? "hrs  done" : "hrs  left"
        case .week:
            return entry.perspective == .halfFull ? "d  done" : "d  left"
        case .month:
            return entry.perspective == .halfFull ? "d  done" : "d  left"
        case .quarter:
            return entry.perspective == .halfFull ? "wk  done" : "wk  left"
        case .year:
            return entry.perspective == .halfFull ? "%  done" : "%  left"
        case .customEvent:
            return entry.perspective == .halfFull ? "d  done" : "d  left"
        }
    }
}

// Helper function for values
func getValueAndTotal(item: DisplayItem, entry: SimpleEntry) -> (Int, Int) {
    switch item {
    case .today:
        let total = entry.timeMode == .nineToFive ? 8 : 24
        if entry.perspective == .halfFull {
            return (entry.timeData.hoursCompleted, total)
        } else {
            return (entry.timeData.hoursLeft, total)
        }
    case .month:
        let total = entry.timeData.daysCompleted + entry.timeData.daysLeft
        if entry.perspective == .halfFull {
            return (entry.timeData.daysCompleted, total)
        } else {
            return (entry.timeData.daysLeft, total)
        }
    case .year:
        if entry.perspective == .halfFull {
            // Calculate year percentage completed
            let yearPercent = Int(entry.timeData.yearProgress * 100)
            return (yearPercent, 100)
        } else {
            // Calculate year percentage left
            let yearPercent = Int((1.0 - entry.timeData.yearProgress) * 100)
            return (yearPercent, 100)
        }
    case .week:
        if entry.perspective == .halfFull {
            return (entry.timeData.daysCrossedInWeek, 7)
        } else {
            return (entry.timeData.daysLeftInWeek, 7)
        }
    case .quarter:
        if entry.perspective == .halfFull {
            return (entry.timeData.quartersCompleted, 4)
        } else {
            return (entry.timeData.quartersLeft, 4)
        }
    case .customEvent(let id):
        if let event = entry.customEvents.first(where: { $0.id == id }) {
            let progress = event.calculateProgress()
            let totalDays = max(1, progress.totalDays)
            let totalUnits = progress.useWeeks ? max(1, Int(ceil(Double(totalDays) / 7.0))) : totalDays

            if event.mode == .habit {
                return (event.currentStreak, event.nextMilestone)
            }
            
            if event.mode == .countup {
                let value = progress.useWeeks ? progress.weeksLeft : progress.daysLeft
                return (value, totalUnits)
            }

            if progress.useWeeks {
                return (progress.weeksLeft, totalUnits)
            }

            let value = progress.isPast ? abs(progress.daysLeft) : max(0, progress.daysLeft)
            return (value, totalUnits)
        }
        return (0, 1)
    }
}

// Helper to ALWAYS get completed count for Tally Marks (Crossed Out = Done)
func getCompletedCount(item: DisplayItem, entry: SimpleEntry) -> Int {
    switch item {
    case .today:
        return entry.timeData.hoursCompleted
    case .month:
        return entry.timeData.daysCompleted
    case .year:
        // For year, we use percentage (0-100) for tally marks if using TallyMarksView logic
        // But the previous code used Int(yearProgress * 100) / 100 which implies 100 marks?
        // Wait, TallyMarksView takes an Int count. If total is 12 for months, 365 for days?
        // Ah, in MainHomeView, year uses total: 12.
        // Let's check what getValueAndTotal returns for year... it returns (percent, 100).
        // So for consistency with TallyMarksView(total: 100), we return percent completed.
        return Int(entry.timeData.yearProgress * 100)
    case .week:
        return entry.timeData.daysCrossedInWeek
    case .quarter:
        return entry.timeData.quartersCompleted
    case .customEvent(let id):
        // Reuse logic but force completed
        if let event = entry.customEvents.first(where: { $0.id == id }) {
            let (completed, total) = getCustomEventValues(event: event, now: Date())
            return completed
        }
        return 0
    }
}

func getTotalCount(item: DisplayItem, entry: SimpleEntry) -> Int {
    switch item {
    case .today:
        return entry.timeMode == .nineToFive ? 8 : 24
    case .month:
        return entry.timeData.daysCompleted + entry.timeData.daysLeft
    case .year:
        return 100 // Year is shown as percentage in getValueAndTotal
    case .week:
        return 7
    case .quarter:
        return 4
    case .customEvent(let id):
        if let event = entry.customEvents.first(where: { $0.id == id }) {
            let (_, total) = getCustomEventValues(event: event, now: Date())
            return total
        }
        return 1
    }
}

func getCustomEventValues(event: CustomEvent, now: Date) -> (Int, Int) {
    let progress = event.calculateProgress()
    let totalDays = max(1, progress.totalDays)
    let totalUnits = progress.useWeeks ? max(1, Int(ceil(Double(totalDays) / 7.0))) : totalDays
    let completedUnits = progress.useWeeks
        ? min(totalUnits, Int(ceil(Double(max(0, progress.daysCompleted)) / 7.0)))
        : min(totalUnits, max(0, progress.daysCompleted))
    return (completedUnits, totalUnits)
}

// Tally Marks Views
struct TallyMarksView: View {
    let total: Int
    let completed: Int
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let itemWidth: CGFloat = 16
            let spacing: CGFloat = 4
            let itemsPerRow = Int(availableWidth / (itemWidth + spacing))
            let rows = (total + itemsPerRow - 1) / max(1, itemsPerRow)
            
            // Limit rows to avoid overflow in widget
            let maxRows = 2
            let displayRows = min(rows, maxRows)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<displayRows, id: \.self) { row in
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
}

struct TallyMarkView: View {
    let isCompleted: Bool
    
    var body: some View {
        ZStack {
            // Vertical line
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 2, height: 20)
            
            // Diagonal cross line
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

// Font Registration for Widget - Made safe and non-fatal
func registerFontsForWidget() {
    print("🔤 [Widget] Starting font registration...")
    
    // First, list all available fonts to see what's actually available
    print("🔤 [Widget] All available font families:")
    for family in UIFont.familyNames.sorted() {
        if family.lowercased().contains("sabdevi") || family.lowercased().contains("sabdev") {
            print("  📦 Family: \(family)")
            for fontName in UIFont.fontNames(forFamilyName: family) {
                print("    - \(fontName)")
                // Store the actual font names for lookup
                if fontName.lowercased().contains("bold") {
                    WidgetFontHelper.registeredFonts["Sabdevi-Bold"] = fontName
                } else if fontName.lowercased().contains("light") {
                    WidgetFontHelper.registeredFonts["Sabdevi-Light"] = fontName
                } else {
                    WidgetFontHelper.registeredFonts["Sabdevi-Regular"] = fontName
                }
            }
        }
    }
    
    // If fonts are declared in Info.plist, iOS should load them automatically
    // But we can also try manual registration as backup
    let fontFiles = [
        ("Sabdevi-Regular", "Regular"),
        ("Sabdevi-Bold", "Bold"),
        ("Sabdevi-Light", "Light")
    ]
    
    let widgetBundle = Bundle.main
    
    for (fontName, style) in fontFiles {
        // Skip if already found from family names
        if WidgetFontHelper.registeredFonts[fontName] != nil {
            print("✅ [Widget] Font \(fontName) already available from system")
            continue
        }
        
        var fontURL: URL?
        
        // Try multiple paths (matching Info.plist format and common locations)
        let paths = [
            "Assets/Fonts/\(fontName)",  // Info.plist format
            fontName,
            "Assets/Fonts/\(fontName).ttf",
            "\(fontName).ttf"
        ]
        
        for path in paths {
            if let url = widgetBundle.url(forResource: path, withExtension: path.hasSuffix(".ttf") ? nil : "ttf") {
                fontURL = url
                print("🔤 [Widget] Found \(fontName) at: \(path)")
                break
            }
            if let url = widgetBundle.url(forResource: path, withExtension: path.hasSuffix(".ttf") ? nil : "ttf", subdirectory: nil) {
                fontURL = url
                print("🔤 [Widget] Found \(fontName) at subdirectory: \(path)")
                break
            }
        }
        
        // Check all bundles
        if fontURL == nil {
            for bundle in Bundle.allBundles {
                for path in paths {
                    if let url = bundle.url(forResource: path, withExtension: path.hasSuffix(".ttf") ? nil : "ttf") {
                        fontURL = url
                        print("🔤 [Widget] Found \(fontName) in bundle: \(bundle.bundleIdentifier ?? "unknown")")
                        break
                    }
                }
                if fontURL != nil { break }
            }
        }
        
        if let url = fontURL {
            guard let fontData = NSData(contentsOf: url),
                  let dataProvider = CGDataProvider(data: fontData),
                  let font = CGFont(dataProvider) else {
                print("⚠️ [Widget] Failed to load font data for \(fontName)")
                continue
            }
            
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterGraphicsFont(font, &error) {
                if let postScriptName = font.postScriptName as String? {
                    print("✅ [Widget] Registered font: \(fontName) -> \(postScriptName)")
                    WidgetFontHelper.registeredFonts[fontName] = postScriptName
                } else {
                    WidgetFontHelper.registeredFonts[fontName] = fontName
                }
            } else {
                // Font might already be registered (from Info.plist)
                if let postScriptName = font.postScriptName as String? {
                    WidgetFontHelper.registeredFonts[fontName] = postScriptName
                    print("✅ [Widget] Font \(fontName) already registered: \(postScriptName)")
                }
            }
        } else {
            print("⚠️ [Widget] Font file not found: \(fontName).ttf")
        }
    }
    
    print("🔤 [Widget] Final registered fonts: \(WidgetFontHelper.registeredFonts)")
}

struct TimeLeftTrackerWidget: Widget {
    let kind: String = "TimeLeftTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimeLeftTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Days counter")
        .description("Track your time progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
    
    init() {
        print("✅ [Widget] TimeLeftTrackerWidget initialized")
        // Register fonts synchronously first to ensure they're available when views render
        // Widgets need fonts registered before rendering
        registerFontsForWidget()
    }
}

// MARK: - Lock Screen Widgets

struct LockScreenCircularView: View {
    let entry: SimpleEntry
    
    var body: some View {
        let (value, _) = getValueAndTotal(item: .today, entry: entry)
        // Visual progress ALWAYS reflects "Done" (so it fills up as day passes)
        let completed = getCompletedCount(item: .today, entry: entry)
        let total = getTotalCount(item: .today, entry: entry)
        let progress = Double(completed) / Double(total)
        
        Gauge(value: progress) {
            Text("Today")
        } currentValueLabel: {
            Text("\(value)")
                .font(.sabdeviBold(size: 10)) // Try applying font
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(.clear, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct LockScreenRectangularView: View {
    let entry: SimpleEntry
    
    var body: some View {
        let (value, _) = getValueAndTotal(item: .today, entry: entry)
        // Visual progress ALWAYS reflects "Done"
        let completed = getCompletedCount(item: .today, entry: entry)
        let total = getTotalCount(item: .today, entry: entry)
        let progress = Double(completed) / Double(total)
        
        // Check if office hours are done (9-5 mode)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let isOfficeHoursDone = entry.timeMode == .nineToFive && hour >= 17
        
        let unitText = entry.perspective == .halfFull ? "hrs done" : "hrs left"
        
        VStack(alignment: .leading, spacing: 5) {
            if isOfficeHoursDone {
                Text("Chill now")
                    .font(.sabdeviRegular(size: 14))
                    .widgetAccentable()
            } else {
                Text("\(value) \(unitText) today")
                    .font(.sabdeviRegular(size: 14))
                    .widgetAccentable()
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(height: 12) // Increased height to 12pt
                .tint(.primary) // Use system tint for contrast
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .containerBackground(.clear, for: .widget)
        .widgetURL(widgetHomeURL())
    }
}

struct LockScreenInlineView: View {
    let entry: SimpleEntry
    
    var body: some View {
        let (value, _) = getValueAndTotal(item: .today, entry: entry)
        let unitText = entry.perspective == .halfFull ? "done" : "left"
        
        Text("Today: \(value)h \(unitText)")
            .font(.sabdeviBold(size: 12)) // Inline might override this, but we try
            .containerBackground(.clear, for: .widget)
            .widgetURL(widgetHomeURL())
    }
}

// MARK: - Leave Insights Widget

struct LeaveInsightsEntry: TimelineEntry {
    let date: Date
    let nextText: String
    let bestText: String
    let rangeText: String
    let daysNeeded: Int
    let strip: [LeaveDay]
    let isPro: Bool
}

struct LeaveDay: Identifiable {
    let id = UUID()
    let label: String
    let day: String
    let type: DayType
}

enum DayType { case holiday, weekend, weekday }

struct Holiday: Codable {
    let name: String
    let dateString: String
    var date: Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: dateString)
    }
    init(name: String, dateString: String) {
        self.name = name
        self.dateString = dateString
    }
}

struct LeaveInsightsProvider: TimelineProvider {
    func placeholder(in context: Context) -> LeaveInsightsEntry {
        LeaveInsightsEntry(
            date: Date(),
            nextText: "Diwali • Nov 12",
            bestText: "Take Friday off for a 4-day break",
            rangeText: "10 Nov - 14 Nov",
            daysNeeded: 1,
            strip: sampleStrip(),
            isPro: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LeaveInsightsEntry) -> ()) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LeaveInsightsEntry>) -> ()) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date().addingTimeInterval(7200)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> LeaveInsightsEntry {
        let cal = Calendar.current
        let defaults = UserDefaults(suiteName: "group.com.prabhakaran.timeprogresstracker")
        let isPro = defaults?.bool(forKey: "isPro") ?? true

        let holidays: [Holiday] = {
            if let data = defaults?.data(forKey: "holidays"),
               let decoded = try? JSONDecoder().decode([Holiday].self, from: data) {
                return decoded
            }
            return defaultHolidays()
        }()

        // Find next holiday >= today
        let today = cal.startOfDay(for: Date())
        guard let nextHoliday = holidays.compactMap({ ($0.name, $0.date) }).first(where: { $0.1 != nil && $0.1! >= today }) else {
            return LeaveInsightsEntry(
                date: Date(),
                nextText: "Plan a long weekend",
                bestText: "Add a day off near a holiday",
                rangeText: "",
                daysNeeded: 0,
                strip: sampleStrip(),
                isPro: isPro
            )
        }
        let holidayName = nextHoliday.0
        let holidayDate = nextHoliday.1 ?? today

        // Build 5-day window around holiday: -2 to +2 days
        var strip: [LeaveDay] = []
        var leaveNeeded = 0
        let dfWeek = DateFormatter(); dfWeek.dateFormat = "EE"
        let dfDay = DateFormatter(); dfDay.dateFormat = "d"
        for offset in -2...2 {
            guard let date = cal.date(byAdding: .day, value: offset, to: holidayDate) else { continue }
            let label = dfWeek.string(from: date)
            let dayText = dfDay.string(from: date)
            let type: DayType
            if cal.isDate(date, inSameDayAs: holidayDate) {
                type = .holiday
            } else if cal.isDateInWeekend(date) {
                type = .weekend
            } else {
                type = .weekday; leaveNeeded += 1
            }
            strip.append(LeaveDay(label: label, day: dayText, type: type))
        }

        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        let rangeText = "\(fmt.string(from: strip.first?.labelDate(cal: cal, ref: holidayDate) ?? holidayDate)) - \(fmt.string(from: strip.last?.labelDate(cal: cal, ref: holidayDate) ?? holidayDate))"

        // Next / best text
        let nextText = "\(holidayName) • \(fmt.string(from: holidayDate))"
        let bestText: String = {
            let weekday = cal.component(.weekday, from: holidayDate)
            if weekday == 6 { // Fri
                return "Take Monday off for a 4-day break"
            } else if weekday == 2 { // Mon
                return "Take Friday off for a 4-day break"
            } else if weekday == 3 { // Tue
                return "Take Monday off and coast into the holiday"
            } else if weekday == 5 { // Thu
                return "Take Friday off to extend the weekend"
            } else {
                return "Add 1 day off around the holiday"
            }
        }()

        return LeaveInsightsEntry(
            date: Date(),
            nextText: nextText,
            bestText: bestText,
            rangeText: rangeText,
            daysNeeded: leaveNeeded,
            strip: strip,
            isPro: isPro
        )
    }

    private func defaultHolidays() -> [Holiday] {
        return [
            Holiday(name: "Republic Day", dateString: "2026-01-26"),
            Holiday(name: "Ambedkar Jayanti", dateString: "2026-04-14"),
            Holiday(name: "May Day", dateString: "2026-05-01"),
            Holiday(name: "Independence Day", dateString: "2026-08-15"),
            Holiday(name: "Gandhi Jayanti", dateString: "2026-10-02"),
            Holiday(name: "Dussehra", dateString: "2026-10-24"),
            Holiday(name: "Diwali", dateString: "2026-11-12"),
            Holiday(name: "Christmas", dateString: "2026-12-25")
        ]
    }

    private func sampleStrip() -> [LeaveDay] {
        [
            LeaveDay(label: "Fri", day: "10", type: .weekday),
            LeaveDay(label: "Sat", day: "11", type: .weekend),
            LeaveDay(label: "Sun", day: "12", type: .weekend),
            LeaveDay(label: "Mon", day: "13", type: .holiday),
            LeaveDay(label: "Tue", day: "14", type: .weekday)
        ]
    }
}

private extension LeaveDay {
    func labelDate(cal: Calendar, ref: Date) -> Date {
        // Reconstruct date using the ref weekday order; used only for range text
        return ref
    }
}

struct LeaveInsightsWidgetView: View {
    let entry: LeaveInsightsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.nextText).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                Text(entry.bestText).font(.system(size: 11)).lineLimit(1)
            }
            .containerBackground(.clear, for: .widget)
        case .accessoryInline:
            Text(entry.bestText).font(.system(size: 12)).containerBackground(.clear, for: .widget)
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next Leave")
                .font(.sabdeviRegular(size: 11))
                .foregroundColor(.secondary)
            Text(entry.nextText)
                .font(.sabdeviBold(size: 15))
                .lineLimit(1)
            if let days = daysUntilHoliday() {
                Text("in \(days)d")
                    .font(.sabdeviRegular(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Leave Optimizer").font(.sabdeviRegular(size: 12))
                Spacer()
                Text(entry.rangeText).font(.system(size: 11)).foregroundColor(.secondary)
            }

            if entry.isPro {
                HStack {
                    Text(entry.nextText).font(.system(size: 16, weight: .bold)).lineLimit(1)
                    Spacer()
                    Text(entry.daysNeeded == 0 ? "No leave" : "\(entry.daysNeeded)d leave")
                        .font(.system(size: 12)).foregroundColor(entry.daysNeeded == 0 ? .green : .orange)
                }

                dayStrip

                Text(entry.bestText)
                    .font(.system(size: 12))
                    .lineLimit(2)
            } else {
                Text("Unlock Pro to see leave plans")
                    .font(.system(size: 14))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var dayStrip: some View {
        HStack(spacing: 10) {
            ForEach(entry.strip) { day in
                VStack(spacing: 4) {
                    Text(day.label).font(.system(size: 11, weight: .medium)).foregroundColor(color(day.type).text)
                    Text(day.day)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color(day.type).text)
                        .frame(width: 30, height: 30)
                        .background(color(day.type).bg)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color(day.type).border, lineWidth: 1))
                        .cornerRadius(6)
                }
            }
        }
    }

    private func color(_ type: DayType) -> (bg: Color, border: Color, text: Color) {
        switch type {
        case .holiday:
            return (Color.green.opacity(0.15), Color.green.opacity(0.7), .green)
        case .weekend:
            return (Color.yellow.opacity(0.2), Color.orange.opacity(0.7), .orange)
        case .weekday:
            return (Color.gray.opacity(0.15), Color.gray.opacity(0.4), .primary)
        }
    }

    private func daysUntilHoliday() -> Int? {
        // Parse nextText which is "Holiday • MMM d"
        let parts = entry.nextText.split(separator: "•").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }
        let df = DateFormatter(); df.dateFormat = "MMM d"
        guard let date = df.date(from: parts[1]) else { return nil }
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        // Move the parsed month/day to the current year
        var comps = cal.dateComponents([.month, .day], from: date)
        comps.year = cal.component(.year, from: now)
        let target = cal.date(from: comps) ?? date
        let days = cal.dateComponents([.day], from: now, to: target).day
        return days
    }
}

struct LeaveInsightsWidget: Widget {
    let kind: String = "LeaveInsightsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LeaveInsightsProvider()) { entry in
            LeaveInsightsWidgetView(entry: entry)
        }
        .configurationDisplayName("Leave Optimizer")
        .description("Next long weekend + best leave suggestion.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .systemSmall) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour),
        perspective: .halfFull,
        timeMode: .twentyFourHour,
        selectedItems: [.today, .month, .year],
        customEvents: [],
        widgetStyle: .classic
    )
}

#Preview(as: .systemMedium) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour),
        perspective: .halfFull,
        timeMode: .twentyFourHour,
        selectedItems: [.today, .month, .year],
        customEvents: [],
        widgetStyle: .classic
    )
}

#Preview(as: .systemLarge) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour),
        perspective: .halfFull,
        timeMode: .twentyFourHour,
        selectedItems: [.today, .month, .year],
        customEvents: [],
        widgetStyle: .classic
    )
}
