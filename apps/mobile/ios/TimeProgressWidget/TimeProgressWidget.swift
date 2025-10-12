//
//  TimeProgressWidget.swift
//  TimeProgressWidget
//
//  Created by prabha karan on 12/10/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dayProgress: 0.5, monthProgress: 0.5, yearProgress: 0.5, perspective: "optimistic", timeMode: "24h")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), dayProgress: 0.6, monthProgress: 0.4, yearProgress: 0.8, perspective: "optimistic", timeMode: "24h")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline entry for the current time
        let currentDate = Date()
        
        // Calculate actual time progress
        let calendar = Calendar.current
        let now = Date()
        
        // Day progress (0-24 hours)
        let hour = calendar.component(.hour, from: now)
        let dayProgress = Double(hour) / 24.0
        
        // Month progress (current day / total days in month)
        let dayOfMonth = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let monthProgress = Double(dayOfMonth) / Double(daysInMonth)
        
        // Year progress (current day of year / total days in year)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
        let yearProgress = Double(dayOfYear) / Double(daysInYear)
        
        // Create entry with calculated progress
        let entry = SimpleEntry(
            date: currentDate,
            dayProgress: dayProgress,
            monthProgress: monthProgress,
            yearProgress: yearProgress,
            perspective: "optimistic",
            timeMode: "24h"
        )
        
        entries.append(entry)
        
        // Create timeline
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dayProgress: Double
    let monthProgress: Double
    let yearProgress: Double
    let perspective: String
    let timeMode: String
    
    init(date: Date, dayProgress: Double = 0.5, monthProgress: Double = 0.5, yearProgress: Double = 0.5, perspective: String = "optimistic", timeMode: String = "24h") {
        self.date = date
        self.dayProgress = dayProgress
        self.monthProgress = monthProgress
        self.yearProgress = yearProgress
        self.perspective = perspective
        self.timeMode = timeMode
    }
}

struct TimeProgressWidgetEntryView : View {
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
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 2) {
            Text(hoursText)
                .font(.custom("Marker Felt", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("For today")
                .font(.custom("Marker Felt", size: 12))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.clear)
    }
    
    private var hoursText: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        
        if entry.timeMode == "9-5" {
            // 9-5 office hours (8 hours total)
            let officeHour = max(0, min(8, hour - 9))
            let hoursLeft = 8 - officeHour
            
            if entry.perspective == "optimistic" {
                return "\(hoursLeft)h left"
            } else {
                return "\(officeHour)h done"
            }
        } else {
            // 24-hour format
            let hoursLeft = 24 - hour
            
            if entry.perspective == "optimistic" {
                return "\(hoursLeft)h left"
            } else {
                return "\(hour)h done"
            }
        }
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Today row
            VStack(spacing: 4) {
                HStack {
                    Text("Today")
                        .font(.custom("Marker Felt", size: 14))
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(todayHoursText)
                        .font(.custom("Marker Felt", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Tally marks for today
                TallyMarksView(completed: todayCompleted, remaining: todayRemaining)
            }
            
            // This Month row
            VStack(spacing: 4) {
                HStack {
                    Text("This Month")
                        .font(.custom("Marker Felt", size: 14))
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(monthDaysText)
                        .font(.custom("Marker Felt", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Tally marks for month
                TallyMarksView(completed: monthCompleted, remaining: monthRemaining)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .padding(.horizontal, 8)
    }
    
    private var todayHoursText: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        
        if entry.timeMode == "9-5" {
            let officeHour = max(0, min(8, hour - 9))
            let hoursLeft = 8 - officeHour
            return "\(hoursLeft)h left"
        } else {
            let hoursLeft = 24 - hour
            return "\(hoursLeft)h left"
        }
    }
    
    private var monthDaysText: String {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: entry.date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: entry.date)?.count ?? 30
        let daysLeft = daysInMonth - dayOfMonth
        return "\(daysLeft) days left"
    }
    
    private var todayCompleted: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        
        if entry.timeMode == "9-5" {
            return max(0, min(8, hour - 9))
        } else {
            return hour
        }
    }
    
    private var todayRemaining: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        
        if entry.timeMode == "9-5" {
            return 8 - max(0, min(8, hour - 9))
        } else {
            return 24 - hour
        }
    }
    
    private var monthCompleted: Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: entry.date)
    }
    
    private var monthRemaining: Int {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: entry.date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: entry.date)?.count ?? 30
        return daysInMonth - dayOfMonth
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Today row
            VStack(spacing: 4) {
                HStack {
                    Text("Today")
                        .font(.custom("Marker Felt", size: 16))
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(todayHoursText)
                        .font(.custom("Marker Felt", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Tally marks for today
                TallyMarksView(completed: todayCompleted, remaining: todayRemaining)
            }
            
            // This Month row
            VStack(spacing: 4) {
                HStack {
                    Text("This Month")
                        .font(.custom("Marker Felt", size: 16))
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(monthDaysText)
                        .font(.custom("Marker Felt", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Tally marks for month
                TallyMarksView(completed: monthCompleted, remaining: monthRemaining)
            }
            
            // This Year row
            VStack(spacing: 4) {
                HStack {
                    Text("This Year")
                        .font(.custom("Marker Felt", size: 16))
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(yearDaysText)
                        .font(.custom("Marker Felt", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Tally marks for year
                TallyMarksView(completed: yearCompleted, remaining: yearRemaining)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .padding(.horizontal, 12)
    }
    
    private var todayHoursText: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        
        if entry.timeMode == "9-5" {
            let officeHour = max(0, min(8, hour - 9))
            let hoursLeft = 8 - officeHour
            return "\(hoursLeft)h left"
        } else {
            let hoursLeft = 24 - hour
            return "\(hoursLeft)h left"
        }
    }
    
    private var monthDaysText: String {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: entry.date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: entry.date)?.count ?? 30
        let daysLeft = daysInMonth - dayOfMonth
        return "\(daysLeft) days left"
    }
    
    private var yearDaysText: String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: entry.date) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: entry.date)?.count ?? 365
        let daysLeft = daysInYear - dayOfYear
        return "\(daysLeft) days left"
    }
    
    private var todayCompleted: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        
        if entry.timeMode == "9-5" {
            return max(0, min(8, hour - 9))
        } else {
            return hour
        }
    }
    
    private var todayRemaining: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        
        if entry.timeMode == "9-5" {
            return 8 - max(0, min(8, hour - 9))
        } else {
            return 24 - hour
        }
    }
    
    private var monthCompleted: Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: entry.date)
    }
    
    private var monthRemaining: Int {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: entry.date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: entry.date)?.count ?? 30
        return daysInMonth - dayOfMonth
    }
    
    private var yearCompleted: Int {
        let calendar = Calendar.current
        return calendar.ordinality(of: .day, in: .year, for: entry.date) ?? 1
    }
    
    private var yearRemaining: Int {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: entry.date) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: entry.date)?.count ?? 365
        return daysInYear - dayOfYear
    }
}

struct TallyMarksView: View {
    let completed: Int
    let remaining: Int
    
    var body: some View {
        VStack(spacing: 2) {
            // Completed marks (X marks) - slightly duller
            HStack(spacing: 1) {
                ForEach(0..<min(completed, 20), id: \.self) { _ in
                    Text("✗")
                        .font(.custom("Marker Felt", size: 12))
                        .foregroundColor(.primary.opacity(0.6))
                }
                Spacer()
            }
            
            // Remaining marks (I marks) - full opacity
            HStack(spacing: 1) {
                ForEach(0..<min(remaining, 20), id: \.self) { _ in
                    Text("|")
                        .font(.custom("Marker Felt", size: 12))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TimeProgressWidget: Widget {
    let kind: String = "TimeProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimeProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Time Progress")
        .description("Track your daily, monthly, and yearly progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    TimeProgressWidget()
} timeline: {
    SimpleEntry(date: Date(), dayProgress: 0.6, monthProgress: 0.4, yearProgress: 0.8)
}

#Preview(as: .systemMedium) {
    TimeProgressWidget()
} timeline: {
    SimpleEntry(date: Date(), dayProgress: 0.6, monthProgress: 0.4, yearProgress: 0.8)
}

#Preview(as: .systemLarge) {
    TimeProgressWidget()
} timeline: {
    SimpleEntry(date: Date(), dayProgress: 0.6, monthProgress: 0.4, yearProgress: 0.8)
}