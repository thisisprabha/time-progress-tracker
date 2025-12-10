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
        SimpleEntry(date: Date(), timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour), perspective: .halfFull, timeMode: .twentyFourHour, selectedItems: [.today, .month, .year], customEvents: [])
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
            customEvents = events
        }
        
        let timeData = TimeCalculator.calculateTimeData(timeMode: timeMode)
        
        return SimpleEntry(
            date: Date(),
            timeData: timeData,
            perspective: perspective,
            timeMode: timeMode,
            selectedItems: selectedItems,
            customEvents: customEvents
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
}

struct TimeLeftTrackerWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let firstItem = entry.selectedItems.first {
                ProgressRow(item: firstItem, entry: entry)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
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
                    TextOnlyRow(item: item, entry: entry)
                    
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
              TallyProgressRow(item: item, entry: entry)
                .padding(.vertical, 20.0)
               
              
            }
            
          
        }
        .padding(.vertical, 10.0)
      
        .containerBackground(.fill.tertiary, for: .widget)
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
            let calendar = Calendar.current
            let now = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            guard let eventDate = dateFormatter.date(from: event.date) else {
                return (0, 1)
            }
            
            // Parse start date (default to today if missing)
            let startDate = dateFormatter.date(from: event.startDate ?? "") ?? now
            
            let today = calendar.startOfDay(for: now)
            let eventDay = calendar.startOfDay(for: eventDate)
            let startDay = calendar.startOfDay(for: startDate)
            
            let totalDuration = eventDay.timeIntervalSince(startDay)
            let totalDays = max(1, Int(totalDuration / (24 * 60 * 60)))
            
            let completedDuration = today.timeIntervalSince(startDay)
            let daysCompleted = max(0, Int(completedDuration / (24 * 60 * 60)))
            let daysLeft = max(0, totalDays - daysCompleted)
            
            if entry.perspective == .halfFull {
                return (daysCompleted, totalDays)
            } else {
                return (daysLeft, totalDays)
            }
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
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    guard let eventDate = dateFormatter.date(from: event.date) else {
        return (0, 1)
    }
    
    // Parse start date (default to today if missing)
    let startDate = dateFormatter.date(from: event.startDate ?? "") ?? now
    
    let today = calendar.startOfDay(for: now)
    let eventDay = calendar.startOfDay(for: eventDate)
    let startDay = calendar.startOfDay(for: startDate)
    
    let totalDuration = eventDay.timeIntervalSince(startDay)
    let totalDays = max(1, Int(totalDuration / (24 * 60 * 60)))
    
    let completedDuration = today.timeIntervalSince(startDay)
    let daysCompleted = max(0, Int(completedDuration / (24 * 60 * 60)))
    
    return (daysCompleted, totalDays)
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
        let (value, total) = getValueAndTotal(item: .today, entry: entry)
        let progress = Double(value) / Double(total)
        
        Gauge(value: progress) {
            Text("Today")
        } currentValueLabel: {
            Text("\(value)")
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct LockScreenRectangularView: View {
    let entry: SimpleEntry
    
    var body: some View {
        let (value, total) = getValueAndTotal(item: .today, entry: entry)
        let progress = Double(value) / Double(total)
        let unitText = entry.perspective == .halfFull ? "hrs done" : "hrs left"
        
        VStack(alignment: .leading) {
            Text("Today")
                .font(.headline)
                .widgetAccentable()
            
            Text("\(value) \(unitText)")
                .font(.body)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
        }
    }
}

struct LockScreenInlineView: View {
    let entry: SimpleEntry
    
    var body: some View {
        let (value, total) = getValueAndTotal(item: .today, entry: entry)
        let unitText = entry.perspective == .halfFull ? "done" : "left"
        
        Text("Today: \(value)h \(unitText)")
    }
}

#Preview(as: .systemSmall) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(date: .now, timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour), perspective: .halfFull, timeMode: .twentyFourHour, selectedItems: [.today, .month, .year], customEvents: [])
}

#Preview(as: .systemMedium) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(date: .now, timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour), perspective: .halfFull, timeMode: .twentyFourHour, selectedItems: [.today, .month, .year], customEvents: [])
}

#Preview(as: .systemLarge) {
    TimeLeftTrackerWidget()
} timeline: {
    SimpleEntry(date: .now, timeData: TimeCalculator.calculateTimeData(timeMode: .twentyFourHour), perspective: .halfFull, timeMode: .twentyFourHour, selectedItems: [.today, .month, .year], customEvents: [])
}
