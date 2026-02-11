import SwiftUI

#if canImport(WidgetKit) && !canImport(UIKit)
// Widget target stub to avoid pulling app types into the extension
struct LeavePlannerCardView: View {
    var body: some View { EmptyView() }
}
#else

/// Lightweight port of the LeavePlanner card using our existing holiday list.
/// Builds a simple 5-day window around the next holiday and shows leave needed.
struct LeavePlannerCardView: View {
    @EnvironmentObject var appState: AppState
    @State private var opportunity: LeaveOpportunity?

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let opp = opportunity {
                header(opp)
                dayStrip(opp)
                leaveLine(opp)
                dateRangeLine(opp)
            } else {
                Text("No upcoming holidays found")
                    .font(.sabdeviRegular(size: 14))
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appState.isDarkMode ? Color.white.opacity(0.06) : Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(appState.isDarkMode ? 0.2 : 0.08), radius: 12, x: 0, y: 6)
        )
        .onAppear { rebuild() }
    }

    private func header(_ opp: LeaveOpportunity) -> some View {
        HStack {
            Text("\(opp.totalDays) day leave")
                .font(.sabdeviBold(size: 16))
                .foregroundColor(.primary)
            Spacer()
            if let daysAway = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: opp.startDate)).day {
                Text(daysAway <= 0 ? "Today" : "In \(daysAway)d")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 8)
    }

    private func dayStrip(_ opp: LeaveOpportunity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ForEach(opp.displayDates, id: \.self) { date in
                    let info = opp.dayInfo(for: date)
                    VStack(spacing: 4) {
                        Text(shortWeekday(date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(color(info).text)
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(color(info).text)
                            .frame(width: 30, height: 30)
                            .background(color(info).bg)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color(info).border, lineWidth: 1))
                            .cornerRadius(6)
                    }
                }
                Spacer()
            }
        }
        .padding(.bottom, 10)
    }

    private func leaveLine(_ opp: LeaveOpportunity) -> some View {
        let text = opp.weekdaysNeeded > 0 ? "Take \(opp.weekdaysNeeded) day off" : "No leave needed"
        let color = opp.weekdaysNeeded > 0 ? Color.red : Color.green
        return Text(text)
            .font(.sabdeviRegular(size: 14))
            .foregroundColor(color)
            .padding(.bottom, 8)
    }

    private func dateRangeLine(_ opp: LeaveOpportunity) -> some View {
        HStack {
            Text(opp.dateRangeText)
                .font(.sabdeviRegular(size: 14))
                .foregroundColor(.primary)
            Spacer()
            Text(opp.holidayName)
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private func shortWeekday(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EE"
        return df.string(from: date)
    }

    private func color(_ info: LeaveOpportunity.DayType) -> (bg: Color, border: Color, text: Color) {
        switch info {
        case .holiday:
            return (Color.green.opacity(0.15), Color.green.opacity(0.7), Color.green)
        case .weekend:
            return (Color.yellow.opacity(0.2), Color.orange.opacity(0.7), Color.orange)
        case .weekday:
            return (Color.gray.opacity(0.15), Color.gray.opacity(0.4), Color.primary)
        }
    }

    private func rebuild() {
        opportunity = LeaveOpportunityBuilder(calendar: calendar).build(from: appState.holidays)
    }
}

// MARK: - Lightweight models

struct LeaveOpportunity {
    enum DayType { case holiday, weekend, weekday }

    let startDate: Date
    let endDate: Date
    let totalDays: Int
    let weekdaysNeeded: Int
    let holidayName: String
    let dates: [(date: Date, type: DayType)]

    var displayDates: [Date] {
        guard let first = dates.first?.date, let last = dates.last?.date else { return [] }
        var result: [Date] = []
        var current = first
        while current <= last {
            result.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return result
    }

    func dayInfo(for date: Date) -> DayType {
        dates.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.type ?? .weekday
    }

    var dateRangeText: String {
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        return "\(df.string(from: startDate)) - \(df.string(from: endDate))"
    }
}

struct LeaveOpportunityBuilder {
    let calendar: Calendar

    func build(from holidays: [Holiday]) -> LeaveOpportunity? {
        let today = calendar.startOfDay(for: Date())
        guard let next = holidays.compactMap({ $0.date }).filter({ $0 >= today }).sorted().first else {
            return nil
        }

        let holidayName = holidays.first(where: { calendar.isDate($0.date ?? today, inSameDayAs: next) })?.name ?? "Holiday"

        // Build a 5-day window: Fri-Sat-Sun-Holiday-Mon when possible
        var dates: [(Date, LeaveOpportunity.DayType)] = []
        for offset in -2...2 {
            if let date = calendar.date(byAdding: .day, value: offset, to: next) {
                let weekday = calendar.component(.weekday, from: date)
                let type: LeaveOpportunity.DayType = calendar.isDate(date, inSameDayAs: next) ? .holiday : (weekday == 1 || weekday == 7 ? .weekend : .weekday)
                dates.append((date, type))
            }
        }

        let weekdaysNeeded = dates.filter { $0.1 == .weekday }.count
        let total = dates.count
        let start = dates.first?.0 ?? next
        let end = dates.last?.0 ?? next

        return LeaveOpportunity(
            startDate: start,
            endDate: end,
            totalDays: total,
            weekdaysNeeded: weekdaysNeeded,
            holidayName: holidayName,
            dates: dates
        )
    }
}

#endif // widget stub guard
