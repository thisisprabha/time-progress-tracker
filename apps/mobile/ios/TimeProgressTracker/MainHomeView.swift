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
                // Header with sun/cloud SVG placeholder
                HeaderView()
                    .padding(.top, 50)
                
                Spacer()
                
                // Main content - show exactly 3 selected items
                ScrollView {
                    VStack(spacing: 24) {
                        // Today
                        if appState.selectedDisplayItems.contains(.today) {
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
                        }
                        
                        // Week
                        if appState.selectedDisplayItems.contains(.week) {
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
                        }
                        
                        // Month
                        if appState.selectedDisplayItems.contains(.month) {
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
                        }
                        
                        // Quarter
                        if appState.selectedDisplayItems.contains(.quarter) {
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
                        }
                        
                        // Year
                        if appState.selectedDisplayItems.contains(.year) {
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
                        }
                        
                        // Custom Events
                        if appState.selectedDisplayItems.contains(.custom) {
                            ForEach(appState.customEvents.prefix(3), id: \.id) { event in
                                CustomEventTallyView(event: event)
                                    .environmentObject(appState)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                }
                
                Spacer()
            }
            
            // Settings button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        appState.showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.sabdeviRegular(size: 24 * 0.7))
                            .foregroundColor(.black)
                            .padding(8)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
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

struct HeaderView: View {
    var body: some View {
        VStack {
            // Load SVG from bundle
            if let svgURL = Bundle.main.url(forResource: "header-sunskybird", withExtension: "svg"),
               let svgData = try? Data(contentsOf: svgURL),
               let svgString = String(data: svgData, encoding: .utf8) {
                SVGView(svgString: svgString)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(650/250, contentMode: .fit)
                    .frame(height: 200)
            } else {
                // Fallback if SVG not found
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
    }
}

// Simple SVG renderer using WebKit
struct SVGView: UIViewRepresentable {
    let svgString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; margin: 0; padding: 0; background: transparent; overflow: visible; }
                svg { width: 100%; height: auto; max-height: 100%; display: block; }
            </style>
        </head>
        <body>
            \(svgString)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
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
                    .font(.sabdeviRegular(size: 17.5 * 1.1))
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Text(value)
                        .font(.sabdeviBold(size: 17.5 * 1.1))
                        .foregroundColor(.black)
                    Text("  \(TimeCalculator.addDoubleSpaces(unit))")
                        .font(.sabdeviBold(size: 17.5 * 1.1))
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

