//
//  SettingsView.swift
//  TimeProgressTracker
//
//  Modern Minimal iOS Style Settings
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                List {
                    // Your Mindset Section
                    Section {
                        ForEach(Perspective.allCases, id: \.self) { perspective in
                            SettingsRow(
                                title: perspective.displayName,
                                isSelected: appState.perspective == perspective
                            ) {
                                appState.perspective = perspective
                                appState.saveSettings()
                            }
                        }
                    } header: {
                        Text("Your Mindset")
                            .font(.sabdeviBold(size: 13 * 1.2))
                            .foregroundColor(.primary)
                    }
                    
                    // Daily Tracking Section
                    Section {
                        ForEach(TimeMode.allCases, id: \.self) { mode in
                            SettingsRow(
                                title: mode.displayName,
                                isSelected: appState.timeMode == mode
                            ) {
                                appState.timeMode = mode
                                appState.saveSettings()
                            }
                        }
                    } header: {
                        Text("Daily Tracking")
                            .font(.sabdeviBold(size: 13 * 1.2))
                            .foregroundColor(.primary)
                    }
                    
                    // Customize Display Section
                    Section {
                        Text("Choose 3 items to display")
                            .font(.sabdeviRegular(size: 15 * 1.2))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                        
                        let displayItems: [DisplayItem] = [.today, .week, .month, .quarter, .year, .custom]
                        // Create ordered array of selected items
                        let orderedSelectedItems = displayItems.filter { appState.selectedDisplayItems.contains($0) }
                        
                        ForEach(displayItems, id: \.self) { item in
                            let isSelected = appState.selectedDisplayItems.contains(item)
                            let index = isSelected ? orderedSelectedItems.firstIndex(of: item) : nil
                            
                            SettingsRow(
                                title: item.displayName,
                                isSelected: isSelected,
                                isDisabled: !isSelected && appState.selectedDisplayItems.count >= 3,
                                showNumber: isSelected,
                                number: index != nil ? index! + 1 : nil
                            ) {
                                if isSelected {
                                    if appState.selectedDisplayItems.count > 1 {
                                        appState.selectedDisplayItems.remove(item)
                                    }
                                } else {
                                    if appState.selectedDisplayItems.count < 3 {
                                        appState.selectedDisplayItems.insert(item)
                                    }
                                }
                                appState.saveSettings()
                            }
                        }
                        
                        // Custom Events section
                        if appState.selectedDisplayItems.contains(.custom) {
                            CustomEventsSection()
                                .environmentObject(appState)
                                .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("Customize Display")
                            .font(.sabdeviBold(size: 13 * 1.2))
                            .foregroundColor(.primary)
                    }
                    
                    // Apple Watch Complication Section
                    Section {
                        Text("Choose what to display on Apple Watch")
                            .font(.sabdeviRegular(size: 15 * 1.2))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                        
                        let watchItems: [DisplayItem] = [.today, .week, .month, .quarter, .year, .custom]
                        ForEach(watchItems, id: \.self) { item in
                            let isSelected = appState.watchComplicationItem == item
                            
                            SettingsRow(
                                title: item.displayName,
                                isSelected: isSelected
                            ) {
                                appState.watchComplicationItem = item
                                appState.saveSettings()
                            }
                        }
                    } header: {
                        Text("Apple Watch")
                            .font(.sabdeviBold(size: 13 * 1.2))
                            .foregroundColor(.primary)
                    }
                    
                    // Notification Section
                    Section {
                        Text("Weekly progress updates every Monday")
                            .font(.sabdeviRegular(size: 15 * 1.2))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                    } header: {
                        Text("Notification")
                            .font(.sabdeviBold(size: 13 * 1.2))
                            .foregroundColor(.primary)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.sabdeviRegular(size: 17 * 1.2))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let title: String
    let isSelected: Bool
    var isDisabled: Bool = false
    var showNumber: Bool = false
    var number: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if showNumber, let num = number {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 24, height: 24)
                        Text("\(num)")
                            .font(.sabdeviBold(size: 14 * 0.9))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 8)
                }
                
                Text(title)
                    .font(isSelected ? .sabdeviBold(size: 17 * 0.9) : .sabdeviRegular(size: 17 * 0.9))
                    .foregroundColor(isDisabled ? .secondary : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.sabdeviBold(size: 17 * 0.9))
                        .foregroundColor(.primary)
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(isDisabled)
        .listRowBackground(Color(.systemBackground))
    }
}

extension Perspective {
    var displayName: String {
        switch self {
        case .halfFull: return "Half Full"
        case .halfEmpty: return "Half Empty"
        }
    }
}

extension TimeMode {
    var displayName: String {
        switch self {
        case .twentyFourHour: return "24 Hours"
        case .nineToFive: return "9 to 5"
        }
    }
}

extension DisplayItem {
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .month: return "This Month"
        case .year: return "This Year"
        case .week: return "This Week"
        case .quarter: return "Q4" // Will be dynamic based on quarter number
        case .custom: return "Custom Events"
        }
    }
}
